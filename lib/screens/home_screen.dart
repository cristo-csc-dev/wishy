import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:wishy/auth/user_auth.dart';
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
import 'package:wishy/static/available_wishlist_icons.dart';
import 'package:wishy/widgets/contact_avatar.dart';
import 'package:wishy/widgets/wish_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  String _sharedLink = "{}";
  static const platform = MethodChannel('com.wishysa.wishy/channel');
  StreamSubscription? _notificationCountSubscription;
  StreamSubscription<User?>? _userChangesSubscription;


  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _pendingRequestsCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchNotificationsCount();
    platform.setMethodCallHandler(_handleMethodCalls);
    _userChangesSubscription = _auth.userChanges().listen((user) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishy'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: _getDrawerHeader(UserAuth().isUserAuthenticated() ? UserAuth().getCurrentUser() : null).currentAccountPicture!,
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('all_wishes_global')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No hay deseos globales.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final wishItem = WishItem.fromFirestore(doc);
              final data = doc.data() as Map<String, dynamic>;
              
              final wishList = WishList(
                ownerId: data['ownerId'] ?? '',
                name: 'Global',
                privacy: ListPrivacy.public,
                itemCount: 0,
              )..id = data['originalWishlistId'];
              return WishCard(
                wishItem: wishItem,
                // wishList: wishList,
              );
            },
          );
        },
      ),
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
          builder: (context) => AddWishScreen(wishItem: wishDataItem),
        ),
      );
    }
  }

  Widget _buildAppDrawer() {

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          _getDrawerHeader(UserAuth().isUserAuthenticated() ? UserAuth().getCurrentUser() : null),
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.indigo),
            title: const Text('Perfil'),
            onTap: () {
              context.go('/home/profile');
            },
          ),
          ListTile(
            leading: const Icon(Icons.list, color: Colors.indigo),
            title: const Text('Mis listas'),
            onTap: () {
              context.go('/home/wishlists/mine');
            },
          ),
          ListTile(
            leading: const Icon(Icons.card_giftcard, color: Colors.indigo),
            title: const Text('Los tengo!'),
            onTap: () {
              // Navegar a la pantalla de 'Los tengo'
              context.go('/home/ihaveit');
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

  _getDrawerHeader(User? user) {
    return UserAccountsDrawerHeader(
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
    );
  }

  @override
  void dispose() {
    _notificationCountSubscription?.cancel(); 
    _userChangesSubscription?.cancel();
    super.dispose();
  }
}