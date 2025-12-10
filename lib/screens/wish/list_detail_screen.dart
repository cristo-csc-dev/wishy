import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wishy/auth/user_auth.dart';
import 'package:wishy/dao/wish_list_dao.dart';
import 'package:wishy/models/wish_list.dart';
import 'package:wishy/models/wish_item.dart';
import 'package:wishy/screens/wish/add_wish_screen.dart';
import 'package:wishy/widgets/wish_card.dart';

class ListDetailScreen extends StatefulWidget {
  final String userId;
  final String wishListId;

  const ListDetailScreen({
    super.key,
    required this.userId,
    required this.wishListId,
  });

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {

  WishList? _currentWishList;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getWishList(widget.wishListId);
  }

  void _getWishList(String wishListId) async {
    setState(() {
      _isLoading = true;
    });
    WishList wishList = WishList.fromFirestore(await WishlistDao().getContactWishlistById(widget.wishListId, widget.userId));
    setState(() {
      _currentWishList = wishList;
      _isLoading = false;
    });
  }

  void _addWishItem() async {
    final newWish = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddWishScreen(wishListId: _currentWishList!.id),
      ),
    );
    if (newWish != null && newWish is WishItem) {
      setState(() {
        WishlistDao().addItem(_currentWishList!.id!, newWish.toMap());
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deseo "${newWish.name}" añadido.')));
    }
  }

  void _editWishItem(QueryDocumentSnapshot wishItem) async {
    final updatedWish = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddWishScreen(
          wishItemId: wishItem.id,
          wishListId: _currentWishList!.id,
        ),
      ),
    );
    if (updatedWish != null && updatedWish is WishItem) {
      setState(() {
        wishItem.reference.update(updatedWish.toMap());
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deseo "${updatedWish.name}" actualizado.')));
    }
  }

  void _deleteWishItem(QuerySnapshot<Object?> wishItemList, int index) {
    final wishItem = wishItemList.docs[index];
    final WishItem wishItemObj = WishItem.fromFirestore(wishItem);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar Deseo'),
          content: Text('¿Estás seguro de que quieres eliminar "${wishItemObj.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  WishlistDao().removeItem(_currentWishList!.id!, wishItem.id);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Deseo "${wishItemObj.name}" eliminado.')));
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentWishList?.name ?? ''),
        /*actions: [
          if (!widget.isForGifting)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateEditListScreen(wishList: _currentWishList),
                  ),
                ).then((updatedListId) async {
                  var updateWishList = WishList.fromFirestore(
                    await WishlistDao().getWishlistById(updatedListId)
                  );
                  setState(() {
                    _currentWishList = updateWishList;
                  });
                });
              },
            ),
        ],*/
      ),
      body: _isLoading
          ? Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          :
        StreamBuilder<QuerySnapshot>(
          stream: WishlistDao().getListItems(widget.userId, _currentWishList!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('Esta lista no tiene deseos aún.'));
            }

            return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final itemDoc = snapshot.data!.docs[index];
                WishItem item = WishItem.fromFirestore(itemDoc);
                return WishCard(
                  wishItem: item,
                  wishList: _currentWishList!,
                  // isForGifting: widget.isForGifting,
                  onEdit: () => _currentWishList?.ownerId == UserAuth.instance.getCurrentUser().uid? _editWishItem(itemDoc): null,
                  onDelete: () => _currentWishList?.ownerId == UserAuth.instance.getCurrentUser().uid? _deleteWishItem(snapshot.data!, index): null,
                );
              },
            );
          },
        ),
      // floatingActionButton: !widget.isForGifting
      //     ? FloatingActionButton(
      //         onPressed: _addWishItem,
      //         child: const Icon(Icons.add),
      //       )
      //     : null, // No mostrar FAB si es para regalar
    );
  }
}