import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wishy/dao/user_dao.dart';
import 'package:wishy/models/contact.dart';
import 'package:wishy/screens/user/edit_contact_screen.dart';

class ContactsListScreen extends StatelessWidget {
  const ContactsListScreen({super.key});

  // Método para obtener el Stream de contactos del usuario actual
  Stream<List<Contact>> _getContactsStream() {
    // 1. Obtener el usuario autenticado
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Si no hay usuario autenticado, retornamos un Stream vacío inmediatamente
      return Stream.value([]);
    }

    // 3. Retornar el Stream de consultas (snapshot)
    return UserDao().getAcceptedContactsStream().map((snapshot) {
      // Mapear cada documento (QueryDocumentSnapshot) a un objeto Contacto
      return snapshot.docs.map((doc) {
        return Contact.fromFirestore(doc);
      }).toList();
    });
  }

  // Widget para manejar los diferentes estados de la carga de datos
  Widget _buildContent(AsyncSnapshot<List<Contact>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      // Estado de carga inicial
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      // Estado de error (ej. problemas de red o permisos)
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Error al cargar los contactos: ${snapshot.error}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    // Estado sin datos o lista vacía
    final contacts = snapshot.data;
    if (contacts == null || contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_alt_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No tienes contactos aún.',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Añade amigos para compartir tus listas de deseos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Estado de datos cargados (lista de contactos)
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Text(
                contact.name?? '',
                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              contact.name?? '',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (contact.email.isNotEmpty) Text(contact.email),
                // Text(
                //   'ID de Usuario: ${contact.userId.substring(0, 8)}...', // Muestra solo los primeros caracteres del ID
                //   style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                // ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.pop(context);
              // Navega a la pantalla de perfil
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditContactScreen(contact: contact),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Nota: Es fundamental que el usuario esté previamente autenticado (con signInWithCustomToken)
    // antes de que esta pantalla se cargue para que FirebaseAuth.instance.currentUser no sea null.
    
    // Si el usuario no está autenticado, mostramos un mensaje de error o solicitamos el login.
    if (FirebaseAuth.instance.currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mis Contactos'),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            'Inicia sesión para ver tus contactos.',
            style: TextStyle(fontSize: 16, color: Colors.red),
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Contactos'),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Simulación: Pantalla para añadir un nuevo contacto')),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Contact>>(
        stream: _getContactsStream(),
        builder: (context, snapshot) {
          return _buildContent(snapshot);
        },
      ),
    );
  }
}