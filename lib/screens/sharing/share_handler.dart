// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'add_wish_to_lists_screen.dart'; 
// import '../main.dart'; 

// // Esta pantalla ahora SOLO maneja el INTENT INICIAL (el que lanza la app).
// // La escucha de INTENTS RECURRENTES se mueve a main.dart.
// class ShareHandlerScreen extends StatefulWidget {
//   const ShareHandlerScreen({super.key});

//   @override
//   State<ShareHandlerScreen> createState() => _ShareHandlerScreenState();
// }

// class _ShareHandlerScreenState extends State<ShareHandlerScreen> {
//   // 1. Definición del Method Channel
//   static const MethodChannel _platform = MethodChannel('app.wishy/share');
  
//   // Estado para manejar si el intent ya se ha procesado (útil para evitar doble navegación)
//   bool _isInitialIntentProcessed = false; 

//   @override
//   void initState() {
//     super.initState();
//     // Solo necesitamos obtener el intent inicial al cargar esta pantalla.
//     _getSharedDataFromNative();
//   }

//   // Lógica para invocar el método nativo y obtener el texto compartido (Intent Inicial)
//   Future<void> _getSharedDataFromNative() async {
//     if (_isInitialIntentProcessed) return;

//     String? sharedText;
    
//     try {
//       // Invocación del Método Nativo: 'getSharedText'
//       sharedText = await _platform.invokeMethod('getSharedText');
      
//     } on PlatformException catch (e) {
//       if (e.code == 'MissingPluginException' || e.code == 'UNAVAILABLE') {
//          // SIMULACIÓN para el entorno de Canvas
//          sharedText = 'https://mock.tienda-online.com/simulacion-producto-inicial-789-modelo-Y';
//          debugPrint('DEBUG: Usando URL de simulación via MethodChannel mock: $sharedText');
//       } else {
//         _showErrorAndNavigate('Error de plataforma al obtener el enlace: ${e.message}');
//         return;
//       }
//     } catch (e) {
//       _showErrorAndNavigate('Error inesperado al obtener el enlace: $e');
//       return;
//     }

//     if (sharedText != null && sharedText.isNotEmpty) {
//         _handleSharedText(sharedText);
//     } else {
//       // Si el canal nativo devuelve null (no hay intent), navegamos a la pantalla principal
//       _navigateToMainApp();
//     }
//   }

//   // Lógica de procesamiento del URL compartido
//   void _handleSharedText(String url) {
//     if (_isInitialIntentProcessed) return; 

//     if (!url.startsWith('http')) {
//        _showErrorAndNavigate('El contenido compartido no parece ser un enlace válido.');
//        return;
//     }
    
//     setState(() {
//       _isInitialIntentProcessed = true; // Marcamos el inicial como procesado
//     });

//     // --- LÓGICA DE PARSEO SIMULADO ---
//     final uri = Uri.tryParse(url);
//     String vendor = 'Web Desconocida';
//     String productName = 'Producto Compartido'; 

//     if (uri != null && uri.host.isNotEmpty) {
//       final host = uri.host.toLowerCase();
      
//       if (host.contains('amazon')) {
//         vendor = 'Amazon';
//         productName = 'Artículo de Amazon';
//       } else if (host.contains('elcorteingles')) {
//         vendor = 'El Corte Inglés';
//         productName = 'Artículo de El Corte Inglés';
//       } else if (host.contains('ebay')) {
//         vendor = 'eBay';
//         productName = 'Artículo de eBay';
//       } else if (host.contains('aliexpress')) {
//         vendor = 'AliExpress';
//         productName = 'Artículo de AliExpress';
//       } else if (host.contains('mock.tienda-online.com')) {
//          vendor = 'Tienda Mock (Channel)';
//       }
      
//       final pathSegments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
//       if (pathSegments.isNotEmpty && pathSegments.last.length > 5 && pathSegments.last.length < 50) {
//         productName = pathSegments.last.replaceAll('-', ' ');
//       }
//     }
    
//     final wishData = InitialWishData(
//       name: productName,
//       url: url,
//     );

//     // Reemplazamos esta pantalla por la de añadir deseo
//     Navigator.of(context).pushReplacement(
//       MaterialPageRoute(
//         builder: (context) => AddWishToListsScreen(wishData: wishData),
//       ),
//     );
//   }

//   void _navigateToMainApp() {
//     // Navegar a la pantalla principal si no hay un intent para procesar
//     Navigator.of(context).pushReplacement(
//       MaterialPageRoute(builder: (context) => const MyApp()),
//     );
//   }

//   void _showErrorAndNavigate(String message) {
//      WidgetsBinding.instance.addPostFrameCallback((_) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(message),
//           backgroundColor: Colors.red,
//           duration: const Duration(seconds: 4),
//         ),
//       );
//       _navigateToMainApp();
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Procesando Enlace...'),
//         backgroundColor: Colors.indigo.shade500,
//         foregroundColor: Colors.white,
//       ),
//       body: const Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             CircularProgressIndicator(),
//             SizedBox(height: 20),
//             Text('Obteniendo detalles del producto...', style: TextStyle(fontSize: 16)),
//           ],
//         ),
//       ),
//     );
//   }
// }
