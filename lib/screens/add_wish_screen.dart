import 'package:flutter/material.dart';
import 'package:wishy/models/wish_item.dart';
import 'package:uuid/uuid.dart'; // Asegúrate de tener 'uuid' en tu pubspec.yaml

class AddWishScreen extends StatefulWidget {
  final WishItem? wishItem; // Si es null, es un nuevo deseo; si no, para editar

  const AddWishScreen({super.key, this.wishItem});

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
  int _selectedPriority = 3; // Default medium priority

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.wishItem?.name ?? '');
    _urlController = TextEditingController(text: widget.wishItem?.productUrl ?? '');
    _priceController = TextEditingController(text: widget.wishItem?.estimatedPrice?.toString() ?? '');
    _storeController = TextEditingController(text: widget.wishItem?.suggestedStore ?? '');
    _notesController = TextEditingController(text: widget.wishItem?.notes ?? '');
    _selectedPriority = widget.wishItem?.priority ?? 3;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _priceController.dispose();
    _storeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveWish() {
    if (_formKey.currentState!.validate()) {
      final String id = widget.wishItem?.id ?? const Uuid().v4();
      final WishItem newWish = WishItem(
        id: id,
        name: _nameController.text,
        productUrl: _urlController.text.isNotEmpty ? _urlController.text : null,
        estimatedPrice: double.tryParse(_priceController.text),
        suggestedStore: _storeController.text.isNotEmpty ? _storeController.text : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        priority: _selectedPriority,
        // En una app real, aquí se intentaría extraer la imagen de la URL
        imageUrl: widget.wishItem?.imageUrl, // Por simplicidad, mantiene la misma o null
      );
      Navigator.pop(context, newWish); // Devuelve el nuevo/actualizado deseo
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.wishItem == null ? 'Añadir Deseo' : 'Editar Deseo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveWish,
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
                keyboardType: TextInputType.number,
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
                label: _selectedPriority == 1
                    ? 'Baja'
                    : _selectedPriority == 2
                        ? 'Normal'
                        : _selectedPriority == 3
                            ? 'Media'
                            : _selectedPriority == 4
                                ? 'Alta'
                                : 'Imprescindible',
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
                  Text('Normal'),
                  Text('Media'),
                  Text('Alta'),
                  Text('Imprescindible'),
                ],
              ),
              // Aquí podrías añadir un selector de imagen si no hay URL o si la URL no tiene imagen
              // ElevatedButton.icon(
              //   onPressed: () { /* Lógica para seleccionar imagen */ },
              //   icon: const Icon(Icons.image),
              //   label: const Text('Añadir Imagen'),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}