import 'package:wishy/models/wish_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum ListPrivacy { 
  
  private, public, shared;

  static ListPrivacy fromString(String value) {
    switch (value.toLowerCase()) {
      case 'private':
        return ListPrivacy.private;
      case 'public':
        return ListPrivacy.public;
      case 'shared':
        return ListPrivacy.shared;
      default:
        throw ArgumentError('Valor de privacidad inválido: $value');
    }
  }

 }

class WishList {
  final String id;
  String? ownerId;
  String name;
  String? description;
  String? iconPath; // Podrías usar un Path o un String de un Emoji/Icono
  ListPrivacy privacy;
  List<String> sharedWithContactIds; // IDs de contactos/grupos con los que se comparte
  List<WishItem> items;
  DateTime? eventDate; // Fecha asociada a la lista (ej. cumpleaños)
  bool allowMarkingAsBought; // Permitir a contactos marcar como comprado
  int itemCount = 0; // Número de ítems en la lista

  WishList({
    required this.id,
    required this.name,
    this.ownerId,
    this.description,
    this.iconPath,
    this.privacy = ListPrivacy.private,
    this.sharedWithContactIds = const [],
    this.items = const [],
    this.eventDate,
    this.allowMarkingAsBought = true,
    this.itemCount = 0,
  });

  factory WishList.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final sharedWith = data['sharedWithContactIds'];
    return WishList(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      ownerId: data['ownerId'] ?? '',
      privacy: ListPrivacy.fromString(data['privacy'] ?? 'private'),
      sharedWithContactIds: sharedWith != null ? List<String>.from(sharedWith) : [],
      itemCount: data['itemCount'] ?? 0,
    );
  }
}
