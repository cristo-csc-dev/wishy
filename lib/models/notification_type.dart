enum NotificationType {
  contactRequest("Tienes una nueva solicitud de contacto"),
  eventInvitation("Has sido invitado a un evento");

  final String title;

  const NotificationType(this.title);

  static NotificationType? fromFirestore(String? value) {
    switch (value) {
      case 'contactRequest':
        return NotificationType.contactRequest;
      case 'eventInvitation':
        return NotificationType.eventInvitation;
      default:
        return null;
    }
  }
}
