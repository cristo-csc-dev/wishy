import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wishy/dao/wish_list_dao.dart';
import 'package:wishy/mocks/mocks.dart';
import 'package:wishy/models/wish_list.dart';
import 'package:wishy/screens/create_edit_contact_screen.dart';
import 'package:wishy/screens/create_edit_list_screen.dart';
import 'package:wishy/screens/friend_list_overview_screen.dart';
import 'package:wishy/screens/list_detail_screen.dart';
import 'package:wishy/widgets/list_card.dart';
import 'package:wishy/models/event.dart'; // ¡NUEVO!
import 'package:wishy/screens/create_edit_event_screen.dart'; // ¡NUEVO!
import 'package:wishy/screens/event_detail_screen.dart'; // ¡NUEVO!



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  //final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Cambia a 3 pestañas: 0 para Mis Listas, 1 para Listas para Regalar, 2 para Eventos
  int _selectedIndex = 0; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishlist'),
        leading: IconButton(
          icon: const Icon(Icons.person),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Menú de Perfil/Ajustes')));
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _signOut();
              //ScaffoldMessenger.of(context).showSnackBar(
              //    const SnackBar(content: Text('Función de Búsqueda')));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSegmentedControl(),
          Expanded(
            child: IndexedStack( // Usamos IndexedStack para mantener el estado de cada vista
              index: _selectedIndex,
              children: [
                _buildMyListsView(),
                _buildGiftListsContactsView(),
                _buildEventsView(), // ¡NUEVO!
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Si estamos en la pestaña de eventos, el FAB crea un evento
          if (_selectedIndex == 2) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateEditEventScreen()),
            );
            if (result != null && result is Event) {
              setState(() {
                userEvents.add(result);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Evento "${result.name}" creado.')));
            }
          } else if (_selectedIndex == 1) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateEditContactScreen()),
            );
            if (result != null && result is WishList) {
              setState(() {
                userWishLists.add(result);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lista "${result.name}" creada.')));
            }
          } else { // Si no, crea una lista normal
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateEditListScreen()),
            );
            if (result != null && result is WishList) {
              setState(() {
                userWishLists.add(result);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lista "${result.name}" creada.')));
            }
          }
        },
        child: Icon(_selectedIndex == 2 ? Icons.event : Icons.add), // Icono dinámico
      ),
    );
  }

  // Modificación en _buildSegmentedControl para 3 pestañas
  Widget _buildSegmentedControl() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () { setState(() { _selectedIndex = 0; }); },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                decoration: BoxDecoration(
                  color: _selectedIndex == 0 ? Colors.blueGrey.shade100 : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text('Deseos', style: TextStyle(fontWeight: _selectedIndex == 0 ? FontWeight.bold : FontWeight.normal, color: _selectedIndex == 0 ? Colors.blueGrey.shade800 : Colors.grey.shade700)),
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () { setState(() { _selectedIndex = 1; }); },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                decoration: BoxDecoration(
                  color: _selectedIndex == 1 ? Colors.blueGrey.shade100 : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text('Contactos', style: TextStyle(fontWeight: _selectedIndex == 1 ? FontWeight.bold : FontWeight.normal, color: _selectedIndex == 1 ? Colors.blueGrey.shade800 : Colors.grey.shade700)),
                ),
              ),
            ),
          ),
          Expanded( // ¡NUEVA PESTAÑA!
            child: InkWell(
              onTap: () { setState(() { _selectedIndex = 2; }); },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                decoration: BoxDecoration(
                  color: _selectedIndex == 2 ? Colors.blueGrey.shade100 : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text('Eventos', style: TextStyle(fontWeight: _selectedIndex == 2 ? FontWeight.bold : FontWeight.normal, color: _selectedIndex == 2 ? Colors.blueGrey.shade800 : Colors.grey.shade700)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ... ( _buildMyListsView y _buildGiftListsContactsView permanecen igual ) ...


  Widget _buildMyListsView() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(child: Text('Inicia sesión para ver tus listas.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: WishlistDao().getWishlistsStreamSnapshot(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No tienes listas de deseos. ¡Crea una!'),
          );
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final list = WishList.fromFirestore(doc);
            return ListCard(
              wishList: list,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ListDetailScreen(wishList: list),
                  ),
                );
                // No necesitamos setState() aquí, ya que el StreamBuilder se encargará de la actualización
              },
              onEdit: () async {
                final updatedList = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateEditListScreen(wishList: list),
                  ),
                );
                // No necesitamos setState() aquí
                if (updatedList != null && updatedList is WishList) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lista "${updatedList.name}" actualizada.')));
                }
              },
              onShare: () {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Compartir lista "${list.name}"')));
              },
              onDelete: () {
                _showDeleteConfirmationDialog(list);
              },
            );
          },
        );
      },
    );
  }

  // --- ¡NUEVA VISTA PARA EVENTOS! ---
  Widget _buildEventsView() {
    if (userEvents.isEmpty) {
      return const Center(
        child: Text('No has creado ni participas en ningún evento aún. ¡Crea uno!'),
      );
    }
    return ListView.builder(
      itemCount: userEvents.length,
      itemBuilder: (context, index) {
        final event = userEvents[index];
        // Aquí podrías usar un EventCard widget reutilizable
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () async {
              // Navegar a la pantalla de detalle del evento
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailScreen(event: event),
                ),
              );
              setState(() {}); // Refrescar si hay cambios en el evento
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fecha: ${event.eventDate.toIso8601String().split('T')[0]}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  Text(
                    'Tipo: ${event.type.toString().split('.').last}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text('Participantes: ${event.participantUserIds.length}'),
                  // Miniaturas de los participantes (opcional)
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGiftListsContactsView() {
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
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: contact.avatarUrl != null && contact.avatarUrl!.isNotEmpty
                        ? NetworkImage(contact.avatarUrl!)
                        : null,
                    child: contact.avatarUrl == null || contact.avatarUrl!.isEmpty
                        ? const Icon(Icons.person, size: 30, color: Colors.white)
                        : null,
                    backgroundColor: Colors.blueGrey.shade200,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          contact.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${contact.sharedWishLists.length} Listas de Deseos',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        if (contact.nextEventDate != null)
                          Text(
                            'Próximo Evento: ${contact.nextEventDate!.toIso8601String().split('T')[0]}',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ... ( _showDeleteConfirmationDialog permanece igual ) ...
  void _showDeleteConfirmationDialog(WishList list) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar Lista'),
          content: Text('¿Estás seguro de que quieres eliminar la lista "${list.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  userWishLists.remove(list);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lista "${list.name}" eliminada.')));
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
  
  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    // Después de cerrar sesión, el StreamBuilder en main.dart detectará el cambio
    // y navegará automáticamente a la pantalla de autenticación.
    // Simplemente cierra la pantalla de perfil.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}