// lib/screens/friend_lists_overview_screen.dart
import 'package:flutter/material.dart';
import 'package:wishy/dao/wish_list_dao.dart';
import 'package:wishy/models/contact.dart';
import 'package:wishy/models/wish_list.dart';
import 'package:wishy/screens/list_detail_screen.dart';
import 'package:wishy/sharing/share_handler_screen.dart';
import 'package:wishy/widgets/list_card.dart'; // Reutilizamos ListCard

class FriendListsOverviewScreen extends StatelessWidget {
  final Contact contact;

  const FriendListsOverviewScreen({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Listas de ${contact.name}'),
      ),
      body: StreamBuilder(
        stream: WishlistDao().getSharedWishlistsStreamSnapshot(contact.id), 
        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final name = contact.name?? contact.email;
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text('¡$name no ha compartido ninguna lista contigo aún!'),
          );
        }

        List<WishList> contactSharedLists = snapshot.data!.docs
            .map((doc) => WishList.fromFirestore(doc))
            .toList();

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final list = contactSharedLists[index];
            return ListCard(
              wishList: list,
              onTap: () {
                // Al tocar, navegamos al detalle de la lista para regalar
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ListDetailScreen(
                      wishList: list,
                      isForGifting: true, // ¡Importante! Indica que es para regalar
                    ),
                  ),
                );
              },
              // Las opciones de editar, compartir y eliminar no son relevantes aquí
              // ya que estas listas son de otra persona.
              onEdit: () {},
              onShare: () {},
              onDelete: () {},
            );
          }
        );
      }),
    );     
  }

  /*
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Listas de ${contact.name}'),
      ),
      body: contact.sharedWishLists.isEmpty
          ? Center(
              child: Text('¡${contact.name} no ha compartido ninguna lista contigo aún!'),
            )
          : ListView.builder(
              itemCount: contact.sharedWishLists.length,
              itemBuilder: (context, index) {
                final list = contact.sharedWishLists[index];
                return ListCard(
                  wishList: list,
                  onTap: () {
                    // Al tocar, navegamos al detalle de la lista para regalar
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ListDetailScreen(
                          wishList: list,
                          isForGifting: true, // ¡Importante! Indica que es para regalar
                        ),
                      ),
                    );
                  },
                  // Las opciones de editar, compartir y eliminar no son relevantes aquí
                  // ya que estas listas son de otra persona.
                  onEdit: () {},
                  onShare: () {},
                  onDelete: () {},
                );
              },
            ),
    );
  }*/
}