class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool read;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.read = false,
  });

  AppNotification copyWith({bool? read}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      read: read ?? this.read,
    );
  }
}
