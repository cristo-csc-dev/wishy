import 'package:flutter/material.dart';
import 'package:wishy/dao/notification_dao.dart';
import 'package:wishy/dao/user_dao.dart';
import 'package:wishy/models/notification.dart';
import 'package:wishy/models/notification_type.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationListScreen extends StatefulWidget {
  const NotificationListScreen({super.key});

  @override
  State<NotificationListScreen> createState() => _NotificationListScreenState();

  void _setState() {
    toString();
  }
}

class _NotificationListScreenState extends State<NotificationListScreen> {
  final notificationDao = NotificationDao();

  // Instancias de Firebase
  final _auth = FirebaseAuth.instance;

  // Lógica para aceptar una notificación
  Future<void> _handleAccept(AppNotification notification) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Usuario no autenticado.')),
      );
      return;
    }

    try {
      // Actualiza el documento en Firestore para marcarlo como aceptado

      // TODO: Aquí se debe implementar la lógica real,
      // por ejemplo: aceptar la solicitud de contacto
      // o unirse a un evento.
      print('Notificación ${notification.id} aceptada.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notificación aceptada.')),
      );
      widget._setState();
    } catch (e) {
      print('Error al aceptar la notificación: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al procesar la solicitud.')),
      );
    }
  }

  // Lógica para rechazar una notificación
  Future<void> _handleReject(AppNotification notification) async {
    final user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Usuario no autenticado.')),
      );
      return;
    }

    try {
      // Actualiza el documento en Firestore para marcarlo como rechazado
      await UserDao().rejectContactRequest(user, notification);

      // TODO: Aquí se debe implementar la lógica real,
      // por ejemplo: rechazar la solicitud de contacto
      // o la invitación a un evento.
      print('Notificación ${notification.id} rechazada.');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notificación rechazada.')),
      );
    } catch (e) {
      print('Error al rechazar la notificación: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al procesar la solicitud.')),
      );
    }
  }

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
        subtitle = 'Tienes una nueva solicitud de contacto.';
        showActionButtons = true;
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon),
            title: Text(notification.title),
            subtitle: Text(subtitle),
            trailing: notification.isRead
                ? null
                : const Icon(Icons.circle, size: 10, color: Colors.blue),
            onTap: onTap,
          ),
          if (showActionButtons && !notification.isRead)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _handleReject(notification),
                    child: const Text('Rechazar', style: TextStyle(color: Colors.red)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _handleAccept(notification),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Aceptar'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
