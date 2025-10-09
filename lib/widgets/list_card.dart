import 'package:flutter/material.dart';
import 'package:wishy/models/wish_list.dart';

class ListCard extends StatelessWidget {
  final WishList wishList;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ListCard({
    super.key,
    required this.wishList,
    required this.onTap,
    required this.onShare,
    required this.onEdit,
    required this.onDelete,
  });

  String _getPrivacyStatus() {
    switch (wishList.get(WishListFields.privacy)) {
      case ListPrivacy.private:
        return 'Privada';
      case ListPrivacy.public:
        return 'Pública (Enlace)';
      case ListPrivacy.shared:
        return 'Compartida con ${wishList.get(WishListFields.sharedWithContactIds).length} pers.';
      default:
        return 'Desconocido';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.card_giftcard, color: Colors.blueGrey.shade700), // Usar un icono de la lista
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      wishList.get(WishListFields.name),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'share') onShare();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Text('Editar'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'share',
                        child: Text('Compartir'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Eliminar'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${wishList.get(WishListFields.itemCount)} deseos',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                'Estado: ${_getPrivacyStatus()}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              // if (wishList.items.isNotEmpty) ...[
              //   const SizedBox(height: 12),
              //   Row(
              //     children: wishList.items
              //         .take(3)
              //         .map((item) => Padding(
              //               padding: const EdgeInsets.only(right: 8.0),
              //               child: CircleAvatar(
              //                 radius: 20,
              //                 backgroundImage: item.imageUrl != null && item.imageUrl!.isNotEmpty
              //                     ? NetworkImage(item.imageUrl!)
              //                     : null,
              //                 child: item.imageUrl == null || item.imageUrl!.isEmpty
              //                     ? const Icon(Icons.shopping_bag_outlined, size: 20)
              //                     : null,
              //               ),
              //             ))
              //         .toList(),
              //   ),
              // ],
            ],
          ),
        ),
      ),
    );
  }
}