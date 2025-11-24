import 'package:flutter/material.dart';
import 'package:wishy/dao/notification_dao.dart';
import 'package:wishy/models/notification.dart';
import 'package:wishy/screens/notification/types/notification_type.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();

}

class _NotificationListScreenState extends State<NotificationListScreen> {
  final notificationDao = NotificationDao();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
      ),
      body: StreamBuilder<List<AppNotification>>(
        stream: notificationDao.getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay notificaciones.'));
          }

          final notifications = snapshot.data!;
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(context, notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, AppNotification notification) {
    IconData icon;
    String subtitle;
    VoidCallback? onTap;
    bool showActionButtons = false;

    // Selecciona el icono y la acción según el tipo de notificación.
    switch (notification.type) {
      case NotificationType.contactRequest:
        icon = Icons.person_add;
        subtitle = notification.message;
        showActionButtons = true;
        break;
      case NotificationType.contactAccepted:
        icon = Icons.check_circle;
        subtitle = 'Tu solicitud de contacto ha sido aceptada.';
        break;
      case NotificationType.eventInvitation:
        icon = Icons.event;
        subtitle = 'Has sido invitado a un evento.';
        showActionButtons = true;
        break;
      default:
        icon = Icons.info;
        subtitle = 'Notificación desconocida.';
        break;
    }

    return notification.type.getNotificationDecorator().decorate(context, notification);

  }
}
