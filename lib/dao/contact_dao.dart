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
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al guardar el contacto: $e');
    }
  }
}
