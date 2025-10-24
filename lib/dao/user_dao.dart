import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wishy/models/contact.dart';
import 'package:wishy/models/contact_request.dart';
import 'package:wishy/models/notification.dart';

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
    required String? message,
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

    DocumentSnapshot doc = await _db.collection('users')
        .doc(recipientUid)
        .collection('contacts')
        .doc(currentUser.uid)
        .get();
    Map<String, dynamic>? data = {};
    if (doc.exists) {
      data = doc.data() as Map<String, dynamic>;
      if (data['status'] == 'pending') {
        throw Exception('Ya has enviado una solicitud de contacto a este usuario.');
      } else if (data['status'] == 'accepted') {
        throw Exception('Este usuario ya es tu contacto.');
      } else if (data['status'] == 'blocked') {
        throw Exception('No ha sido posible añadir este contacto.');
      }
    } else {
      data = {
      'userId': currentUser.uid,
      'name': currentUser.displayName,
      'message': message,
      'email': currentUser.email,
      'status': 'pending',
      'requestDate': Timestamp.now(),
      'requestBy': currentUser.uid,
    };
    }

    // Crea un documento con los datos de la solicitud en la subcolección del destinatario
    await _db
        .collection('users')
        .doc(currentUser.uid)
        .collection('contacts')
        .doc(recipientUid)
        .set(data, SetOptions(merge: true));
  }

  // Función para aceptar una solicitud de contacto
  Future<void> _responseContactRequest({
      required String response,
      required AppNotification notification,
    }) async {
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Usuario no autenticado.');
    }

    // Usa una transacción para asegurar la atomicidad de las operaciones
    return _db.runTransaction((transaction) async {

      DocumentSnapshot requestContact = await transaction.get(notification.contactRef!);

      if (!requestContact.exists ||
          requestContact['status'] != 'pending') {
        throw Exception('La solicitud de contacto no es válida o ya ha sido procesada.');
      }

      await notification.contactRef!.set( {
        'status': response,
        'acceptanceDate': Timestamp.now(),
      }, SetOptions(merge: true));

      // 2. Crea el documento bidireccional en la subcolección del emisor
      _db
        .collection('users')
        .doc(currentUser.uid)
        .collection('contacts')
        .doc(notification.sender.id)
        .set({
          'userId': currentUser.uid,
          'name': notification.sender.name,
          'email': notification.sender.email,
          'status': response,
          'requestDate': requestContact['requestDate'],
          'acceptanceDate': Timestamp.now(),
          'requestBy': notification.sender.id,
        }, SetOptions(merge: true));
      notification.docRef!.reference.delete();
    });
  }

  // Función para aceptar una solicitud de contacto
  Future<void> acceptContact({required AppNotification notification}) async {
    return _responseContactRequest(response: "accepted", notification: notification);
  }

  // Función para rechazar una solicitud de contacto
  Future<void> declineContact({required AppNotification notification}) async {
    return _responseContactRequest(response: "declined", notification: notification);
  }

  // Función para rechazar una solicitud de contacto 
  Future<void> blockContact({required AppNotification notification}) async {
    return _responseContactRequest(response: "blocked", notification: notification);
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

  Future<void> updateContact(User currentUser, ContactRequest request) async {
    final userContactRef = _db
        .collection('users')
        .doc(currentUser.uid)
        .collection('contacts')
        .doc(request.id);
    
    await userContactRef.update({
      'acceptanceDate': FieldValue.serverTimestamp(),
      'status': 'accepted',
    });
  }
}
