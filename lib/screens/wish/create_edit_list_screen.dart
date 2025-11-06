import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wishy/dao/user_dao.dart';
import 'package:wishy/dao/wish_list_dao.dart';
import 'package:wishy/models/contact.dart';
import 'package:wishy/models/wish_list.dart';
import 'package:uuid/uuid.dart'; // Añadir al pubspec.yaml: uuid: ^4.0.0

class CreateEditListScreen extends StatefulWidget {
  final WishList? wishList; // Si es null, es una nueva lista; si no, es para editar

  const CreateEditListScreen({super.key, this.wishList});

  @override
  State<CreateEditListScreen> createState() => _CreateEditListScreenState();
}

class _CreateEditListScreenState extends State<CreateEditListScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  ListPrivacy _selectedPrivacy = ListPrivacy.private;
  List<String> _selectedContactIds = [];
  DateTime? _selectedEventDate;
  final bool _allowMarkingAsBought = true;
  List<Contact> _contacts = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.wishList?.name ?? '');
    _selectedPrivacy = widget.wishList?.privacy ?? ListPrivacy.private;
    _selectedContactIds = List.from(widget.wishList?.sharedWithContactIds ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveList() async{
    if (_formKey.currentState!.validate()) {
      final String id = widget.wishList?.id ?? const Uuid().v4();

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null || !user.emailVerified) {
          throw Exception('Usuario no autenticado');
        }
        WishlistDao().createOrUpdateWishlist(id, {
          'name': _nameController.text,
          'privacy': _selectedPrivacy.toString().split('.').last,
          'sharedWithContactIds': _selectedPrivacy == ListPrivacy.shared
              ? _selectedContactIds
              : [],
          'ownerId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
          'itemCount': widget.wishList?.itemCount ?? 0,
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de autenticación: $e')),
        );
        return;
      }

      final WishList newList = WishList(
        name: _nameController.text,
        privacy: _selectedPrivacy,
        sharedWithContactIds: _selectedPrivacy == ListPrivacy.shared
            ? _selectedContactIds
            : [],
        ownerId: FirebaseAuth.instance.currentUser!.uid,
      );
      Navigator.pop(context, newList); // Devuelve la nueva/actualizada lista
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedEventDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedEventDate) {
      setState(() {
        _selectedEventDate = picked;
      });
    }
  }

  void _selectContacts() async {
    // Esto es una simulación. En una app real, abrirías una pantalla
    // para seleccionar contactos de tu base de datos o agenda.
     _contacts = await UserDao().getAcceptedContacts();

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
        title: Text(widget.wishList == null ? 'Nueva Lista' : 'Editar Lista'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveList,
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                title: const Text('Pública (Cualquiera con el enlace)'),
                value: ListPrivacy.public,
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
                      label: Text("MiContacto"),
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
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //   children: [
              //     Text(
              //       'Permitir marcar como "Comprado"',
              //       style: Theme.of(context).textTheme.titleMedium,
              //     ),
              //     Switch(
              //       value: _allowMarkingAsBought,
              //       onChanged: (value) {
              //         setState(() {
              //           _allowMarkingAsBought = value;
              //         });
              //       },
              //     ),
              //   ],
              // ),
              // const SizedBox(height: 24),
              // ListTile(
              //   title: Text(
              //     _selectedEventDate == null
              //         ? 'Asociar fecha de evento (Opcional)'
              //         : 'Fecha del evento: ${_selectedEventDate!.toLocal().toIso8601String().split('T')[0]}',
              //   ),
              //   trailing: const Icon(Icons.calendar_today),
              //   onTap: () => _selectDate(context),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}