import '../repositories/notifications_repository.dart' as nr;

class GetUnreadNotificationsCount {
  final nr.NotificationsRepository repository;

  GetUnreadNotificationsCount(this.repository);

  Future<int> call(String userId) =>
      repository.getUnreadNotificationsCount(userId);
}
