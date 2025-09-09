import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wishy/models/contact.dart';

class UserDao {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _appId = 'wishy-app'; // Reemplaza con tu ID de app si es diferente

  // Singleton
  static final UserDao _instance = UserDao._internal();
  factory UserDao() => _instance;
   UserDao._internal();

  Future<void> createUser(String userId, String email, String name) async {
    await _db.collection('users').doc(userId).set({
      'email': email,
      'name': name,
      'createdAt': Timestamp.now(),
      'appId': _appId,
    });
  }

  Future<DocumentSnapshot?> getUserById(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    return doc.exists ? doc : null;
  }

  // Función para enviar una solicitud de contacto
  Future<void> sendContactRequest({
    required String email,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Usuario no autenticado.');
    }

    // Busca al usuario destinatario por su email
    final usersSnapshot = await _db.collection('users').where('email', isEqualTo: email).limit(1).get();

    if (usersSnapshot.docs.isEmpty) {
      throw Exception('No se encontró un usuario con ese email.');
    }

    final recipientDoc = usersSnapshot.docs.first;
    final recipientUid = recipientDoc.id;

    if (recipientUid == currentUser.uid) {
      throw Exception('No puedes agregarte a ti mismo como contacto.');
    }

    // Crea un documento con los datos de la solicitud en la subcolección del destinatario
    await _db
        .collection('users')
        .doc(recipientUid)
        .collection('contacts')
        .doc(currentUser.uid)
        .set({
      'userId': currentUser.uid,
      'name': currentUser.displayName,
      'email': currentUser.email,
      'status': 'pending',
      'requestDate': Timestamp.now(),
      'requestBy': currentUser.uid,
    });
  }

  // Función para aceptar una solicitud de contacto
  Future<void> acceptContact({
    required String requestDocId,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Usuario no autenticado.');
    }

    // Usa una transacción para asegurar la atomicidad de las operaciones
    return _db.runTransaction((transaction) async {
      final recipientContactRef = _db
          .collection('users')
          .doc(currentUser.uid)
          .collection('contacts')
          .doc(requestDocId);

      final recipientContactDoc = await transaction.get(recipientContactRef);

      if (!recipientContactDoc.exists ||
          recipientContactDoc.data()?['status'] != 'pending') {
        throw Exception('La solicitud de contacto no es válida o ya ha sido procesada.');
      }

      final senderUid = recipientContactDoc.data()?['userId'];

      // 1. Actualiza el estado de la solicitud en el documento del receptor
      transaction.update(recipientContactRef, {
        'status': 'accepted',
        'acceptanceDate': Timestamp.now(),
      });

      // 2. Crea el documento bidireccional en la subcolección del emisor
      final senderContactRef = _db
          .collection('users')
          .doc(senderUid)
          .collection('contacts')
          .doc(currentUser.uid);

      transaction.set(senderContactRef, {
        'userId': currentUser.uid,
        'name': currentUser.displayName,
        'email': currentUser.email,
        'status': 'accepted',
        'requestDate': recipientContactDoc.data()?['requestDate'],
        'acceptanceDate': Timestamp.now(),
        'requestBy': senderUid,
      });
    });
  }

  // Función para rechazar una solicitud de contacto (simplemente elimina el documento)
  Future<void> declineContact({required String requestDocId}) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Usuario no autenticado.');
    }
    await _db
        .collection('users')
        .doc(currentUser.uid)
        .collection('contacts')
        .doc(requestDocId)
        .delete();
  }

  // Función para obtener los UIDs de los contactos aceptados del usuario actual
  Future<List<Contact>> getAcceptedContacts() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return [];
    }

    final contactsSnapshot = await _db
        .collection('users')
        .doc(currentUser.uid)
        .collection('contacts')
        .where('status', isEqualTo: 'accepted')
        .get();

    return contactsSnapshot.docs.map((doc) => Contact.fromFirestore(doc)).toList();
  }

  Stream<QuerySnapshot> getAcceptedContactsStream() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // Retorna un stream vacío si no hay usuario
      return Stream.empty();
    }

    return _db
        .collection('users')
        .doc(currentUser.uid)
        .collection('contacts')
        .where('status', isEqualTo: 'accepted')
        .snapshots();
  }

  // Función para recuperar las solicitudes de contacto pendientes para el usuario actual
  Stream<QuerySnapshot> getPendingRequests() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // Retorna un stream vacío si no hay usuario
      return Stream.empty();
    }

    return _db
        .collection('users')
        .doc(currentUser.uid)
        .collection('contacts')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

}
