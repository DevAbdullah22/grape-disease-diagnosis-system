import 'package:flutter_application_55555/features/notifications/domain/entities/app_notification.dart';
import 'package:flutter_application_55555/features/notifications/domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_datasource.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsRemoteDataSource remote;

  NotificationsRepositoryImpl(this.remote);

  @override
  Future<List<AppNotification>> fetchNotifications({String? userId}) async {
    final models = await remote.fetchNotifications(userId: userId);
    // `models` is List<NotificationModel>. Dart generics are invariant,
    // so convert to List<AppNotification> explicitly to avoid runtime cast errors.
    return models.map<AppNotification>((m) => m).toList();
  }

  @override
  Future<int> getUnreadNotificationsCount(String userId) {
    return remote.fetchUnreadNotificationsCount(userId: userId);
  }
}
