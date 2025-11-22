import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wishy/dao/wish_list_dao.dart';
import 'package:wishy/models/contact.dart';
import 'package:wishy/models/wish_list.dart';
import 'package:wishy/screens/wish/list_detail_screen.dart';
import 'package:wishy/widgets/list_card.dart';

class FriendListsOverviewScreen extends StatelessWidget {
  final Contact contact;

  const FriendListsOverviewScreen({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    final displayName = contact.name ?? contact.email ?? 'Contacto';
    
    return Scaffold(
      appBar: AppBar(

        title: Text('Listas de $displayName'),
      ),
      body: Column(
        children: [
          // Avatar fijo arriba
          Container(
            width: double.infinity,
            // color: Theme.of(context).colorScheme.surfaceVariant,
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  radius: 40,
                  child: Text(
                    contact.name?? '',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                ),
                // const SizedBox(height: 12),
                // Text(
                //   displayName,
                //   style: Theme.of(context).textTheme.titleMedium,
                // ),
                // const SizedBox(height: 4),
                // if (contact.email != null)
                //   Text(
                //     contact.email!,
                //     style: Theme.of(context).textTheme.bodySmall,
                //   ),
              ],
            ),
          ),

          // Listas scrollables debajo
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: WishlistDao().getSharedWishlistsStreamSnapshot(contact.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('¡$displayName no ha compartido ninguna lista contigo aún!'),
                    ),
                  );
                }

                final contactSharedLists = docs.map((doc) => WishList.fromFirestore(doc)).toList();

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: contactSharedLists.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final list = contactSharedLists[index];
                    return ListCard(
                      wishList: list,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ListDetailScreen(
                              userId: contact.id,
                              wishList: list,
                              isForGifting: true,
                            ),
                          ),
                        );
                      },
                      onEdit: () {},
                      onShare: () {},
                      onDelete: () {},
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}