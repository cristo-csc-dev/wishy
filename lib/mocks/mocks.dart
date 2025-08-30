// --- Simulación de datos (actualizada para Contactos) ---
import 'package:wishy/models/contact.dart';
import 'package:wishy/models/event.dart';
import 'package:wishy/models/wish_item.dart';
import 'package:wishy/models/wish_list.dart';

List<WishList> userWishLists = [
  WishList(
    id: '1',
    name: 'Mi Cumpleaños',
    privacy: ListPrivacy.shared,
    sharedWithContactIds: ['contact1', 'contact2'],
    eventDate: DateTime(2025, 7, 15),
    items: [
      WishItem(id: 'a', name: 'Libro El Principito', estimatedPrice: 15.00),
      WishItem(id: 'b', name: 'Auriculares Bluetooth', estimatedPrice: 80.00),
    ],
  ),
  WishList(
    id: '2',
    name: 'Navidad 2025',
    privacy: ListPrivacy.private,
    items: [
      WishItem(id: 'c', name: 'Consola de Videojuegos', estimatedPrice: 450.00),
    ],
  ),
  WishList(
    id: '3',
    name: 'Viaje a Japón',
    privacy: ListPrivacy.public,
    items: [
      WishItem(id: 'd', name: 'Maleta grande', estimatedPrice: 120.00),
      WishItem(id: 'e', name: 'Guía de Tokio', estimatedPrice: 25.00),
    ],
  ),
];

// Simulamos los contactos que han compartido listas con el usuario actual
List<Contact> contactsWithSharedLists = [
  Contact(
    id: 'c1',
    name: 'Ana García',
    nextEventDate: DateTime(2025, 8, 20),
    sharedWishLists: [
      WishList(
        id: 'ana1',
        name: 'Cumpleaños de Ana',
        privacy: ListPrivacy.shared,
        eventDate: DateTime(2025, 8, 20),
        items: [
          WishItem(id: 'ana_a', name: 'Cámara Instantánea', estimatedPrice: 90.00, isBought: true),
          WishItem(id: 'ana_b', name: 'Set de Pinturas', estimatedPrice: 40.00, isBought: false),
        ],
      ),
      WishList(
        id: 'ana2',
        name: 'Deseos para mi Estudio',
        privacy: ListPrivacy.shared,
        items: [
          WishItem(id: 'ana_c', name: 'Silla ergonómica', estimatedPrice: 250.00, isBought: false),
        ],
      ),
    ],
  ),
  Contact(
    id: 'c2',
    name: 'Javier Ramos',
    nextEventDate: DateTime(2025, 10, 5),
    sharedWishLists: [
      WishList(
        id: 'javier1',
        name: 'Deseos de Navidad',
        privacy: ListPrivacy.shared,
        items: [
          WishItem(id: 'jav_a', name: 'Drone con cámara', estimatedPrice: 300.00, isBought: false),
        ],
      ),
    ],
  ),
];
// --- Fin Simulación de datos ---

// --- Simulación de datos de eventos ---
List<Event> userEvents = [
  Event(
    id: 'e1',
    name: 'Amigo Invisible Navidad 2025',
    description: 'Regalos para el sorteo de la oficina.',
    organizerUserId: 'current_user_id', // Suponiendo un ID de usuario actual
    eventDate: DateTime(2025, 12, 24),
    type: EventType.secretSanta,
    invitedUserIds: ['c1', 'c2'], // Ana y Javier
    participantUserIds: ['current_user_id', 'c1'],
    userListsInEvent: {
      'current_user_id': ['1'], // Mi lista "Mi Cumpleaños"
      'c1': ['ana1'], // La lista "Cumpleaños de Ana"
    },
    userLooseWishesInEvent: {
      'c1': [WishItem(id: 'lw1', name: 'Calcetines de lana', estimatedPrice: 10.00).id],
    }
  ),
  Event(
    id: 'e2',
    name: 'Cumpleaños de María',
    organizerUserId: 'c1',
    eventDate: DateTime(2025, 8, 20),
    type: EventType.birthday,
    invitedUserIds: ['current_user_id'],
    participantUserIds: ['current_user_id'],
    userListsInEvent: {'current_user_id': []},
  )
];
// --- Fin Simulación de datos de eventos ---