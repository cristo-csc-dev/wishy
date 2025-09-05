import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ContactDao {
  static final ContactDao _instance = ContactDao._internal();

  factory ContactDao() {
    return _instance;
  }

  ContactDao._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> addContact(String name, String email) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Usuario no autenticado');
    }

    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('contacts')
          .add({
        'name': name,
        'email': email,
        'requestDate': FieldValue.serverTimestamp(),
        'acceptanceDate': null,
        'requestBy': user.uid,
      });
    } catch (e) {
      throw Exception('Error al guardar el contacto: $e');
    }
  }

  Future<void> acceptContact(String contactId, String acceptingUserId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Usuario no autenticado');
    }

    // Usar una transacción para asegurar que ambas escrituras sean atómicas.
    await _db.runTransaction((transaction) async {
      // 1. Obtener el documento del contacto en la lista del solicitante.
      final contactDocRef = _db
          .collection('users')
          .doc(contactId) // El contactId es el UID del usuario que envió la solicitud.
          .collection('contacts')
          .doc(acceptingUserId); // El acceptingUserId es el ID del documento del contacto.
          
      final contactDoc = await transaction.get(contactDocRef);
      if (!contactDoc.exists) {
        throw Exception('El documento de contacto no existe.');
      }

      // 2. Actualizar el documento del solicitante para indicar que la solicitud fue aceptada.
      transaction.update(contactDocRef, {
        'acceptanceDate': FieldValue.serverTimestamp(),
      });

      // 3. Crear un nuevo documento de contacto en la colección del usuario que acepta.
      // Esta es la parte que crea la relación bidireccional.
      await _db
          .collection('users')
          .doc(currentUser.uid)
          .collection('contacts')
          .add({
        'name': contactDoc['name'],
        'email': contactDoc['email'],
        'requestDate': FieldValue.serverTimestamp(),
        'acceptanceDate': FieldValue.serverTimestamp(),
        'requestBy': contactDoc['requestBy'],
      });
    });
  }
}
