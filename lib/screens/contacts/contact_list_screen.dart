import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wishy/auth/user_auth.dart';
import 'package:wishy/dao/user_dao.dart';
import 'package:wishy/models/contact.dart';
import 'package:wishy/screens/contacts/create_edit_contact_request_screen.dart';
import 'package:wishy/screens/contacts/edit_contact_screen.dart';
import 'package:wishy/screens/contacts/friend_list_overview_screen.dart';

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
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No tienes contactos aún.'),
          );
        }

        var contactsWithSharedLists = snapshot.data!;

        if (contactsWithSharedLists.isEmpty) {
          return const Center(
            child: Text('Nadie ha compartido una lista contigo aún.'),
          );
        }

        return ListView.builder(
          itemCount: contactsWithSharedLists.length,
          itemBuilder: (context, index) {
            final contact = contactsWithSharedLists[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FriendListsOverviewScreen(contact: contact),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            child: Text(
                              contact.name?? '',
                              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                            ),
                          ), // Usar un icono de la lista
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              contact.name?? contact.email,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: () {}, 
                            icon: const Icon(Icons.edit)
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          });
  }

  @override
  Widget build(BuildContext context) {
    // Nota: Es fundamental que el usuario esté previamente autenticado (con signInWithCustomToken)
    // antes de que esta pantalla se cargue para que FirebaseAuth.instance.currentUser no sea null.
    
    // Si el usuario no está autenticado, mostramos un mensaje de error o solicitamos el login.
    if (!UserAuth.isUserAuthenticatedAndVerified()) {
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Si estamos en la pestaña de eventos, el FAB crea un evento
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateEditContactRequestScreen()),
          );
        },
        child: Icon(Icons.add), // Icono dinámico
      )
    );
  }
}