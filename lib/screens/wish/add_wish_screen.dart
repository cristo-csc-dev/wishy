import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wishy/dao/wish_list_dao.dart';
import 'package:wishy/models/wish_item.dart';
import 'package:uuid/uuid.dart';
import 'package:wishy/models/wish_list.dart';

class AddWishScreen extends StatefulWidget {
  final WishItem? wishItem;
  final WishList? wishList;

  const AddWishScreen({
    super.key,
    this.wishItem,
    this.wishList,
  });

  @override
  State<AddWishScreen> createState() => _AddWishScreenState();
}

class _AddWishScreenState extends State<AddWishScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _priceController;
  late TextEditingController _storeController;
  late TextEditingController _notesController;
  late TextEditingController _newListController;
  int _selectedPriority = 3; // Default medium priority
  final Set<String> _selectedWishlistIds = {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.wishItem?.name ?? '');
    _urlController =
        TextEditingController(text: widget.wishItem?.productUrl ?? '');
    _priceController = TextEditingController(
        text: widget.wishItem?.estimatedPrice?.toString() ?? '');
    _storeController =
        TextEditingController(text: widget.wishItem?.suggestedStore ?? '');
    _notesController = TextEditingController(text: widget.wishItem?.notes ?? '');
    _newListController = TextEditingController();
    _selectedPriority = widget.wishItem?.priority ?? 3;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _priceController.dispose();
    _storeController.dispose();
    _notesController.dispose();
    _newListController.dispose();
    super.dispose();
  }

  void _toggleWishlistSelection(String wishlistId) {
    setState(() {
      if (_selectedWishlistIds.contains(wishlistId)) {
        _selectedWishlistIds.remove(wishlistId);
      } else {
        _selectedWishlistIds.add(wishlistId);
      }
    });
  }

  Future<void> _saveWish() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final newListName = _newListController.text.trim();
    // If we are not editing and not adding to a specific list, we must select at least one list or create a new one.
    if (widget.wishItem == null &&
        widget.wishList == null &&
        _selectedWishlistIds.isEmpty &&
        newListName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Por favor, selecciona al menos una lista o crea una nueva.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !user.emailVerified) return;

    final wishItem = WishItem(
      id: widget.wishItem?.id ?? const Uuid().v4(),
      name: _nameController.text,
      productUrl: _urlController.text,
      estimatedPrice: double.tryParse(_priceController.text),
      suggestedStore: _storeController.text,
      notes: _notesController.text,
      priority: _selectedPriority,
    );

    try {
      final wishlistDao = WishlistDao();
      String? newWishlistId;

      // Create a new list if a name was provided
      if (newListName.isNotEmpty) {
        final newList = WishList(
          name: newListName,
          privacy: ListPrivacy.private,
          ownerId: user.uid,
          itemCount: 0,
        );
        newList.id = await wishlistDao.createWishlist(newList.data);
        newWishlistId = newList.id;
      }

      // If we are editing an existing wish
      if (widget.wishItem != null && widget.wishList != null && widget.wishList!.id != null) {
        await wishlistDao.updateItem(
            widget.wishList!.id!, wishItem.id, wishItem.toMap());
      } else {
        // Adding a new wish to one or more lists
        final allFutures = <Future>[];
        final allListIds = {..._selectedWishlistIds};
        if (newWishlistId != null) {
          allListIds.add(newWishlistId);
        }
        if(widget.wishList != null && widget.wishList!.id != null) {
          allListIds.add(widget.wishList!.id!);
        }
        for (final listId in allListIds) {
          allFutures.add(wishlistDao.addItem(listId, wishItem.toMap()));
        }
        await Future.wait(allFutures);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.wishItem == null
              ? 'Deseo añadido con éxito'
              : 'Deseo actualizado con éxito'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar el deseo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final _auth = FirebaseAuth.instance;
    final wishlistsStreamSnapshot =
        WishlistDao().getWishlistsStreamSnapshot(_auth.currentUser!.uid);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.wishItem == null ? 'Añadir Deseo' : 'Editar Deseo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveWish,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Deseo',
                        hintText: 'Ej: Auriculares Bluetooth',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El nombre del deseo es obligatorio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        labelText: 'URL del Producto (Opcional)',
                        hintText: 'Ej: https://amazon.es/producto',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Precio Estimado (€) (Opcional)',
                        hintText: 'Ej: 79.99',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _storeController,
                      decoration: const InputDecoration(
                        labelText: 'Tienda Sugerida (Opcional)',
                        hintText: 'Ej: Amazon, El Corte Inglés',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notas / Detalles (Opcional)',
                        hintText: 'Ej: Me gustaría en color negro',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Prioridad:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Slider(
                      value: _selectedPriority.toDouble(),
                      min: 1,
                      max: 5,
                      divisions: 4,
                      label: _getPriorityLabel(_selectedPriority),
                      onChanged: (double value) {
                        setState(() {
                          _selectedPriority = value.round();
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Baja'),
                        Text('Media'),
                        Text('Imprescindible'),
                      ],
                    ),
                    if (widget.wishList == null) ...[
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        'Añadir a Listas de Deseos',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ),
            if (widget.wishList == null)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: wishlistsStreamSnapshot,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverToBoxAdapter(
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasError) {
                      return SliverToBoxAdapter(
                        child: Center(
                          child: Text('Error al cargar listas: ${snapshot.error}'),
                        ),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];

                    return SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          if (docs.isNotEmpty) ...[
                            const Text(
                              'Selecciona una o más listas:',
                              style: TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            ...docs.map((doc) {
                              final wishlist = WishList.fromFirestore(doc);
                              final isSelected =
                                  _selectedWishlistIds.contains(wishlist.id);
                              return CheckboxListTile(
                                title: Text(wishlist.name),
                                subtitle: Text(wishlist.privacy.name),
                                value: isSelected,
                                onChanged: (_) =>
                                    _toggleWishlistSelection(wishlist.id!),
                                activeColor: Colors.indigo,
                              );
                            }).toList(),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 16),
                          ],
                          Text(
                            docs.isEmpty
                                ? 'Crea tu primera lista:'
                                : 'O crea una nueva:',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _newListController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre de la nueva lista',
                              hintText: 'Ej: Regalos de cumpleaños',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 24), // Espacio al final
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getPriorityLabel(int priority) {
    switch (priority) {
      case 1:
        return 'Baja';
      case 2:
        return 'Normal';
      case 3:
        return 'Media';
      case 4:
        return 'Alta';
      case 5:
        return 'Imprescindible';
      default:
        return 'Media';
    }
  }
}