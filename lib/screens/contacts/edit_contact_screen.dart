import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wishy/dao/user_dao.dart';
import 'package:wishy/models/contact.dart';

class EditContactScreen extends StatefulWidget {

  final String contactId;

  const EditContactScreen({super.key, required this.contactId});

  @override
  State<EditContactScreen> createState() => _EditContactScreenState();
}

class _EditContactScreenState extends State<EditContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _displayEmailController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  Contact? _contact;

  @override
  void initState() {
    super.initState();
    _getContact();
  }

  void _getContact() async {
    setState(() {
      _isLoading = true;
    });
    try {
      Contact contact = await UserDao().getContactById(widget.contactId);
      setState(() {
        _contact = contact;
        _displayNameController.text = contact.name ?? '';
        _displayEmailController.text = contact.email;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo cargar el contacto.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _displayEmailController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      if (_contact != null) {
        try {
          await UserDao().updateContactUserName(_contact!, _displayNameController.text.trim());
         
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Contacto actualizado con éxito')),
            );
            Navigator.of(context).pop();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al actualizar el contacto: $e')),
            );
          }
        } finally {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null || !user.emailVerified) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Avatar del usuario
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _contact?.avatarUrl != null && _contact!.avatarUrl!.isNotEmpty
                      ? NetworkImage(_contact!.avatarUrl!)
                      : null,
                  child: _contact?.avatarUrl == null || _contact!.avatarUrl!.isEmpty
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              // Campo para el nombre de visualización
              TextFormField(
                controller: _displayNameController,
                decoration: InputDecoration(
                  labelText: 'Nombre de usuario',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa tu nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Campo para el email (solo lectura)
              TextFormField(
                controller: _displayEmailController,
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa un email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Botón de guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text('Guardar Cambios'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
