import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wishy/models/wish_list.dart';

class WishlistDao {
  // Patrón Singleton
  static final WishlistDao _instance = WishlistDao._internal();

  factory WishlistDao() {
    return _instance;
  }

  WishlistDao._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> getWishlistsStreamSnapshot(String userId) {
    return _db.collection('wishlists').where('ownerId', isEqualTo: userId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getSharedWishlistsStreamSnapshot(String userId) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Usuario no autenticado.');
    }
    //return _db.collection('wishlists').where('ownerId', isEqualTo: userId).where('sharedWithContactIds', arrayContains: currentUser.uid).snapshots();
    return _db.collection('wishlists').where(
      Filter.and(
        Filter.or(
          Filter('sharedWithContactIds', arrayContains: currentUser.uid),
          Filter('privacy', isEqualTo: 'public')
        ), 
        Filter('ownerId', isEqualTo: userId)
      )
    ).snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getWishlistsStream(String userId) {
    return _db.collection('wishlists').where('ownerId', isEqualTo: userId).get();
  }

  Future<String> createWishlist(Map<String, dynamic> wishlistData) async {
    try {
      DocumentReference newWishList = await _db.collection('wishlists').add(wishlistData);
      return newWishList.id;
    } catch (e) {
      // Devolvemos el error para que el UI pueda manejarlo
      throw Exception('Error al crear la lista de deseos: $e');
    }
  }

  Future<void> addItem(String wishlistId, Map<String, dynamic> itemData) async {
    try {
      await _db.runTransaction((transaction) async {
        final wishlistRef = _db.collection('wishlists').doc(wishlistId);
        CollectionReference itemsRef = wishlistRef.collection('items');

        DocumentReference itemsRefUpdated = await itemsRef.add(itemData);

        AggregateQuerySnapshot numItemsSnapshot = await _db.collection('wishlists').doc(wishlistId).collection('items').count().get();
        transaction.update(wishlistRef, {'itemCount': (numItemsSnapshot.count??0 + 1)});
      });
    } catch (e) {
      // Devolvemos el error para que el UI pueda manejarlo
      throw Exception('Error al agregar el deseo: $e');
    }
  }

  Future<void> updateItem(String wishlistId, String itemId,  Map<String, dynamic> itemData) async {
    try {
      await _db.collection('wishlists').doc(wishlistId).collection('items').doc(itemId).set(itemData, SetOptions(merge: true));
    } catch (e) {
      // Devolvemos el error para que el UI pueda manejarlo
      throw Exception('Error al actualizar el deseo: $e');
    }
  }

  Future<void> removeItem(String wishlistId, String itemId) async {
    try {
      await _db.runTransaction((transaction) async {
        final wishlistRef = _db.collection('wishlists').doc(wishlistId);
        CollectionReference itemsRef = wishlistRef.collection('items');
        await itemsRef.doc(itemId).delete();

        AggregateQuerySnapshot numItemsSnapshot = await _db.collection('wishlists').doc(wishlistId).collection('items').count().get();
        transaction.update(wishlistRef, {'itemCount': (numItemsSnapshot.count??0 - 1)});
      });
    } catch (e) {
      // Devolvemos el error para que el UI pueda manejarlo
      throw Exception('Error al eliminar el deseo: $e');
    }
  }

  void createOrUpdateWishlist(String id, Map<String, Object> map) {
     _db.collection('wishlists').doc(id).set(map, SetOptions(merge: true));
  }

  void deleteWishlist(String id) {
     _db.collection('wishlists').doc(id).delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getListItems(WishList currentWishList) {
    return FirebaseFirestore.instance
          .collection('wishlists')
          .doc(currentWishList.getId())
          .collection('items')
          .snapshots();
  }

}