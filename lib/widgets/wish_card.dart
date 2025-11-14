import 'package:flutter/material.dart';
import 'package:wishy/models/wish_item.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wishy/screens/wish/wish_detail_screen.dart';

class WishCard extends StatelessWidget {
  final WishItem wishItem;
  final bool isForGifting; // Si esta tarjeta es para el regalador
  final VoidCallback? onMarkAsBought; // Solo si isForGifting es true
  final VoidCallback? onEdit; // Solo si no es forGifting
  final VoidCallback? onDelete; // Solo si no es forGifting

  const WishCard({
    super.key,
    required this.wishItem,
    this.isForGifting = false,
    this.onMarkAsBought,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WishDetailScreen(wishItem: wishItem),
            ),
          );
          // No necesitamos setState() aquí, ya que el StreamBuilder se encargará de la actualización
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (wishItem.imageUrl != null && wishItem.imageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        wishItem.imageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 80),
                      ),
                    )
                  else
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.image, size: 40, color: Colors.grey),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          wishItem.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (wishItem.estimatedPrice != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              '${wishItem.estimatedPrice!.toStringAsFixed(2)}€',
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.green),
                            ),
                          ),
                        if (wishItem.suggestedStore != null && wishItem.suggestedStore!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Text(
                              'Tienda: ${wishItem.suggestedStore}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ),
                        if (wishItem.notes != null && wishItem.notes!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Notas: ${wishItem.notes}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (!isForGifting)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') onEdit?.call();
                        if (value == 'delete') onDelete?.call();
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Text('Editar'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Eliminar'),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (wishItem.productUrl != null && wishItem.productUrl!.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (!await launchUrl(Uri.parse(wishItem.productUrl!))) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No se pudo abrir el enlace.')),
                          );
                        }
                      },
                      icon: const Icon(Icons.link, size: 18),
                      label: const Text('Ver Producto'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.blueGrey,
                        backgroundColor: Colors.blueGrey.shade50,
                        elevation: 0,
                      ),
                    ),
                  if (isForGifting)
                    wishItem.isBought
                        ? const Chip(
                            label: Text('Regalo ya reservado', style: TextStyle(color: Colors.white)),
                            backgroundColor: Colors.blueGrey,
                            avatar: Icon(Icons.check, color: Colors.white),
                          )
                        : ElevatedButton.icon(
                            onPressed: onMarkAsBought,
                            icon: const Icon(Icons.check_circle_outline, size: 18),
                            label: const Text('Marcar como Comprado'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}