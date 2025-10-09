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

enum WishListFields {
  ownerId, name, privacy, sharedWithContactIds, itemCount;
 }

class WishList {

  DocumentSnapshot? document;
  Map<String, dynamic> data;

  WishList({this.document, required this.data});

  factory WishList.fromFirestore(DocumentSnapshot doc) {
    return WishList(document: doc, data: doc.data() as Map<String, dynamic>);
  }

  String? getId() {
    return document?.id;
  }

  dynamic get(WishListFields field) {
    return data[field.name];
  }

  void set(WishListFields field, dynamic value) {
    data[field.name] = value;
  }

  // List<WishItem> get items {
  //   if (data[WishListFields.items.name] != null) {
  //     return (data[WishListFields.items.name] as List)
  //         .map((item) => WishItem.fromMap(item as Map<String, dynamic>))
  //         .toList();
  //   }
  //   data[WishListFields.items.name] = [];
  //   return data[WishListFields.items.name] as List<WishItem>;
  // }
}