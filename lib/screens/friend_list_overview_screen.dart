// lib/screens/friend_lists_overview_screen.dart
import 'package:flutter/material.dart';
import 'package:wishy/models/contact.dart';
import 'package:wishy/screens/list_detail_screen.dart';
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
  }
}