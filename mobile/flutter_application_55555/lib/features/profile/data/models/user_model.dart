import '../../domain/entities/user.dart';

class UserModel extends UserEntity {
  final Map<String, dynamic> raw;

  UserModel({required this.raw})
    : super(
        id: raw['id']?.toString() ?? raw['Id']?.toString() ?? '',
        fullName:
            raw['fullName']?.toString() ?? raw['FullName']?.toString() ?? '',
        email: raw['email']?.toString() ?? raw['Email']?.toString() ?? '',
      );

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final map = <String, dynamic>{};
    json.forEach((k, v) {
      final key = k.isNotEmpty ? (k[0].toLowerCase() + k.substring(1)) : k;
      map[key] = v;
    });
    return UserModel(raw: map);
  }
}
