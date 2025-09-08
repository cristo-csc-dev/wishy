// lib/models/contact.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wishy/models/wish_list.dart'; // Asegúrate de importar WishList

class Contact {
  final String id;
  final String? name;
  final String email;
  final String? avatarUrl;
  final DateTime? nextEventDate; // Para simular fechas de eventos

  // ¡NUEVO! Para la demo, simula las listas que este contacto ha compartido
  // En una app real, esto se obtendría de un servicio de backend
  final List<WishList> sharedWishLists;

  Contact({
    required this.id,
    this.name,
    required this.email,
    this.avatarUrl,
    this.nextEventDate,
    this.sharedWishLists = const [], // Inicialmente vacía
  });

  factory Contact.fromFirestore(DocumentSnapshot doc) {
    return Contact(id: doc.id, name: doc['name'] ?? 'Anónimo', email: doc['email']);
  }
}