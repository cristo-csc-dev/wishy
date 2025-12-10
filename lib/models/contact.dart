import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wishy/models/wish_list.dart'; 

class Contact {
  final String id;
  final String? name;
  final String email;
  final String? avatarUrl;
  final DateTime? nextEventDate; 
  final List<WishList> sharedWishLists;

  Contact({
    required this.id,
    this.name,
    required this.email,
    this.avatarUrl,
    this.nextEventDate,
    this.sharedWishLists = const [],
  });

  factory Contact.fromFirestore(DocumentSnapshot doc) {
    return Contact(id: doc.id, name: doc['name'], email: doc['email']);
  }
}