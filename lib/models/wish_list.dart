import 'package:wishy/models/wish_item.dart';

enum ListPrivacy { private, public, shared }

class WishList {
  final String id;
  String name;
  String? description;
  String? iconPath; // Podrías usar un Path o un String de un Emoji/Icono
  ListPrivacy privacy;
  List<String> sharedWithContactIds; // IDs de contactos/grupos con los que se comparte
  List<WishItem> items;
  DateTime? eventDate; // Fecha asociada a la lista (ej. cumpleaños)
  bool allowMarkingAsBought; // Permitir a contactos marcar como comprado

  WishList({
    required this.id,
    required this.name,
    this.description,
    this.iconPath,
    this.privacy = ListPrivacy.private,
    this.sharedWithContactIds = const [],
    this.items = const [],
    this.eventDate,
    this.allowMarkingAsBought = true,
  });
}