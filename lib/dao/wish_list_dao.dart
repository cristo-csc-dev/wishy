import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wishy/auth/user_auth.dart';
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
    return _db
      .collection('users')
      .doc(userId)
      .collection('wishlists')
      .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getSharedWishlistsStreamSnapshot(String userId) {
    if (!UserAuth.instance.isUserAuthenticatedAndVerified()) {
      throw Exception('Usuario no autenticado.');
    }
    return _db
      .collection('users')
      .doc(userId)
      .collection('wishlists')
      .where(
        Filter.and(
          Filter.or(
            Filter('sharedWithContactIds', arrayContains: UserAuth.instance.getCurrentUser().uid),
            Filter('privacy', isEqualTo: 'public')
          ), 
          Filter('ownerId', isEqualTo: userId)
        )
      ).snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getWishlistsStream(String userId) {
    return _db
      .collection('users')
      .doc(userId)
      .collection('wishlists').get();
  }

  Future<String> createWishlist(Map<String, dynamic> wishlistData) async {
    if (!UserAuth.instance.isUserAuthenticatedAndVerified()) {
      throw Exception('Usuario no autenticado.');
    }
    try {
      DocumentReference newWishList = await _db
        .collection('users')
        .doc(UserAuth.instance.getCurrentUser().uid)
        .collection('wishlists')
        .add(wishlistData);
      return newWishList.id;
    } catch (e) {
      // Devolvemos el error para que el UI pueda manejarlo
      throw Exception('Error al crear la lista de deseos: $e');
    }
  }

  Future<void> addItem(String wishlistId, Map<String, dynamic> itemData) async {
    try {
      if (!UserAuth.instance.isUserAuthenticatedAndVerified()) {
        throw Exception('Usuario no autenticado.');
      }
      await _db.runTransaction((transaction) async {
        final wishlistRef = _db
          .collection('users')
          .doc(UserAuth.instance.getCurrentUser().uid)
          .collection('wishlists').doc(wishlistId);
        CollectionReference itemsRef = wishlistRef.collection('items');

        await itemsRef.add(itemData);
        int itemCount = (await itemsRef.count().get()).count ?? 0;

        transaction.update(wishlistRef, {'itemCount': itemCount});
      });
    } catch (e) {
      // Devolvemos el error para que el UI pueda manejarlo
      throw Exception('Error al agregar el deseo: $e');
    }
  }

  Future<void> updateItem(String wishlistId, String itemId,  Map<String, dynamic> itemData) async {
    if (!UserAuth.instance.isUserAuthenticatedAndVerified()) {
      throw Exception('Usuario no autenticado.');
    }
    try {
      await _db
        .collection('users')
        .doc(UserAuth.instance.getCurrentUser().uid)
        .collection('wishlists')
        .doc(wishlistId)
        .collection('items')
        .doc(itemId)
        .set(itemData, SetOptions(merge: true));
    } catch (e) {
      // Devolvemos el error para que el UI pueda manejarlo
      throw Exception('Error al actualizar el deseo: $e');
    }
  }

  Future<void> removeItem(String wishlistId, String itemId) async {
    if (!UserAuth.instance.isUserAuthenticatedAndVerified()) {
      throw Exception('Usuario no autenticado.');
    }
    try {
      await _db.runTransaction((transaction) async {
        final wishlistRef = _db
          .collection('users')
          .doc(UserAuth.instance.getCurrentUser().uid)
          .collection('wishlists')
          .doc(wishlistId);
        CollectionReference itemsRef = wishlistRef.collection('items');
        await itemsRef.doc(itemId).delete();

        int itemCount = (await itemsRef.count().get()).count ?? 0;
        transaction.update(wishlistRef, {'itemCount': itemCount});
      });
    } catch (e) {
      // Devolvemos el error para que el UI pueda manejarlo
      throw Exception('Error al eliminar el deseo: $e');
    }
  }

  void createOrUpdateWishlist(String id, Map<String, Object> map) async {
    if (!UserAuth.instance.isUserAuthenticatedAndVerified()) {
      throw Exception('Usuario no autenticado.');
    }
    await _db
     .collection('users')
      .doc(UserAuth.instance.getCurrentUser().uid)
      .collection('wishlists')
      .doc(id)
      .set(map, SetOptions(merge: true));
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getContactWishlistById(String wishListId, String? userId) async {
    if (!UserAuth.instance.isUserAuthenticatedAndVerified()) {
      throw Exception('Usuario no autenticado.');
    }
    String userIdToUse = userId ?? UserAuth.instance.getCurrentUser().uid;
    return await _db
      .collection('users')
      .doc(userIdToUse)
      .collection('wishlists')
      .doc(wishListId)
      .get();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getWishlistById(String wishListId) async {
    if (!UserAuth.instance.isUserAuthenticatedAndVerified()) {
      throw Exception('Usuario no autenticado.');
    }
    if (!UserAuth.instance.isUserAuthenticatedAndVerified()) {
      throw Exception('Usuario no autenticado.');
    }
    String userIdToUse = UserAuth.instance.getCurrentUser().uid;
    return await _db
      .collection('users')
      .doc(userIdToUse)
      .collection('wishlists')
      .doc(wishListId)
      .get();
  }

  void deleteWishlist(String id) {
    if (!UserAuth.instance.isUserAuthenticatedAndVerified()) {
      throw Exception('Usuario no autenticado.');
    }
    _db
      .collection('users')
      .doc(UserAuth.instance.getCurrentUser().uid)
      .collection('wishlists')
      .doc(id)
      .delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getListItems(String userId, WishList currentWishList) {
    if (!UserAuth.instance.isUserAuthenticatedAndVerified()) {
      throw Exception('Usuario no autenticado.');
    }
    return _db
      .collection('users')
      .doc(userId)
      .collection('wishlists')
      .doc(currentWishList.id)
      .collection('items')
      .snapshots();
  }

}