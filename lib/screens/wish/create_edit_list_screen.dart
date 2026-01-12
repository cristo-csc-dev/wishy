import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:wishy/auth/user_auth.dart';
import 'package:wishy/dao/user_dao.dart';
import 'package:wishy/dao/wish_list_dao.dart';
import 'package:wishy/models/contact.dart';
import 'package:wishy/models/wish_list.dart';
import 'package:uuid/uuid.dart'; // Añadir al pubspec.yaml: uuid: ^4.0.0

class CreateEditListScreen extends StatefulWidget {
  final String? wishListId; // Si es null, es una nueva lista; si no, es para editar

  const CreateEditListScreen({super.key, this.wishListId});

  @override
  State<CreateEditListScreen> createState() => _CreateEditListScreenState();
}

class _CreateEditListScreenState extends State<CreateEditListScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  bool _isLoading = false;
  WishList? _wishList;
  ListPrivacy _selectedPrivacy = ListPrivacy.private;
  List<String> _selectedContactIds = [];
  List<Contact> _contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContactsAndList();    
  }

  Future<void> _loadContactsAndList() async {
    setState(() {
      _isLoading = true;
    });
    var contacts = await UserDao().getAcceptedContacts();
    WishList? wishList = null;
    if(widget.wishListId != null) {
      wishList = WishList.fromFirestore(
        await WishlistDao().getWishlistById(widget.wishListId!));
    }
    setState(() {
      _contacts = contacts;
      _wishList = wishList;
      _nameController = TextEditingController(text: _wishList?.name ?? '');
      _selectedPrivacy = _wishList?.privacy ?? ListPrivacy.private;
      _selectedContactIds = List.from(_wishList?.sharedWithContactIds ?? []);
    
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveList() async {
    if (_formKey.currentState!.validate()) {
      final String id = widget.wishListId ?? const Uuid().v4();

      try {
        if (!UserAuth.instance.isUserAuthenticatedAndVerified()) {
          throw Exception('Usuario no autenticado');
        }
        WishlistDao().createOrUpdateWishlist(id, {
          'name': _nameController.text,
          'privacy': _selectedPrivacy.toString().split('.').last,
          'sharedWithContactIds': _selectedPrivacy == ListPrivacy.shared
              ? _selectedContactIds
              : [],
          'ownerId': UserAuth.instance.getCurrentUser().uid,
          'createdAt': FieldValue.serverTimestamp(),
          'itemCount': _wishList?.itemCount ?? 0,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lista ${_nameController.text} ${_wishList == null ? 'creada' : 'actualizada'}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de autenticación: $e')),
        );
        return;
      }

      Navigator.pop(context, _nameController.text); // Devuelve la nueva/actualizada lista
    }
  }

  void _selectContacts() async {
    // Esto es una simulación. En una app real, abrirías una pantalla
    // para seleccionar contactos de tu base de datos o agenda.

    final List<String>? result = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Contactos'),
        content: SingleChildScrollView(
          child: Column(
            children: /*availableContactIds*/_contacts.map((contact) {
              final isSelected = _selectedContactIds.contains(contact.id);
              return CheckboxListTile(
                title: Text(contact.name?? '--'),
                subtitle: Text(contact.email),
                value: isSelected,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedContactIds.add(contact.id);
                    } else {
                      _selectedContactIds.remove(contact.id);
                    }
                  });
                  // Forzar la reconstrucción del AlertDialog para reflejar el cambio
                  (context as Element).markNeedsBuild();
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _selectedContactIds),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _selectedContactIds = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_wishList == null ? 'Nueva Lista' : 'Editar Lista'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveList,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
      : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la Lista',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, introduce un nombre para la lista';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 24),
              Text(
                'Privacidad de la Lista:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              RadioListTile<ListPrivacy>(
                title: const Text('Privada (Solo yo)'),
                value: ListPrivacy.private,
                groupValue: _selectedPrivacy,
                onChanged: (value) {
                  setState(() {
                    _selectedPrivacy = value!;
                  });
                },
              ),
              RadioListTile<ListPrivacy>(
                title: const Text('Compartir con Contactos/Grupos específicos'),
                value: ListPrivacy.shared,
                groupValue: _selectedPrivacy,
                onChanged: (value) {
                  setState(() {
                    _selectedPrivacy = value!;
                  });
                },
              ),
              if (_selectedPrivacy == ListPrivacy.shared) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _selectContacts,
                  icon: const Icon(Icons.group_add),
                  label: const Text('Añadir Contactos/Grupos'),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: _selectedContactIds.map((id) {
                    return Chip(
                      label: Text(_contacts.firstWhere((c) => c.id == id).name ?? '--'),
                      onDeleted: () {
                        setState(() {
                          _selectedContactIds.remove(id);
                        });
                      },
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}