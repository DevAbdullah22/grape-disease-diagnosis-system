import 'package:flutter_application_55555/features/profile/domain/entities/user.dart';
import '../repositories/profile_repository.dart' as pr;

class GetProfile {
  final pr.ProfileRepository repository;

  GetProfile(this.repository);

  Future<UserEntity> call({String? userId}) =>
      repository.fetchProfile(userId: userId);
}
