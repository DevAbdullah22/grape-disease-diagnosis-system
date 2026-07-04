class NotificationSubscriptionModel {
  final String type;
  final bool isEnabled;

  NotificationSubscriptionModel({required this.type, required this.isEnabled});

  factory NotificationSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return NotificationSubscriptionModel(
      type: json['Type'] ?? json['type'] ?? '',
      isEnabled: json['IsEnabled'] ?? json['isEnabled'] ?? false,
    );
  }
}
