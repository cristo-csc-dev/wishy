import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wishy/auth/user_auth.dart';
import 'package:wishy/models/wish_item.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wishy/models/wish_list.dart';
import 'package:wishy/dao/wish_list_dao.dart';

class WishCard extends StatefulWidget {
  final WishItem wishItem;
  final WishList wishList;
  final bool isForGifting; // Si esta tarjeta es para el regalador
  final VoidCallback? onMarkAsBought; // Solo si isForGifting es true
  final VoidCallback? onEdit; // Solo si no es forGifting
  final VoidCallback? onDelete; // Solo si no es forGifting

  const WishCard({
    super.key,
    required this.wishItem,
    required this.wishList,
    this.isForGifting = false,
    this.onMarkAsBought,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<WishCard> createState() => _WishCardState();
}

class _WishCardState extends State<WishCard> {
  late int _currentPriority;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _currentPriority = widget.wishItem.priority;
  }

  bool get _isOwner => widget.wishList.ownerId == UserAuth.instance.getCurrentUser().uid;

  Future<void> _setPriority(int newPriority) async {
    if (!_isOwner) return;
    final oldPriority = _currentPriority;
    setState(() {
      _currentPriority = newPriority;
      _isUpdating = true;
    });

    final wishlistId = widget.wishList.id ?? '';
    if (wishlistId.isEmpty) {
      setState(() {
        _currentPriority = oldPriority;
        _isUpdating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lista inválida')));
      return;
    }

    try {
      await WishlistDao().updateItem(wishlistId, widget.wishItem.id, {'priority': newPriority});
    } catch (e) {
      setState(() {
        _currentPriority = oldPriority;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al actualizar prioridad: $e')));
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Widget _buildPriorityStars() {
    // Mostrar fila de 5 estrellas; si no es owner, deshabilitadas
    final Color starColor = Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).colorScheme.primary;
    return Row(
      children: List.generate(5, (index) {
        final starIndex = index + 1;
        final filled = starIndex <= _currentPriority;
        return IconButton(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          onPressed: _isOwner && !_isUpdating ? () => _setPriority(starIndex) : null,
          icon: Icon(
            filled ? Icons.star : Icons.star_border,
            color: starColor,
            size: 18,
          ),
          tooltip: _isOwner ? 'Cambiar prioridad' : null,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wishItem = widget.wishItem;
    final wishList = widget.wishList;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () async {
          context.go('/home/contacts/${wishList.ownerId}/lists/${wishList.id}/wishes/${wishItem.id}/detail');
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
                        // Prioridad (estrellas) antes del precio
                        _buildPriorityStars(),
                        const SizedBox(height: 4),
                        if (wishItem.estimatedPrice != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
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
                  if (wishList.ownerId == UserAuth.instance.getCurrentUser().uid)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') widget.onEdit?.call();
                        if (value == 'delete') widget.onDelete?.call();
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
                ],
              ),

            ],
          ),
        ),
      ),
    );
  }
}