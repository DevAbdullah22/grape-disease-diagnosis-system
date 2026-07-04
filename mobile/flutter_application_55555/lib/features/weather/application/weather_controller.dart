import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_55555/core/api_client.dart';
import 'package:flutter_application_55555/core/contracts/app_runtime_contract.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class WeatherController {
  final ApiClient apiClient;
  final FirebaseAuth firebaseAuth;
  final Future<SharedPreferences> Function() sharedPreferencesProvider;

  WeatherController({
    required this.apiClient,
    required this.firebaseAuth,
    Future<SharedPreferences> Function()? sharedPreferencesProvider,
  }) : sharedPreferencesProvider =
           sharedPreferencesProvider ?? SharedPreferences.getInstance;

  Future<String?> loadSavedLocationsRaw() async {
    final sp = await sharedPreferencesProvider();
    return sp.getString(AppRuntimeContract.weatherSavedLocationsKey);
  }

  Future<String?> loadDefaultLocationRaw() async {
    final sp = await sharedPreferencesProvider();
    final uid = firebaseAuth.currentUser?.uid;
    final key = AppRuntimeContract.weatherDefaultLocationKey(uid);
    return sp.getString(key);
  }

  Future<List<Map<String, dynamic>>> fetchFarmsFromBackend() async {
    final prefs = await sharedPreferencesProvider();
    final backendId = prefs.getString(AppRuntimeContract.backendUserIdKey);
    if (backendId == null || backendId.isEmpty) return [];

    final uri = Uri.parse('${apiClient.baseUrl}/api/farms?userId=$backendId');
    final resp = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );
    if (resp.statusCode != 200) return [];

    final List data = json.decode(resp.body) as List;
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> saveLocations(
    List<Map<String, dynamic>> serializedLocations,
  ) async {
    final sp = await sharedPreferencesProvider();
    final data = json.encode(serializedLocations);
    await sp.setString(AppRuntimeContract.weatherSavedLocationsKey, data);
  }

  Future<String?> createFarmOnBackend({
    required String name,
    required double lat,
    required double lon,
  }) async {
    final prefs = await sharedPreferencesProvider();
    final backendId = prefs.getString(AppRuntimeContract.backendUserIdKey);
    if (backendId == null || backendId.isEmpty) return null;

    final uri = Uri.parse('${apiClient.baseUrl}/api/farms');
    final payload = json.encode({
      'UserId': backendId,
      'Name': name,
      'Latitude': lat,
      'Longitude': lon,
    });

    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: payload,
    );

    if (resp.statusCode == 200 || resp.statusCode == 201) {
      final Map<String, dynamic> decoded =
          json.decode(resp.body) as Map<String, dynamic>;
      return decoded['id']?.toString() ?? decoded['Id']?.toString();
    }

    return null;
  }

  Future<void> deleteFarmOnBackend(String id) async {
    final prefs = await sharedPreferencesProvider();
    final backendId = prefs.getString(AppRuntimeContract.backendUserIdKey);
    if (backendId == null || backendId.isEmpty) return;

    final uri = Uri.parse('${apiClient.baseUrl}/api/farms/$id');
    final resp = await http.delete(
      uri,
      headers: {'Content-Type': 'application/json'},
    );
    if (resp.statusCode >= 200 && resp.statusCode < 300) return;
  }

  Future<void> saveDefaultLocation({
    String? id,
    required double lat,
    required double lon,
    String? name,
  }) async {
    final prefs = await sharedPreferencesProvider();
    final payload = json.encode({
      'id': id ?? '',
      'lat': lat,
      'lon': lon,
      'name': name ?? '',
    });
    final uid = firebaseAuth.currentUser?.uid;
    final key = AppRuntimeContract.weatherDefaultLocationKey(uid);
    await prefs.setString(key, payload);
  }
}
