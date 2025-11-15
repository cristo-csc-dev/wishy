import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wishy/models/wish_item.dart';
import 'package:wishy/models/wish_list.dart'; // Asegúrate de que este import sea correcto
import 'package:intl/intl.dart';
import 'package:wishy/screens/wish/add_wish_screen.dart'; // Necesario para formatear la moneda

class WishDetailScreen extends StatefulWidget {
  final WishItem wishItem;
  final WishList wishList;

  const WishDetailScreen({
    super.key,
    required this.wishItem,
    required this.wishList,
  });
  
  @override
  State<WishDetailScreen> createState() => _WishDetailScreenState();
}

class _WishDetailScreenState extends State<WishDetailScreen> {

  // Reutilizamos la lógica de prioridad de tu AddWishScreen para la etiqueta
  String _getPriorityLabel(int priority) {
    switch (priority) {
      case 1:
        return 'Baja';
      case 2:
        return 'Normal';
      case 3:
        return 'Media';
      case 4:
        return 'Alta';
      case 5:
        return 'Imprescindible';
      default:
        return 'Media';
    }
  }

  // Helper para mostrar un ítem de detalle
  Widget _buildDetailItem(String title, String? value, {bool isUrl = false}) {
    if (value == null || value.isEmpty) {
      return const SizedBox.shrink(); // No muestra nada si el valor es nulo o vacío
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () async {
              if (!isUrl) return;
                final uri = Uri.parse(value);
                  await launchUrl(uri);
              },
            child: 
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: isUrl ? Colors.blue.shade700 : Colors.black87,
                  decoration: isUrl ? TextDecoration.underline : TextDecoration.none,
                ),
              ),
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }

  // Helper para formatear el precio
  String _formatPrice(double? price) {
    if (price == null) return 'N/A';
    // Se asume la configuración regional española para el símbolo del Euro
    final formatter = NumberFormat.currency(locale: 'es_ES', symbol: '€');
    return formatter.format(price);
  }

  // Helper para generar el widget de prioridad
  Widget _buildPriorityTag(int priority) {
    final label = _getPriorityLabel(priority);
    Color color;

    switch (priority) {
      case 5:
        color = Colors.red.shade700;
        break;
      case 4:
        color = Colors.orange.shade700;
        break;
      case 3:
        color = Colors.indigo.shade500;
        break;
      default:
        color = Colors.green.shade500;
        break;
    }

    return Chip(
      label: Text(
        'Prioridad: $label',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      backgroundColor: color,
      avatar: const Icon(Icons.star, color: Colors.white, size: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  @override
  Widget build(BuildContext context) {
    var currentWishList = widget.wishList;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Deseo'),
        actions: [
          IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // Navegar a la pantalla de edición de la lista
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddWishScreen(wishList: widget.wishList, wishItem: widget.wishItem),
                  ),
                ).then((updatedList) {
                  if (updatedList != null && updatedList is WishList) {
                    setState(() {
                      currentWishList = updatedList;
                    });
                  }
                });
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título Principal
              Text(
                widget.wishItem.name,
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 10),

              // Etiqueta de Prioridad
              _buildPriorityTag(widget.wishItem.priority),
              const SizedBox(height: 20),

              // Información del Precio
              _buildDetailItem(
                'Precio Estimado',
                _formatPrice(widget.wishItem.estimatedPrice),
              ),

              // Información de la Tienda
              _buildDetailItem(
                'Tienda Sugerida',
                widget.wishItem.suggestedStore,
              ),

              // URL del Producto
              _buildDetailItem(
                'Enlace del Producto',
                widget.wishItem.productUrl,
                isUrl: true,
              ),

              // Lista a la que pertenece
              _buildDetailItem(
                'Perteneciente a la Lista',
               widget.wishList.name,
              ),

              // Notas / Detalles
              if (widget.wishItem.notes != null && widget.wishItem.notes!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  "Notas / Detalles",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    widget.wishItem.notes!,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              
              // Aquí podrías añadir un botón para volver a editar si lo deseas
              
            ],
          ),
        ),
      ),
    );
  }
}