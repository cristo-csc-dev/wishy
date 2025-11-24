import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wishy/screens/notification/types/notification_type.dart';

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final Sender sender;
  final DateTime timestamp;
  final bool isRead;
  final DocumentReference? contactRef;
  DocumentSnapshot? docRef;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.sender,
    required this.timestamp,
    this.isRead = false,
    this.contactRef,
    this.docRef,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    var type = NotificationType.fromFirestore(data['type'])!;
    return AppNotification(
      id: doc.id,
      type: type,
      title: type.title,
      message: data['message'] as String,
      sender: Sender.fromMap(data['sender'] as Map<String, dynamic>),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] as bool? ?? false,
      contactRef: data['ref'] as DocumentReference?,
      docRef: doc,
    );
  }
}

class Sender {
  final String id;
  final String name;
  final String email;

  Sender({
    required this.id,
    required this.name,
    required this.email,
  });

  factory Sender.fromMap(Map<String, dynamic> data) {
    return Sender(
      id: data['uid'] as String,
      name: data['name']?? "Anónimo",
      email: data['email'] as String,
    );
  }
}
