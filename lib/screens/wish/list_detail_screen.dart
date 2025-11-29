import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wishy/dao/wish_list_dao.dart';
import 'package:wishy/models/wish_list.dart';
import 'package:wishy/models/wish_item.dart';
import 'package:wishy/screens/wish/add_wish_screen.dart';
import 'package:wishy/screens/wish/create_edit_list_screen.dart';
import 'package:wishy/widgets/wish_card.dart';

class ListDetailScreen extends StatefulWidget {
  final String userId;
  final WishList wishList;
  final bool isForGifting; // True si es una lista de otro para regalar

  const ListDetailScreen({
    super.key,
    required this.userId,
    required this.wishList,
    this.isForGifting = false,
  });

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {

  late WishList _currentWishList; // Para poder modificarla

  @override
  void initState() {
    super.initState();
    _currentWishList = widget.wishList;
  }

  void _addWishItem() async {
    final newWish = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddWishScreen(wishList: _currentWishList,),
      ),
    );
    if (newWish != null && newWish is WishItem) {
      setState(() {
        WishlistDao().addItem(_currentWishList.id!, newWish.toMap());
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
          wishItem: WishItem.fromFirestore(wishItem),
          wishList: widget.wishList,
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
                  WishlistDao().removeItem(_currentWishList.id!, wishItem.id);
                  // wishItemList.docs[index].reference.delete();
                  // _currentWishList.set(WishListFields.itemCount,wishItemList.docs.length);
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
        title: Text(_currentWishList.name),
        actions: [
          if (!widget.isForGifting) // Solo si es una lista propia
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // Navegar a la pantalla de edición de la lista
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
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: WishlistDao().getListItems(widget.userId, _currentWishList),
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

          // Si hay datos, construye la lista de ítems
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final itemDoc = snapshot.data!.docs[index];
              WishItem item = WishItem.fromFirestore(itemDoc);
              return WishCard(
                  wishItem: item,
                  wishList: _currentWishList,
                  isForGifting: widget.isForGifting,
                  onEdit: !widget.isForGifting ? () => _editWishItem(itemDoc) : null,
                  onDelete: !widget.isForGifting ? () => _deleteWishItem(snapshot.data!, index) : null,
                );
            },
          );
        },
      ),
      floatingActionButton: !widget.isForGifting
          ? FloatingActionButton(
              onPressed: _addWishItem,
              child: const Icon(Icons.add),
            )
          : null, // No mostrar FAB si es para regalar
    );
  }
}