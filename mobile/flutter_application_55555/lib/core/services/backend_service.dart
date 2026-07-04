import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_55555/core/contracts/app_runtime_contract.dart';
import 'package:flutter_application_55555/core/network/app_http_client.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

/// Service مركزي للتعامل مع الــ Backend
///
/// الهدف: جلب idToken من Firebase ثم إرسال POST إلى
/// /api/User/firebase-register ليبحث الخادم عن المستخدم
/// حسب FirebaseUid أو ينشئه إذا لم يوجد.
class BackendService {
  /// عنوان الـ API الأساسي. افتراضيًا موجّه إلى محاكي أندرويد
  /// استخدم 10.0.2.2 للوصول إلى localhost من المحاكي.
  final String baseUrl;
  final AppHttpClient _appHttpClient;

  BackendService({String? baseUrl})
    : baseUrl = baseUrl ?? Config.apiBaseUrl,
      _appHttpClient = AppHttpClient(baseUrl: baseUrl ?? Config.apiBaseUrl);

  /// ترجع map من JSON الرد عند الحالة 200
  /// ترمي استثناء BackendException عند فشل الشبكة أو حالة غير 200
  /// Send or sync current Firebase user to backend.
  ///
  /// By default this method will skip the network call if a `backend_user_id`
  /// is already stored locally (to avoid duplicate creations). Pass
  /// `force: true` to always call the backend.
  Future<Map<String, dynamic>> sendUserToBackend({
    User? firebaseUser,
    bool force = false,
  }) async {
    final user = firebaseUser ?? FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No Firebase user is currently signed in.');
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final existingBackendId = prefs.getString(
      AppRuntimeContract.backendUserIdKey,
    );
    final existingBackendFirebaseUid = prefs.getString(
      AppRuntimeContract.backendFirebaseUidKey,
    );
    final currentFirebaseUid = user.uid;
    if (!force &&
        existingBackendId != null &&
        existingBackendId.isNotEmpty &&
        existingBackendFirebaseUid == currentFirebaseUid) {
      // already synced for this firebase uid — return a minimal map to indicate existing id
      // ignore: avoid_print
      print(
        'BackendService: skipping sendUserToBackend, ${AppRuntimeContract.backendUserIdKey} exists for this firebase uid',
      );
      return {'userId': existingBackendId};
    }

    // الحصول على idToken (مهم للتحقق في الخادم)
    final idToken = await user.getIdToken();

    // DEBUG: طباعة التوكن مؤقتًا لتسهيل الاختبار (أزلها بعد التأكد)
    // لا تعرض هذا في بيئة الإنتاج.
    final String preview = (idToken != null && idToken.length > 40)
        ? idToken.substring(0, 40)
        : (idToken ?? '');
    // ignore: avoid_print
    print('DEBUG: sending idToken to backend: $preview...');

    final uri = _appHttpClient.uri('/api/User/firebase-register');

    final payload = jsonEncode({
      'IdToken': idToken,
      'FullName': user.displayName,
      'PhotoUrl': user.photoURL,
    });

    http.Response resp;
    try {
      resp = await _appHttpClient.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: payload,
      );
    } catch (e) {
      throw BackendException(-1, 'Network error: $e');
    }

    if (resp.statusCode == 200) {
      try {
        final decoded = jsonDecode(resp.body);
        // إذا استلمنا معرف المستخدم من الباكند، خزّنه محليًا لعمليات لاحقة
        try {
          String? backendId;
          if (decoded is Map<String, dynamic>) {
            if (decoded['userId'] != null)
              backendId = decoded['userId'].toString();
            if (decoded['UserId'] != null)
              backendId = decoded['UserId'].toString();
            if (decoded['id'] != null) backendId = decoded['id'].toString();

            // Some endpoints return the user object under the key 'user'
            if (decoded['user'] is Map<String, dynamic>) {
              final userMap = decoded['user'] as Map<String, dynamic>;
              if (userMap['id'] != null) backendId = userMap['id'].toString();
              if (userMap['Id'] != null) backendId = userMap['Id'].toString();
              if (userMap['userId'] != null)
                backendId = userMap['userId'].toString();
              if (userMap['UserId'] != null)
                backendId = userMap['UserId'].toString();
            }

            if (decoded['data'] is Map<String, dynamic>) {
              final data = decoded['data'] as Map<String, dynamic>;
              if (data['userId'] != null) backendId = data['userId'].toString();
              if (data['UserId'] != null) backendId = data['UserId'].toString();
              if (data['id'] != null) backendId = data['id'].toString();
            }
          }
          if (backendId != null && backendId.isNotEmpty) {
            await prefs.setString(
              AppRuntimeContract.backendUserIdKey,
              backendId,
            );
            await prefs.setString(
              AppRuntimeContract.backendFirebaseUidKey,
              currentFirebaseUid,
            );
            // ignore: avoid_print
            print(
              'Saved ${AppRuntimeContract.backendUserIdKey}=$backendId for firebaseUid=$currentFirebaseUid',
            );
          }
        } catch (e) {
          // ignore: avoid_print
          print('Warning: failed to persist backend user id: $e');
        }
        if (decoded is Map<String, dynamic>) return decoded;
        return {'data': decoded};
      } catch (e) {
        throw BackendException(resp.statusCode, 'Invalid JSON: ${resp.body}');
      }
    }

