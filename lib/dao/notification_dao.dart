import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wishy/auth/user_auth.dart';
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

  Stream<QuerySnapshot<Map<String, dynamic>>> getNotificationsCount() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (!UserAuth.isUserAuthenticatedAndVerified()) {
      throw Exception('Usuario no autenticado.');
    }
    // Escucha los cambios en la subcolección de notificaciones del usuario actual.
    return _db.collection('users')
      .doc(uid)
      .collection('notifications').snapshots();
  }
}