// lib/models/event.dart
enum EventType {
  birthday,
  christmas,
  secretSanta,
  wedding,
  babyShower,
  other,
}

class Event {
  final String id;
  String name;
  String description;
  String organizerUserId; // ID del usuario que crea el evento
  DateTime eventDate;
  EventType type;
  List<String> invitedUserIds; // IDs de los usuarios invitados
  List<String> participantUserIds; // IDs de los usuarios que han aceptado/se han unido
  Map<String, List<String>> userListsInEvent; // userId -> lista de wishListIds asociados al evento por ese usuario
  Map<String, List<String>> userLooseWishesInEvent; // userId -> lista de wishItemIds sueltos en el evento

  Event({
    required this.id,
    required this.name,
    this.description = '',
    required this.organizerUserId,
    required this.eventDate,
    this.type = EventType.other,
    this.invitedUserIds = const [],
    this.participantUserIds = const [],
    this.userListsInEvent = const {},
    this.userLooseWishesInEvent = const {},
  });
}