import 'package:cloud_firestore/cloud_firestore.dart';

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
        final itemsRef = wishlistRef.collection('items');

        itemsRef.add(itemData);

        final wishlistDoc = await transaction.get(wishlistRef);
        final currentCount = wishlistDoc.data()?['itemCount'] ?? 0;
        transaction.update(wishlistRef, {'itemCount': currentCount + 1});
      });
    } catch (e) {
      // Devolvemos el error para que el UI pueda manejarlo
      throw Exception('Error al agregar el deseo: $e');
    }
  }

  Future<void> removeItem(String wishlistId, String itemId) async {
    try {
      await _db.runTransaction((transaction) async {
        final wishlistRef = _db.collection('wishlists').doc(wishlistId);
        final itemRef = wishlistRef.collection('items').doc(itemId);

        transaction.delete(itemRef);

        final wishlistDoc = await transaction.get(wishlistRef);
        final currentCount = wishlistDoc.data()?['itemCount'] ?? 0;
        transaction.update(wishlistRef, {'itemCount': currentCount - 1});
      });
    } catch (e) {
      // Devolvemos el error para que el UI pueda manejarlo
      throw Exception('Error al eliminar el deseo: $e');
    }
  }

  void createOrUpdateWishlist(String id, Map<String, Object> map) {
     _db.collection('wishlists').doc(id).set(map, SetOptions(merge: true));
  }

}