    // غير 200: أعد رسالة الخطأ كاملة
    throw BackendException(resp.statusCode, resp.body);
  }

  /// Get user profile from backend by firebaseUid
  Future<Map<String, dynamic>> getUserProfile({String? firebaseUid}) async {
    if (firebaseUid == null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No firebase user');
      firebaseUid = user.uid;
    }

    final uri = _appHttpClient.uri('/api/User/me?firebaseUid=$firebaseUid');
    final resp = await _appHttpClient.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );
    if (resp.statusCode == 200) {
      final decoded = jsonDecode(resp.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'data': decoded};
    }
    throw BackendException(resp.statusCode, resp.body);
  }

  /// Get notification subscriptions for current backend user
  Future<List<Map<String, dynamic>>> getUserSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(AppRuntimeContract.backendUserIdKey);
    if (userId == null || userId.isEmpty)
      throw Exception(
        '${AppRuntimeContract.backendUserIdKey} not found in prefs',
      );

    final uri = _appHttpClient.uri(
      '/api/Notification/subscriptions?userId=$userId',
    );
    final resp = await _appHttpClient.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    );
    if (resp.statusCode == 200) {
      final decoded = jsonDecode(resp.body);
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      }
      if (decoded is Map<String, dynamic> && decoded['data'] is List) {
        return List<Map<String, dynamic>>.from(decoded['data']);
      }
      return [];
    }
    throw BackendException(resp.statusCode, resp.body);
  }

  /// Update or create a notification subscription for current backend user
  Future<Map<String, dynamic>> updateSubscription({
    required String type,
    required bool isEnabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(AppRuntimeContract.backendUserIdKey);
    if (userId == null || userId.isEmpty)
      throw Exception(
        '${AppRuntimeContract.backendUserIdKey} not found in prefs',
      );

    final uri = _appHttpClient.uri('/api/Notification/subscriptions');
    final payload = jsonEncode({
      'UserId': userId,
      'Type': type,
      'IsEnabled': isEnabled,
    });

    final resp = await _appHttpClient.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: payload,
    );
    if (resp.statusCode == 200) {
      final decoded = jsonDecode(resp.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'data': decoded};
    }
    throw BackendException(resp.statusCode, resp.body);
  }

  /// Mark one or more notifications as read for the current backend user
  Future<Map<String, dynamic>> markNotificationsRead({
    required List<String> notificationIds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(AppRuntimeContract.backendUserIdKey);
    if (userId == null || userId.isEmpty)
      throw Exception(
        '${AppRuntimeContract.backendUserIdKey} not found in prefs',
      );

    final uri = _appHttpClient.uri('/api/notifications/mark-read');
    final payload = jsonEncode({'UserId': userId, 'Ids': notificationIds});

    final resp = await _appHttpClient.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: payload,
    );
    if (resp.statusCode == 200) {
      final decoded = jsonDecode(resp.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'data': decoded};
    }
    throw BackendException(resp.statusCode, resp.body);
  }

  /// Delete one or more notifications for the current backend user
  Future<Map<String, dynamic>> deleteNotifications({
    required List<String> notificationIds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(AppRuntimeContract.backendUserIdKey);
    if (userId == null || userId.isEmpty)
      throw Exception(
        '${AppRuntimeContract.backendUserIdKey} not found in prefs',
      );

    final uri = _appHttpClient.uri('/api/notifications/delete');
    final payload = jsonEncode({'UserId': userId, 'Ids': notificationIds});

    final resp = await _appHttpClient.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: payload,
    );
    if (resp.statusCode == 200) {
      final decoded = jsonDecode(resp.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'data': decoded};
    }
    throw BackendException(resp.statusCode, resp.body);
  }
}

/// Exception type used throughout BackendService for non-200 responses.
class BackendException implements Exception {
  final int code;
  final String message;
  BackendException(this.code, this.message);

  @override
  String toString() => 'BackendException($code): $message';
}
