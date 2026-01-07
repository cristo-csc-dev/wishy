import 'package:flutter/material.dart';
import 'package:wishy/dao/wish_list_dao.dart';

class IHaveItScreen extends StatefulWidget {
  final String? wishListId;
  final String? wishItemId;
  final String? sourceUserId; // owner of the original wishlist
  final String? wishItemName;

  const IHaveItScreen({Key? key, this.wishListId, this.wishItemId, this.sourceUserId, this.wishItemName}) : super(key: key);

  @override
  State<IHaveItScreen> createState() => _IHaveItScreenState();
}

class _IHaveItScreenState extends State<IHaveItScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¿Cuándo fue?')));
      return;
    }

    // Llamar a DAO para mover el documento
    try {
      if (widget.wishItemId == null || widget.sourceUserId == null || widget.wishListId == null) {
        throw Exception('Faltan identificadores del deseo o lista.');
      }

      final scaffold = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      await WishlistDao().moveItemToIHaveIt(
        sourceUserId: widget.sourceUserId!,
        wishlistId: widget.wishListId!,
        itemId: widget.wishItemId!,
        iHaveItDate: _selectedDate!,
        iHaveItComments: _descriptionController.text.trim(),
      );

      if (!mounted) return;
      scaffold.showSnackBar(const SnackBar(content: Text('Deseo movido a "Lo tengo!"')));
      navigator.pop(true);
    } catch (e) {
      final scaffold = ScaffoldMessenger.of(context);
      scaffold.showSnackBar(SnackBar(content: Text('Error guardando: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lo tengo!'),
        actions: [
          IconButton(
            onPressed: _save,
            tooltip: 'Guardar',
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_selectedDate == null ? '¿Cuándo fue?' : _selectedDate!.toLocal().toString().split(' ')[0]),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Cuéntenos un poco sobre cómo fue :)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Introduce una descripción.';
                  }
                  return null;
                },
                keyboardType: TextInputType.multiline,
                minLines: 4,
                maxLines: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
