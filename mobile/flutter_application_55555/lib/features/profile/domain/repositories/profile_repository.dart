import 'package:flutter_application_55555/features/profile/domain/entities/user.dart';

abstract class ProfileRepository {
  Future<UserEntity> fetchProfile({String? userId});
}
