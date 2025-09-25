enum NotificationType {
  contactRequest,
  eventInvitation;

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
