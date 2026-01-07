import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wishy/auth/user_auth.dart';
import 'package:wishy/dao/wish_list_dao.dart';
import 'package:wishy/models/wish_list.dart';
import 'package:wishy/widgets/list_card.dart';

class MyListsOverviewScreen extends StatefulWidget {
  const MyListsOverviewScreen({super.key});

  @override
  State<MyListsOverviewScreen> createState() => _MyListsOverviewScreenState();
}

class _MyListsOverviewScreenState extends State<MyListsOverviewScreen> {
  @override
  Widget build(BuildContext context) {
    final user = UserAuth.instance.getCurrentUser();
    // ignore: unnecessary_null_comparison
    if (user == null || !user.emailVerified) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mis Listas')),
        body: const Center(child: Text('Inicia sesión para ver tus listas.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Listas')),
      body: StreamBuilder<QuerySnapshot>(
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
                  // Navegar a la ruta de mis listas (ruta nueva)
                  context.go('/home/wishlists/mine/${list.id}');
                },
                onEdit: () async {
                  context.go('/home/wishlists/mine/${list.id}/edit');
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newListName = await context.push('/home/wishlists/mine/add');
          if (context.mounted && newListName != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lista "$newListName" creada.')));
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

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
}
