import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wishy/dao/user_dao.dart';
import 'package:wishy/models/contact_request.dart';

class ContactRequestsScreen extends StatefulWidget {
  const ContactRequestsScreen({super.key});

  @override
  State<ContactRequestsScreen> createState() => _ContactRequestsScreenState();
}

class _ContactRequestsScreenState extends State<ContactRequestsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Acepta una solicitud de contacto
  Future<void> _acceptRequest(ContactRequest request) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // 1. Aceptar la solicitud en la base de datos del usuario actual
      await acceptRequest(currentUser, request);


      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Solicitud de ${request.senderName} aceptada correctamente.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al aceptar la solicitud: $e')),
      );
    }
  }

  Future<void> acceptRequest(User currentUser, ContactRequest request) async {
    await UserDao().updateContact(currentUser, request);
    
    // 2. Crear una entrada recíproca para el remitente
    UserDao().acceptRequest(currentUser, request);
  }

  // Rechaza una solicitud de contacto
  Future<void> _declineRequest(String requestId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      await UserDao().declineRequest(currentUser, requestId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud de contacto rechazada.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al rechazar la solicitud: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notificaciones')),
        body: const Center(
          child: Text('Inicia sesión para ver las notificaciones.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: UserDao().getPendingRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
                child: Text('No notificaciones pendientes.'));
          }

          final requests = snapshot.data!.docs
              .map((doc) => ContactRequest.fromFirestore(doc))
              .toList();

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(request.senderName),
                  subtitle: Text(request.senderEmail),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => _acceptRequest(request),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _declineRequest(request.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
