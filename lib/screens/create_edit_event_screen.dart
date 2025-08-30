// lib/screens/create_edit_event_screen.dart
import 'package:flutter/material.dart';
import 'package:wishy/models/event.dart';
import 'package:wishy/models/contact.dart'; // Para seleccionar invitados
import 'package:uuid/uuid.dart';

// Simulación de contactos disponibles para invitar (los mismos que para compartir listas)
// En una app real, vendrían de la lista de amigos del usuario
final List<Contact> availableContactsForEvents = [
  Contact(id: 'c1', name: 'Ana García'),
  Contact(id: 'c2', name: 'Javier Ramos'),
  Contact(id: 'c3', name: 'María López'),
];

class CreateEditEventScreen extends StatefulWidget {
  final Event? event; // Si es null, es un nuevo evento; si no, para editar

  const CreateEditEventScreen({super.key, this.event});

  @override
  State<CreateEditEventScreen> createState() => _CreateEditEventScreenState();
}

class _CreateEditEventScreenState extends State<CreateEditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late DateTime _selectedEventDate;
  EventType _selectedEventType = EventType.other;
  List<String> _invitedUserIds = []; // IDs de los invitados

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.event?.name ?? '');
    _descriptionController = TextEditingController(text: widget.event?.description ?? '');
    _selectedEventDate = widget.event?.eventDate ?? DateTime.now();
    _selectedEventType = widget.event?.type ?? EventType.other;
    _invitedUserIds = List.from(widget.event?.invitedUserIds ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedEventDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedEventDate) {
      setState(() {
        _selectedEventDate = picked;
      });
    }
  }

  void _selectInvitations() async {
    final List<String>? result = await showDialog<List<String>>(
      context: context,
      builder: (context) {
        // Clonar la lista actual para trabajar en el diálogo
        List<String> tempSelected = List.from(_invitedUserIds);
        return AlertDialog(
          title: const Text('Invitar Usuarios'),
          content: SingleChildScrollView(
            child: Column(
              children: availableContactsForEvents.map((contact) {
                final isSelected = tempSelected.contains(contact.id);
                return StatefulBuilder( // Necesario para que el checkbox se actualice
                  builder: (context, setDialogState) {
                    return CheckboxListTile(
                      title: Text(contact.name),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setDialogState(() {
                          if (value == true) {
                            tempSelected.add(contact.id);
                          } else {
                            tempSelected.remove(contact.id);
                          }
                        });
                      },
                    );
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // No guardar cambios
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, tempSelected),
              child: const Text('Invitar'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        _invitedUserIds = result;
      });
    }
  }

  void _saveEvent() {
    if (_formKey.currentState!.validate()) {
      final String id = widget.event?.id ?? const Uuid().v4();
      final Event newEvent = Event(
        id: id,
        name: _nameController.text,
        description: _descriptionController.text,
        organizerUserId: 'current_user_id', // En una app real, obtén el ID del usuario logueado
        eventDate: _selectedEventDate,
        type: _selectedEventType,
        invitedUserIds: _invitedUserIds,
        // Al crear/editar un evento, los participantes y listas/deseos se gestionan en la pantalla de detalle
        participantUserIds: widget.event?.participantUserIds ?? [],
        userListsInEvent: widget.event?.userListsInEvent ?? {},
        userLooseWishesInEvent: widget.event?.userLooseWishesInEvent ?? {},
      );
      Navigator.pop(context, newEvent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? 'Crear Evento' : 'Editar Evento'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveEvent,
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
                  labelText: 'Nombre del Evento',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Introduce un nombre para el evento.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción (Opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  'Fecha del Evento: ${_selectedEventDate.toIso8601String().split('T')[0]}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<EventType>(
                value: _selectedEventType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Evento',
                  border: OutlineInputBorder(),
                ),
                items: EventType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.toString().split('.').last.replaceAllMapped(
                      RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}').trim()
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedEventType = value!;
                  });
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Invitados:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _selectInvitations,
                icon: const Icon(Icons.person_add),
                label: const Text('Invitar Usuarios'),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _invitedUserIds.map((id) {
                  final contactName = availableContactsForEvents.firstWhere((c) => c.id == id, orElse: () => Contact(id: id, name: 'Usuario Desconocido')).name;
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundImage: availableContactsForEvents.firstWhere((c) => c.id == id, orElse: () => Contact(id: id, name: '')).avatarUrl != null
                          ? NetworkImage(availableContactsForEvents.firstWhere((c) => c.id == id, orElse: () => Contact(id: id, name: '')).avatarUrl!)
                          : null,
                      child: availableContactsForEvents.firstWhere((c) => c.id == id, orElse: () => Contact(id: id, name: '')).avatarUrl == null
                          ? const Icon(Icons.person_outline, size: 18)
                          : null,
                    ),
                    label: Text(contactName),
                    onDeleted: () {
                      setState(() {
                        _invitedUserIds.remove(id);
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}