import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventDao {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Singleton
  static final EventDao _instance = EventDao._internal();
  factory EventDao() => _instance;
  EventDao._internal();

  // Obtiene el stream de datos del usuario actual
  Stream<DocumentSnapshot> getCurrentUserStream() {
    final user = _auth.currentUser;
    if (user != null) {
      return _db.collection('users').doc(user.uid).snapshots();
    } else {
      throw Exception('No user is currently signed in.');
    }
  }

  void createOrUpdateEvent(String id, Map<String, Object> map) {
    _db.collection('events').doc(id).set(map, SetOptions(merge: true));
  }

  Stream<QuerySnapshot> getEventsSharedWithMe() {
    final user = _auth.currentUser;
    if (user != null) {
      return _db.collection('events').where(
        Filter.or(Filter('invitedUserIds', arrayContains: user.uid), Filter('ownerId', isEqualTo: user.uid))
      ).snapshots();
    } else {
      throw Exception('No user is currently signed in.');
    }
  }
}