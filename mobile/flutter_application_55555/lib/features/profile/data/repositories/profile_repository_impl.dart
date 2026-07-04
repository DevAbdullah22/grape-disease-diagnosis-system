import 'package:flutter_application_55555/features/profile/domain/entities/user.dart';
import 'package:flutter_application_55555/features/profile/domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remote;

  ProfileRepositoryImpl(this.remote);

  @override
  Future<UserEntity> fetchProfile({String? userId}) async {
    final model = await remote.fetchProfile(userId: userId);
    return model;
  }
}
