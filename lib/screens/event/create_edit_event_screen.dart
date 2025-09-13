// lib/screens/create_edit_event_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:wishy/dao/event_dao.dart';
import 'package:wishy/dao/user_dao.dart';
import 'package:wishy/models/event.dart';
import 'package:wishy/models/contact.dart'; // Para seleccionar invitados
import 'package:uuid/uuid.dart';

class CreateEditEventScreen extends StatefulWidget {
  final Event? event;
  
  
  const CreateEditEventScreen({super.key, this.event}); // Si es null, es un nuevo evento; si no, para editar

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
  // Lista de IDs de los contactos seleccionados
  final List<String> _selectedContactIds = [];
  // NUEVO: Lista de IDs de invitados seleccionados para un evento
  final List<String> _selectedInvitationIds = [];

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
          content: StreamBuilder<QuerySnapshot>(
            stream: UserDao().getAcceptedContactsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()));
              }
              if (!snapshot.hasData) {
                return const SizedBox(
                  height: 100,
                  child: Center(
                      child: Text('No tienes contactos aceptados.',
                          textAlign: TextAlign.center)),
                );
              }

              final contacts = snapshot.data!;
              return SingleChildScrollView(
                child: Column(
                  children: contacts.docs.map((contact) {
                    final isSelected = _selectedInvitationIds.contains(contact.id);
                    return CheckboxListTile(
                      title: Text(contact['name'] ?? '--'),
                      subtitle: Text(contact['email']),
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedInvitationIds.add(contact.id);
                          } else {
                            _selectedInvitationIds.remove(contact.id);
                          }
                        });
                        (context as Element).markNeedsBuild();
                      },
                    );
                  }).toList(),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // No guardar cambios
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => {
                Navigator.pop(context, tempSelected)
              },
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

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Usuario no autenticado.');
    }
    var userId = currentUser.uid;

    if (_formKey.currentState!.validate()) {
      if(widget.event != null) {

      }
      final String id = widget.event?.id ?? const Uuid().v4();
      Map<String, Object> event = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'eventDate': _selectedEventDate.toIso8601String(),
        'type': _selectedEventType.toString().split('.').last,
        'invitedUserIds': _selectedInvitationIds,
        'ownerId': userId, // En una app real, obtén el ID del usuario logueado
        'participantUserIds': widget.event?.participantUserIds ?? [],
        'userListsInEvent': widget.event?.userListsInEvent ?? {},
        'userLooseWishesInEvent': widget.event?.userLooseWishesInEvent ?? {},
        // participantUserIds, userListsInEvent y userLooseWishesInEvent se gestionan en la pantalla de detalle
      };
      EventDao().createOrUpdateEvent(id, event);
      Navigator.of( context).pop(); // Cierra la pantalla actual
      //Navigator.pop(context, Event.fromMap(id, event));
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
                initialValue: _selectedEventType,
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
                  //final contactName = availableContactsForEvents.firstWhere((c) => c.id == id, orElse: () => Contact(id: id, name: 'Usuario Desconocido', email: 'a@a.com')).name;
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundImage: /*UserDao().getUserById(id).firstWhere((c) => c.id == id, orElse: () => Contact(id: id, name: '', email: 'b@b.com')).avatarUrl != null
                          ? NetworkImage(availableContactsForEvents.firstWhere((c) => c.id == id, orElse: () => Contact(id: id, name: '', email: 'c@c.com')).avatarUrl!)
                          : */null,
                      child: /*availableContactsForEvents.firstWhere((c) => c.id == id, orElse: () => Contact(id: id, name: '', email: 'd@d.com')).avatarUrl == null
                          ? const Icon(Icons.person_outline, size: 18)
                          : */null,
                    ),
                    label: Text(/*contactName??*/ '--'),
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