import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:wishy/auth/user_auth.dart';
import 'package:wishy/dao/event_dao.dart';
import 'package:wishy/dao/notification_dao.dart';
import 'package:wishy/dao/user_dao.dart';
import 'package:wishy/dao/wish_list_dao.dart';
import 'package:wishy/intent/android_intent.dart';
import 'package:wishy/models/contact.dart';
import 'package:wishy/models/wish_item.dart';
import 'package:wishy/models/wish_list.dart';
import 'package:wishy/screens/notification/notification_list_screen.dart';
import 'package:wishy/screens/wish/add_wish_screen.dart';
import 'package:wishy/screens/contacts/friend_list_overview_screen.dart';
import 'package:wishy/screens/wish/list_detail_screen.dart';
import 'package:wishy/widgets/list_card.dart';
import 'package:wishy/models/event.dart'; // ¡NUEVO!
import 'package:wishy/screens/event/event_detail_screen.dart'; // ¡NUEVO!

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  String _sharedLink = "{}";
  static const platform = MethodChannel('com.wishysa.wishy/channel');
  StreamSubscription? _notificationCountSubscription;


  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Cambia a 3 pestañas: 0 para Mis Listas, 1 para Listas para Regalar, 2 para Eventos
  int _selectedIndex = 0; 
  int _pendingRequestsCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchNotificationsCount();
    platform.setMethodCallHandler(_handleMethodCalls);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishy'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationListScreen(),
                    ),
                  );
                },
              ),
              if (_pendingRequestsCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: Text(
                      '$_pendingRequestsCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      drawer: _buildAppDrawer(),
      body: Column(
        children: [
          _buildSegmentedControl(),
          Expanded(
            child: IndexedStack( // Usamos IndexedStack para mantener el estado de cada vista
              index: _selectedIndex,
              children: [
                _buildMyListsView(),
                _buildGiftListsContactsView(),
                //_buildEventsView(), // ¡NUEVO!
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: (_selectedIndex == 0)? FloatingActionButton(
        onPressed: () async {
          // Si estamos en la pestaña de eventos, el FAB crea un evento
          final newListName = await context.push('/wishlist/add'); // Volver a Home después de crear la lista
          if(context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Lista "$newListName" creada.')));
          }
        },
        child: Icon(_selectedIndex == 2 ? Icons.event : Icons.add), // Icono dinámico
      ): null,
    );
  }

  void _fetchNotificationsCount() {
    if (UserAuth.instance.isUserAuthenticatedAndVerified()) {
      _notificationCountSubscription =
      NotificationDao().getNotificationsCount().listen((QuerySnapshot snapshot) {
        if (mounted) { // 3. Opcional, pero buena práctica: comprobar 'mounted' antes de setState
          setState(() {
            _pendingRequestsCount = snapshot.docs.length;
          });
        }
      }, onError: (error) {
          if (mounted) {
              setState(() {
                   _pendingRequestsCount = 0;
              });
          }
      });
    }
  }

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
                  child: Text('Míos', style: TextStyle(fontWeight: _selectedIndex == 0 ? FontWeight.bold : FontWeight.normal, color: _selectedIndex == 0 ? Colors.blueGrey.shade800 : Colors.grey.shade700)),
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
                  child: Text('Suyos', style: TextStyle(fontWeight: _selectedIndex == 1 ? FontWeight.bold : FontWeight.normal, color: _selectedIndex == 1 ? Colors.blueGrey.shade800 : Colors.grey.shade700)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- VISTA DE MIS LISTAS ---
  Widget _buildMyListsView() {
    final user = _auth.currentUser;
    if (user == null || !user.emailVerified) {
      return const Center(child: Text('Inicia sesión para ver tus listas.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: WishlistDao().getWishlistsStreamSnapshot(user.uid),
      builder: (context, myWishlistsSnapshot) {
        if (myWishlistsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (myWishlistsSnapshot.hasError) {
          return Center(child: Text('Error: ${myWishlistsSnapshot.error}'));
        }

        if (!myWishlistsSnapshot.hasData || myWishlistsSnapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No tienes listas de deseos. ¡Crea una!'),
          );
        }

        return ListView.builder(
          itemCount: myWishlistsSnapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = myWishlistsSnapshot.data!.docs[index];
            final list = WishList.fromFirestore(doc);
            return ListCard(
              wishList: list,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ListDetailScreen(userId: UserAuth.instance.getCurrentUser().uid,wishListId: list.id!),
                  ),
                );
                // No necesitamos setState() aquí, ya que el StreamBuilder se encargará de la actualización
              },
              onEdit: () async {
                context.go('/home/wishlist/${list.id}/edit');
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

  Widget _buildGiftListsContactsView() {
    return StreamBuilder<QuerySnapshot>(
      stream: UserDao().getAcceptedContactsStream(),
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('Nadie ha compartido una lista contigo aún.'),
          );
        }

        var contactsWithSharedLists = snapshot.data!.docs
            .map((doc) => Contact.fromFirestore(doc))
            .toList();

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
                      builder: (context) => FriendListsOverviewScreen(contactId: contact.id),
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
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          });
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
                  //userWishLists.remove(list);
                });
                WishlistDao().deleteWishlist(list.id!);
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
    UserAuth.instance.signOut();
  }

  Future<void> _handleMethodCalls(MethodCall call) async {
    if (call.method == 'onSharedText') {
      _sharedLink = call.arguments;
      final Map<String, dynamic> jsonData = jsonDecode(_sharedLink);
      dev.log("Received shared text: $jsonData");
      WishItem wishDataItem = getWishItemFromMap(jsonData)!;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AddWishScreen(wishItemId: wishDataItem.id),
        ),
      );
    }
  }

  Widget _buildAppDrawer() {
    final user = _auth.currentUser;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(user?.displayName ?? "Nombre de Usuario"),
            accountEmail: Text(user?.email ?? ""),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage:
                  user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              child: user?.photoURL == null
                  ? const Icon(
                      Icons.person_outline,
                      size: 40,
                      color: Colors.blueGrey,
                    )
                  : null,
            ),
            decoration: const BoxDecoration(
              color: Colors.blueGrey,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.indigo),
            title: const Text('Perfil'),
            onTap: () {
              context.go('/home/profile');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.people, color: Colors.indigo),
            title: const Text('Contactos'),
            onTap: () {
              context.go('/home/contacts');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Salir'),
            onTap: () {
              Navigator.pop(context);
              _signOut();
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _notificationCountSubscription?.cancel(); 
    super.dispose();
  }
}