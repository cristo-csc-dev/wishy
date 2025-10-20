import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wishy/models/notification.dart';

class NotificationDao {
  final _db = FirebaseFirestore.instance;

  Stream<List<AppNotification>> getNotificationsStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Stream.value([]);
    }

    // Escucha los cambios en la subcolección de notificaciones del usuario actual.
    return _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => AppNotification.fromFirestore(doc)).toList());
  }

  void getNotificationsCount(Function(QuerySnapshot) onEvent) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return;
    }

    // Escucha los cambios en la subcolección de notificaciones del usuario actual.
    _db.collection('users')
      .doc(uid)
      .collection('notifications').snapshots().listen(
        (event) => onEvent(event),
        onError: (error) => print("Error al obtener el conteo de notificaciones: $error"),
      );
  }
}