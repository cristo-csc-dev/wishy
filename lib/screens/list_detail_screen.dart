import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wishy/models/wish_list.dart';
import 'package:wishy/models/wish_item.dart';
import 'package:wishy/screens/add_wish_screen.dart';
import 'package:wishy/screens/create_edit_list_screen.dart';
import 'package:wishy/widgets/wish_card.dart';

class ListDetailScreen extends StatefulWidget {
  final WishList wishList;
  final bool isForGifting; // True si es una lista de otro para regalar

  const ListDetailScreen({
    super.key,
    required this.wishList,
    this.isForGifting = false,
  });

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
        builder: (context) => const AddWishScreen(),
      ),
    );
    if (newWish != null && newWish is WishItem) {
      setState(() {
        _db.collection('wishlists').doc(_currentWishList.id).collection('items').add(newWish.toMap());
        //_currentWishList.items.add(newWish);
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deseo "${newWish.name}" añadido.')));
    }
  }

  void _editWishItem(WishItem wishItem) async {
    final updatedWish = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddWishScreen(wishItem: wishItem),
      ),
    );
    if (updatedWish != null && updatedWish is WishItem) {
      setState(() {
        final index = _currentWishList.items.indexOf(wishItem);
        if (index != -1) {
          _currentWishList.items[index] = updatedWish;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deseo "${updatedWish.name}" actualizado.')));
    }
  }

  void _deleteWishItem(WishItem wishItem) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar Deseo'),
          content: Text('¿Estás seguro de que quieres eliminar "${wishItem.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _currentWishList.items.remove(wishItem);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Deseo "${wishItem.name}" eliminado.')));
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _markWishAsBought(WishItem wishItem) {
    if (!_currentWishList.allowMarkingAsBought && widget.isForGifting) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El creador de esta lista no permite marcar deseos.')),
      );
      return;
    }

    setState(() {
      wishItem.isBought = true;
      // Aquí, en una app real, también se enviaría esta actualización a la base de datos
      // y se asociaría con el ID del usuario que lo compró.
    });
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('¡Has marcado "${wishItem.name}" como comprado!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentWishList.name),
        actions: [
          if (!widget.isForGifting) // Solo si es una lista propia
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                // Lógica para compartir esta lista específica
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Compartir lista "${_currentWishList.name}"')));
              },
            ),
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
                ).then((updatedList) {
                  if (updatedList != null && updatedList is WishList) {
                    setState(() {
                      _currentWishList = updatedList;
                    });
                  }
                });
              },
            ),
        ],
      ),
      body: _currentWishList.items.isEmpty
          ? Center(
              child: Text(widget.isForGifting
                  ? 'Esta lista de deseos está vacía.'
                  : 'Esta lista está vacía. ¡Añade algunos deseos!'),
            )
          : ListView.builder(
              itemCount: _currentWishList.items.length,
              itemBuilder: (context, index) {
                final item = _currentWishList.items[index];
                return WishCard(
                  wishItem: item,
                  isForGifting: widget.isForGifting,
                  onMarkAsBought: widget.isForGifting && _currentWishList.allowMarkingAsBought
                      ? () => _markWishAsBought(item)
                      : null,
                  onEdit: !widget.isForGifting ? () => _editWishItem(item) : null,
                  onDelete: !widget.isForGifting ? () => _deleteWishItem(item) : null,
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