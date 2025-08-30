// lib/models/contact.dart
import 'package:wishy/models/wish_list.dart'; // Asegúrate de importar WishList

class Contact {
  final String id;
  final String name;
  final String? avatarUrl;
  final DateTime? nextEventDate; // Para simular fechas de eventos

  // ¡NUEVO! Para la demo, simula las listas que este contacto ha compartido
  // En una app real, esto se obtendría de un servicio de backend
  final List<WishList> sharedWishLists;

  Contact({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.nextEventDate,
    this.sharedWishLists = const [], // Inicialmente vacía
  });
}