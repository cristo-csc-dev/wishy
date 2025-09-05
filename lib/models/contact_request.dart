  // Modelo de datos para una solicitud de contacto
  import 'package:cloud_firestore/cloud_firestore.dart';

class ContactRequest {
    final String id;
    final String senderId;
    final String senderEmail;
    final String senderName;

    ContactRequest({
      required this.id,
      required this.senderId,
      required this.senderEmail,
      required this.senderName,
    });

    factory ContactRequest.fromFirestore(DocumentSnapshot doc) {
      Map data = doc.data() as Map<String, dynamic>;
      return ContactRequest(
        id: doc.id,
        senderId: data['senderId'] ?? '',
        senderEmail: data['senderEmail'] ?? 'Usuario desconocido',
        senderName: data['senderName'] ?? 'Anónimo',
      );
    }
  }