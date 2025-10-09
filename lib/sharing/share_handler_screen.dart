// Importaciones necesarias
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:async';

import 'package:wishy/dao/wish_list_dao.dart';
import 'package:wishy/models/wish_list.dart';

// Componente principal para manejar el intento de compartir
class ShareHandlerScreen extends StatefulWidget {
  const ShareHandlerScreen({super.key});

  @override
  State<ShareHandlerScreen> createState() => _ShareHandlerScreenState();
}

class _ShareHandlerScreenState extends State<ShareHandlerScreen> {
  // Estado de la pantalla
  String _sharedText = '';
  String _sharedLink = '';
  bool _isLoading = true;
  bool _isSaving = false;
  String _selectedWishlistId = '';
  String _newWishlistName = '';
  final List<WishList> _wishlists = [];

  // Instancias de Firebase
  //final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream para recibir el intent
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    // Escuchar el intent cuando la app está en segundo plano
    /*_intentDataStreamSubscription =
        // Escuchar el intent cuando la app se abre por primera vez a través de "compartir"
    //ReceiveSharingIntent.get ;

    ReceiveSharingIntent.instance.getMediaStream().listen(  (List<SharedMediaFile> mediaList) {
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
    });
    */

    _loadUserWishlists();
  }

  // Cargar las listas del usuario desde Firestore
  Future<void> _loadUserWishlists() async {
    final user = _auth.currentUser;
    if (user == null) {
      // Manejar el caso de usuario no autenticado
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      /*final snapshot = await _db
          .collection('artifacts/__app_id/users/${user.uid}/wishlists')
          .get();*/
      /*Stream<QuerySnapshot<Map<String, dynamic>>> snapshot = WishlistDao().getWishlistsStreamSnapshot(user.uid);
      setState(() {
        _wishlists =
            snapshot.map((doc) => Wishlist.fromFirestore(doc)).toList().get();
        _isLoading = false;
      });*/
    } catch (e) {
      print('Error al cargar las listas: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Analizar el contenido compartido para extraer el enlace y el texto
  void _handleSharedContent(String value) {
    // Expresión regular para detectar URLs
    final urlRegex = RegExp(
        r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)');
    
    final match = urlRegex.firstMatch(value);
    
    if (match != null) {
      // Si se encuentra un enlace, separamos el texto de la URL
      setState(() {
        _sharedLink = match.group(0)!;
        _sharedText = value.replaceAll(urlRegex, '').trim();
      });
    } else {
      // Si no hay enlace, todo el contenido es texto
      setState(() {
        _sharedText = value;
      });
    }
  }

  // Guardar el ítem en la lista de deseos seleccionada o nueva
  Future<void> _saveItem() async {
    if (_isSaving) return;
    
    // Validar la entrada del usuario
    if (_selectedWishlistId.isEmpty && _newWishlistName.trim().isEmpty) {
      _showSnackbar('Por favor, selecciona una lista o crea una nueva.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final user = _auth.currentUser;
    if (user == null) {
      _showSnackbar('Usuario no autenticado. Por favor, inicia sesión.');
      setState(() {
        _isSaving = false;
      });
      return;
    }

    try {
      String targetWishlistId = _selectedWishlistId;

      if (targetWishlistId.isEmpty) {
        // Crear una nueva lista de deseos
        final newWishlistRefId = await WishlistDao().createWishlist({
          'name': _newWishlistName.trim(),
          'ownerId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        targetWishlistId = newWishlistRefId;
      }

      // Añadir el ítem a la lista
      await WishlistDao().addItem(targetWishlistId, {
        'name': _sharedText.isNotEmpty ? _sharedText : _sharedLink,
        'link': _sharedLink.isNotEmpty ? _sharedLink : null,
        'description': '',
        'addedBy': user.uid,
        'isPurchased': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _showSnackbar('¡Ítem guardado con éxito!');
      // Cerrar la pantalla después de guardar
      Navigator.of(context).pop();
    } catch (e) {
      print('Error al guardar el ítem: $e');
      _showSnackbar('Error al guardar el ítem. Inténtalo de nuevo.');
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si la app se abre sin un intent, no mostramos nada
    if (_sharedText.isEmpty && _sharedLink.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Añadir a lista de deseos'),
        centerTitle: true,
        backgroundColor: Colors.indigo.shade500,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mostrar el contenido compartido
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Contenido compartido:',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54)),
                          const SizedBox(height: 8),
                          if (_sharedLink.isNotEmpty)
                            Text(_sharedLink,
                                style: const TextStyle(
                                    color: Colors.indigo,
                                    decoration: TextDecoration.underline)),
                          if (_sharedText.isNotEmpty)
                            Text(_sharedText,
                                style: const TextStyle(
                                    color: Colors.black87, fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Opciones de lista de deseos
                  const Text('Elige una lista o crea una nueva:',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  // Selector de listas existentes
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Listas existentes',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    initialValue: _selectedWishlistId.isEmpty ? null : _selectedWishlistId,
                    items: [
                      const DropdownMenuItem(
                        value: '',
                        child: Text('-- Selecciona una lista --'),
                      ),
                      ..._wishlists.map((list) {
                        return DropdownMenuItem(
                          value: list.getId(),
                          child: Text(list.get(WishListFields.name),
                          )
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedWishlistId = value ?? '';
                        // Limpiar el campo de nueva lista si se selecciona una existente
                        if (_selectedWishlistId.isNotEmpty) {
                          _newWishlistName = '';
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Separador
                  const Center(
                    child: Text('o',
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.black54,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  
                  // Campo para nueva lista
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la nueva lista',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _newWishlistName = value;
                        // Limpiar la selección si se empieza a escribir una nueva
                        if (_newWishlistName.isNotEmpty) {
                          _selectedWishlistId = '';
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Botón para guardar
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveItem,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.indigo.shade500,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.add),
                    label: Text(_isSaving ? 'Guardando...' : 'Guardar ítem'),
                  ),
                ],
              ),
            ),
    );
  }
}

/*void _processSharedMedia(List<SharedMediaFile> mediaList) {
}*/

// Modelo de datos para una lista de deseos
/*class Wishlist {
  final String id;
  final String name;

  Wishlist({required this.id, required this.name});

  factory Wishlist.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Wishlist(
      id: doc.id,
      name: data['name'] ?? 'Sin nombre',
    );
  }
}
*/