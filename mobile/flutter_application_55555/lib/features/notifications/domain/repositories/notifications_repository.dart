import 'package:flutter_application_55555/features/notifications/domain/entities/app_notification.dart';

abstract class NotificationsRepository {
  Future<List<AppNotification>> fetchNotifications({String? userId});
  Future<int> getUnreadNotificationsCount(String userId);
}
