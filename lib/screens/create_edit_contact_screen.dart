import 'package:flutter/material.dart';
import 'package:wishy/dao/contact_dao.dart';

class CreateEditContactScreen extends StatefulWidget {
  const CreateEditContactScreen({super.key});

  @override
  State<CreateEditContactScreen> createState() => _CreateEditContactScreenState();
}

class _CreateEditContactScreenState extends State<CreateEditContactScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  void _addContact() {
    // Aquí es donde se conectará con la base de datos o el servicio
    // para añadir el contacto. Por ahora, solo imprimimos los datos.
    final name = _nameController.text;
    final email = _emailController.text;
    
    if (name.isNotEmpty && email.isNotEmpty) {
      ContactDao().addContact(name, email);
      print('Añadir contacto: $name, $email');
      Navigator.of(context).pop();
    } else {
      // Mostrar un mensaje de error si los campos están vacíos
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, rellena todos los campos.')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Añadir Contacto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre o alias',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _addContact,
              child: const Text('Guardar Contacto'),
            ),
          ],
        ),
      ),
    );
  }
}
