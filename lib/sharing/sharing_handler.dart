// lib/sharing_handler.dart
import 'dart:async';

// Una clase simple para estructurar el contenido compartido
class SharedContent {
  final String? text;
  final List<String>? imagePaths;
  final List<String>? videoPaths;
  final List<String>? filePaths; // Para cualquier otro tipo de archivo

  SharedContent({
    this.text,
    this.imagePaths,
    this.videoPaths,
    this.filePaths,
  });

  @override
  String toString() {
    String output = '';
    if (text != null) output += 'Texto: "$text"\n';
    if (imagePaths != null && imagePaths!.isNotEmpty) output += 'Imágenes: ${imagePaths!.join(', ')}\n';
    if (videoPaths != null && videoPaths!.isNotEmpty) output += 'Videos: ${videoPaths!.join(', ')}\n';
    if (filePaths != null && filePaths!.isNotEmpty) output += 'Archivos: ${filePaths!.join(', ')}\n';
    return output.isEmpty ? 'No se recibió contenido.' : output.trim();
  }
}

class SharingHandler {
  // Un StreamController para emitir el contenido compartido a los escuchadores
  final _sharedContentController = StreamController<SharedContent?>.broadcast();

  // Expone el stream de contenido compartido
  Stream<SharedContent?> get sharedContentStream => _sharedContentController.stream;

  // Suscripciones para limpiar al finalizar
  StreamSubscription? _textStreamSubscription;
  StreamSubscription? _mediaStreamSubscription;

  SharingHandler() {
    _initListeners();
  }

  // Inicializa los escuchadores para intents iniciales y nuevos intents
  void _initListeners() {
    // Escuchar el intent cuando la app se abre por primera vez a través de "compartir"
    //ReceiveSharingIntent.get ;
    /*ReceiveSharingIntent.instance.getMediaStream().listen(  (List<SharedMediaFile> mediaList) {
      if (mediaList.isNotEmpty) {
        _processSharedMedia(mediaList);
      }
    }, onError: (err) {
      print("Error al recibir media: $err");
    });

    // Escuchar intents mientras la app ya está abierta
    ReceiveSharingIntent.instance.getMediaStream().listen( (List<SharedMediaFile> mediaList) {
      if (mediaList.isNotEmpty) {
        _processSharedMedia(mediaList);
      }
    }, onError: (err) {
      print("Error al recibir media: $err");
    });*/
  }

  // Procesa la lista de archivos multimedia compartidos
  /*void _processSharedMedia(List<SharedMediaFile> mediaList) {
    List<String> imagePaths = [];
    List<String> videoPaths = [];
    List<String> filePaths = [];

    for (var media in mediaList) {
      if (media.type == SharedMediaType.image) {
        imagePaths.add(media.path);
      } else if (media.type == SharedMediaType.video) {
        videoPaths.add(media.path);
      } else {
        // En Android, SharedMediaFile puede ser usado para otros archivos también
        // Si el tipo es FILE, o si no es imagen/video, se considera un archivo general
        filePaths.add(media.path);
      }
    }
    _sharedContentController.add(SharedContent(
      imagePaths: imagePaths.isNotEmpty ? imagePaths : null,
      videoPaths: videoPaths.isNotEmpty ? videoPaths : null,
      filePaths: filePaths.isNotEmpty ? filePaths : null,
    ));
  }

  // Limpia los recursos cuando la clase ya no es necesaria
  void dispose() {
    _textStreamSubscription?.cancel();
    _mediaStreamSubscription?.cancel();
    _sharedContentController.close();
  }*/
}
