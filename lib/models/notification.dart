import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wishy/models/notification_type.dart';

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final String? senderId;
  final DateTime timestamp;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.senderId,
    required this.timestamp,
    this.isRead = false,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    var type = NotificationType.fromFirestore(data['type'])!;
    return AppNotification(
      id: doc.id,
      type: type,
      title: type.title,
      message: data['message'] as String,
      senderId: data['senderId'] as String?,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      isRead: data['isRead'] as bool? ?? false,
    );
  }
}
