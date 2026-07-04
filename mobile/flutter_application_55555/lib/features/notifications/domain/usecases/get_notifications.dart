import 'package:flutter_application_55555/features/notifications/domain/entities/app_notification.dart';
import '../repositories/notifications_repository.dart' as nr;

class GetNotifications {
  final nr.NotificationsRepository repository;

  GetNotifications(this.repository);

  Future<List<AppNotification>> call({String? userId}) =>
      repository.fetchNotifications(userId: userId);
}
