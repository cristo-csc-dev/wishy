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

enum WishListFields {
  ownerId, name, privacy, sharedWithContactIds, itemCount;
 }

class WishList {

  DocumentSnapshot? document;
  Map<String, dynamic> data;
  String? id;

  WishList({this.document, required this.data});

  factory WishList.fromFirestore(DocumentSnapshot doc) {
    return WishList(document: doc, data: doc.data() as Map<String, dynamic>);
  }

  String? getId() {
    return document?.id;
  }

  setId(String id) {
    this.id = id;
  }

  dynamic get(WishListFields field) {
    return data[field.name];
  }

  void set(WishListFields field, dynamic value) {
    data[field.name] = value;
  }
}