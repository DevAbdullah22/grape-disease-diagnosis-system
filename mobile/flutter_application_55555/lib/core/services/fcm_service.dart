import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_application_55555/core/contracts/app_runtime_contract.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class FcmService {
  static bool _initialized = false;
  static Future<void> sendFcmTokenToBackend() async {
    try {
      // الحصول على FCM Token
      final token = await FirebaseMessaging.instance.getToken();
      print("🔥 FCM Token = $token");

      if (token == null || token.isEmpty) {
        print("⚠ لا يوجد FCM Token");
        return;
      }

      // الحصول على Firebase UID
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("⚠ لا يوجد مستخدم مسجّل الدخول");
        return;
      }

      final firebaseUid = user.uid;

      // تحقق محلياً مما إذا أرسلنا هذا التوكن مسبقاً حتى لا نكرر الطلبات بعد إعادة التشغيل
      final prefs = await SharedPreferences.getInstance();
      final localKey = AppRuntimeContract.lastFcmTokenKey(firebaseUid);
      final lastSent = prefs.getString(localKey);
      if (lastSent != null && lastSent == token) {
        print('ℹ️ FCM token matches last sent token; skipping send.');
      } else {
        // المسار الصحيح الذي موجود في الباك إند
        final uri = Uri.parse("${Config.apiBaseUrl}/api/User/update-fcm-token");

        final body = jsonEncode({
          "firebaseUid": firebaseUid,
          "token": token,
        });

        final response = await http.post(
          uri,
          headers: {
            "Content-Type": "application/json",
          },
          body: body,
        );

        print("📨 STATUS = ${response.statusCode}");
        print("📨 BODY = ${response.body}");

        if (response.statusCode == 200 || response.statusCode == 204) {
          // حفظ التوكن محلياً كأحدث قيمة مرسلة
          await prefs.setString(localKey, token);
          print('✅ FCM token successfully sent and stored locally.');
        } else {
          print('❌ Failed to update FCM token on backend.');
        }
      }

      // المسار الصحيح الذي موجود في الباك إند
      final uri = Uri.parse("${Config.apiBaseUrl}/api/User/update-fcm-token");

      final body = jsonEncode({
        "firebaseUid": firebaseUid,
        "token": token,
      });

      final response = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
        },
        body: body,
      );

      print("📨 STATUS = ${response.statusCode}");
      print("📨 BODY = ${response.body}");
      // Register token refresh listener once
      if (!_initialized) {
        _initialized = true;
        FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
          try {
            if (newToken == null || newToken.isEmpty) return;
            print('🔁 FCM token refreshed: $newToken');
            final prefs2 = await SharedPreferences.getInstance();
            final localKey2 = AppRuntimeContract.lastFcmTokenKey(firebaseUid);
            final lastSent2 = prefs2.getString(localKey2);
            if (lastSent2 != null && lastSent2 == newToken) {
              print('ℹ️ Refreshed token matches last stored token; skipping backend update.');
              return;
            }
            final uri2 = Uri.parse('${Config.apiBaseUrl}/api/User/update-fcm-token');
            final body2 = jsonEncode({
              'firebaseUid': firebaseUid,
              'token': newToken,
            });
            final resp2 = await http.post(uri2, headers: {'Content-Type': 'application/json'}, body: body2);
            print('🔁 STATUS = ${resp2.statusCode}');
            print('🔁 BODY = ${resp2.body}');
            if (resp2.statusCode == 200 || resp2.statusCode == 204) {
              await prefs2.setString(localKey2, newToken);
              print('✅ Refreshed FCM token sent and stored locally.');
            } else {
              print('❌ Failed to send refreshed FCM token to backend.');
            }
          } catch (e) {
            print('❌ Error sending refreshed FCM token: $e');
          }
        });
      }
    } catch (e) {
      print("❌ خطأ أثناء إرسال FCM token: $e");
    }
  }
}
