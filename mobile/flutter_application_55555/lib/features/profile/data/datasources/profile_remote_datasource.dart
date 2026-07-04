import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:flutter_application_55555/core/api_client.dart';
import '../models/user_model.dart';

class ProfileRemoteDataSource {
  final ApiClient apiClient;

  ProfileRemoteDataSource(this.apiClient);

  Future<UserModel> fetchProfile({String? userId}) async {
    final uri = Uri.parse('${apiClient.baseUrl}/api/users/${userId ?? "me"}');
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      return UserModel.fromJson(json);
    }
    throw Exception('Failed to load profile: ${resp.statusCode}');
  }
}
