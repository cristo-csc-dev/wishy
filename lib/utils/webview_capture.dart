import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

// Widget principal de ejemplo
class WebViewCapture extends StatefulWidget {
  final String? initialUrl;

  const WebViewCapture({super.key, this.initialUrl});

  @override
  State<WebViewCapture> createState() => _WebViewCaptureState();
}

class _WebViewCaptureState extends State<WebViewCapture> {
  // Controlador para manejar el WebView
  InAppWebViewController? webViewController;

  // Variable para mostrar una barra de carga
  double progress = 0;

  // Key para medir el tamaño y posición del WebView
  final GlobalKey _webViewKey = GlobalKey();

  // Selección de región
  bool _selectionMode = false;
  Offset? _dragStartLogical;
  Rect? _selectionRectLogical;

  // Variables para manipulación de la selección (mover/escalar)
  Rect? _baseRectForResize;
  Offset? _baseFocalPoint;
  bool _isMoving = false;
  bool _isResizing = false;
  bool _initialSelectionSet = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Navega y Captura"),
        actions: [
          if (_selectionMode) ...[
            IconButton(
              icon: const Icon(Icons.check),
              tooltip: 'Capturar selección',
              onPressed: _selectionRectLogical == null
                  ? null
                  : () async {
                      final bytes = await _captureRegion(
                        _selectionRectLogical!,
                      );
                      if (bytes != null) _showPreviewDialog(bytes);
                      setState(() {
                        _selectionMode = false;
                        _selectionRectLogical = null;
                        _dragStartLogical = null;
                      });
                    },
            ),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Cancelar selección',
              onPressed: () {
                setState(() {
                  _selectionMode = false;
                  _selectionRectLogical = null;
                  _dragStartLogical = null;
                });
              },
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.crop_free),
              tooltip: 'Seleccionar región',
              onPressed: () {
                setState(() {
                  _selectionMode = true;
                });
              },
            ),
            // Botón extra para recargar si es necesario
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                webViewController?.reload();
              },
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          // 1. El WebView ocupa todo el fondo (envuelto para medir su tamaño)
          Container(
            key: _webViewKey,
            child: InAppWebView(
              initialUrlRequest: URLRequest(
                url: WebUri(
                  widget.initialUrl ??
                      "https://es.wikipedia.org/wiki/Flutter_(software)",
                ),
              ),
              // Configuración inicial para permitir zoom y scroll fluido
              initialSettings: InAppWebViewSettings(
                isInspectable: kDebugMode,
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
                iframeAllow: "camera; microphone",
                iframeAllowFullscreen: true,
                // Habilitar soporte de zoom nativo
                supportZoom: true,
                builtInZoomControls: true,
                displayZoomControls:
                    false, // Ocultar los botones feos de zoom +/-
              ),
              onWebViewCreated: (controller) {
                // Guardamos el controlador cuando se crea la vista
                webViewController = controller;
              },
              onProgressChanged: (controller, count) {
                setState(() {
                  progress = count / 100;
                });
              },
              onLoadStop: (controller, url) {
                if (!_initialSelectionSet && mounted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final renderBox = _webViewKey.currentContext
                        ?.findRenderObject() as RenderBox?;
                    if (renderBox != null && renderBox.hasSize) {
                      final size = renderBox.size;
                      final width = size.width * 0.5;
                      final height = size.height * 0.2;
                      final rect = Rect.fromCenter(
                        center: size.center(Offset.zero),
                        width: width,
                        height: height,
                      );
                      setState(() {
                        _selectionMode = true;
                        _selectionRectLogical = rect;
                        _initialSelectionSet = true;
                      });
                    }
                  });
                }
              },
            ),
          ),

          // 2. Barra de progreso simple mientras carga
          progress < 1.0
              ? LinearProgressIndicator(value: progress)
              : Container(),

          // Overlay para seleccionar región (captura de área)
          if (_selectionMode)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onScaleStart: (details) {
                  final box =
                      _webViewKey.currentContext?.findRenderObject() as RenderBox?;
                  if (box == null) return;
                  final local = box.globalToLocal(details.focalPoint);

                  if (details.pointerCount > 1) {
                    // Pinch: Modo Escalar (Cerrar/Abrir perspectiva)
                    _isResizing = true;
                    _isMoving = false;
                    // Si no hay selección, crear una por defecto centrada
                    _selectionRectLogical ??=
                        Rect.fromCenter(center: local, width: 200, height: 200);
                    _baseRectForResize = _selectionRectLogical;
                  } else {
                    // 1 Dedo
                    if (_selectionRectLogical != null &&
                        _selectionRectLogical!.contains(local)) {
                      // Tocar dentro: Modo Mover
                      _isMoving = true;
                      _isResizing = false;
                      _baseFocalPoint = local;
                      _baseRectForResize = _selectionRectLogical;
                    } else {
                      // Tocar fuera: Modo Dibujar Nuevo
                      _isMoving = false;
                      _isResizing = false;
                      _dragStartLogical = local;
                      _selectionRectLogical = Rect.fromPoints(local, local);
                    }
                  }
                },
                onScaleUpdate: (details) {
                  final box =
                      _webViewKey.currentContext?.findRenderObject() as RenderBox?;
                  if (box == null) return;
                  final local = box.globalToLocal(details.focalPoint);

                  if (details.pointerCount > 1) {
                    // Detectar inicio de pinch tardío (si se añade el 2º dedo después)
                    if (!_isResizing) {
                      _isResizing = true;
                      _isMoving = false;
                      _baseRectForResize = _selectionRectLogical ??
                          Rect.fromCenter(center: local, width: 200, height: 200);
                    }
                    if (_baseRectForResize != null) {
                      setState(() {
                        final newWidth =
                            _baseRectForResize!.width * details.horizontalScale;
                        final newHeight =
                            _baseRectForResize!.height * details.verticalScale;
                        _selectionRectLogical = Rect.fromCenter(
                          center: _baseRectForResize!.center,
                          width: newWidth,
                          height: newHeight,
                        );
                      });
                    }
                  } else {
                    // 1 Dedo
                    if (_isResizing) return; // Ignorar si estábamos escalando

                    if (_isMoving &&
                        _baseRectForResize != null &&
                        _baseFocalPoint != null) {
                      // Mover
                      final delta = local - _baseFocalPoint!;
                      setState(() {
                        _selectionRectLogical =
                            _baseRectForResize!.shift(delta);
                      });
                    } else if (_dragStartLogical != null) {
                      // Dibujar
                      setState(() {
                        _selectionRectLogical =
                            Rect.fromPoints(_dragStartLogical!, local);
                      });
                    }
                  }
                },
                onScaleEnd: (details) {
                  _isMoving = false;
                  _isResizing = false;
                  _baseRectForResize = null;
                  _baseFocalPoint = null;
                  _dragStartLogical = null;
                },
                child: _selectionRectLogical != null
                    ? CustomPaint(
                        painter: _SelectionOverlayPainter(
                          rect: _selectionRectLogical!,
                          overlayColor: Colors.black.withOpacity(0.5),
                          borderColor: Theme.of(context).colorScheme.primary,
                        ),
                        size: Size.infinite,
                      )
                    : const SizedBox.shrink(),
              ),
            ),
        ],
      ),
      // 3. El botón "Obturador"
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _takeScreenshotOfVisibleArea,
        label: const Text("Capturar Vista Actual"),
        icon: const Icon(Icons.camera_alt),
      ),
    );
  }

  // Captura una región lógica (coordenadas dentro del WebView) y devuelve PNG recortado
  Future<Uint8List?> _captureRegion(Rect logicalRect) async {
    if (webViewController == null) return null;

    // 1) Tomamos captura completa
    final Uint8List? bytes = await webViewController!.takeScreenshot(
      screenshotConfiguration: ScreenshotConfiguration(
        compressFormat: CompressFormat.PNG,
        quality: 90,
      ),
    );
    if (bytes == null) return null;

    // 2) Decodificamos la imagen y obtenemos dimensiones
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    // 3) Medimos el WebView en pantalla para mapear coordenadas lógicas a píxeles
    final box = _webViewKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final widgetSize = box.size;

    final scaleX = image.width / widgetSize.width;
    final scaleY = image.height / widgetSize.height;

    final double px = (logicalRect.left * scaleX)
        .clamp(0, image.width.toDouble())
        .toDouble();
    final double py = (logicalRect.top * scaleY)
        .clamp(0, image.height.toDouble())
        .toDouble();
    final double pwidth = (logicalRect.width * scaleX)
        .clamp(0, image.width - px)
        .toDouble();
    final double pheight = (logicalRect.height * scaleY)
        .clamp(0, image.height - py)
        .toDouble();

    final pixelRect = Rect.fromLTWH(px, py, pwidth, pheight);

    // 4) Recortamos usando un PictureRecorder
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint();

    final dst = Rect.fromLTWH(0, 0, pixelRect.width, pixelRect.height);
    canvas.drawImageRect(image, pixelRect, dst, paint);

    final croppedImage = await recorder.endRecording().toImage(
      pixelRect.width.toInt(),
      pixelRect.height.toInt(),
    );

    final byteData = await croppedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData?.buffer.asUint8List();
  }

  // La función mágica
  Future<void> _takeScreenshotOfVisibleArea() async {
    if (webViewController == null) return;

    // Muestra un indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // TOMA LA FOTO: Esto captura el viewport visible actual
      final Uint8List? screenshotBytes = await webViewController!
          .takeScreenshot(
            screenshotConfiguration: ScreenshotConfiguration(
              compressFormat: CompressFormat.PNG,
              quality: 90,
            ),
          );

      // Cerrar el indicador de carga
      Navigator.of(context).pop();

      if (screenshotBytes != null) {
        // Mostramos el resultado
        _showPreviewDialog(screenshotBytes);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al tomar la captura')),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Diálogo simple para mostrar la imagen capturada
  void _showPreviewDialog(Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Captura realizada"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Esta es la imagen exacta de lo que estabas viendo:",
                ),
                const SizedBox(height: 10),
                // Mostrar la imagen desde la memoria
                Image.memory(imageBytes),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cerrar"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            // Aquí podrías añadir otro botón para "Guardar" o "Compartir" la imagen
          ],
        );
      },
    );
  }
}

class _SelectionOverlayPainter extends CustomPainter {
  final Rect rect;
  final Color overlayColor;
  final Color borderColor;

  _SelectionOverlayPainter({
    required this.rect,
    required this.overlayColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(rect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, Paint()..color = overlayColor);

    canvas.drawRect(
      rect,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0,
    );
  }

  @override
  bool shouldRepaint(covariant _SelectionOverlayPainter oldDelegate) {
    return oldDelegate.rect != rect ||
        oldDelegate.overlayColor != overlayColor ||
        oldDelegate.borderColor != borderColor;
  }
}
