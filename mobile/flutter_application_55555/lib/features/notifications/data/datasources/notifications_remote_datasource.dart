import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:flutter_application_55555/core/api_client.dart';
import '../models/notification_model.dart';

class NotificationsRemoteDataSource {
  final ApiClient apiClient;

  NotificationsRemoteDataSource(this.apiClient);

  Future<List<NotificationModel>> fetchNotifications({String? userId}) async {
    final uri = Uri.parse(
      '${apiClient.baseUrl}/api/notifications${userId != null ? '/$userId' : ''}',
    );
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      final list = jsonDecode(resp.body) as List<dynamic>;
      return list
          .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    throw Exception('Failed to load notifications: ${resp.statusCode}');
  }

  Future<int> fetchUnreadNotificationsCount({required String userId}) async {
    final paths = <String>[
      '/api/notifications/unread-count',
      '/notifications/unread-count',
    ];
    Object? lastError;

    for (final path in paths) {
      final uri = Uri.parse('${apiClient.baseUrl}$path').replace(
        queryParameters: {
          // Keep both styles for backend compatibility.
          'userId': userId,
          'UserId': userId,
        },
      );
      try {
        final resp = await http.get(uri);
        if (resp.statusCode == 200) {
          final decoded = jsonDecode(resp.body);
          return _extractUnreadCount(decoded);
        }
        // If endpoint path is missing, try the next fallback path.
        if (resp.statusCode == 404) {
          lastError = '404 at $path';
          continue;
        }
        lastError = 'status=${resp.statusCode} body=${resp.body}';
      } catch (e) {
        lastError = e;
      }
    }

    throw Exception('Failed to load unread notifications count: $lastError');
  }

  int _extractUnreadCount(dynamic decoded) {
    final parsed = _findCountValue(decoded);
    if (parsed != null && parsed >= 0) return parsed;
    return 0;
  }

  int? _findCountValue(dynamic value) {
    final direct = _toInt(value);
    if (direct != null) return direct;

    if (value is Map) {
      int? genericCount;
      for (final entry in value.entries) {
        final key = entry.key.toString().toLowerCase().replaceAll('_', '');
        final parsed = _toInt(entry.value);
        if (parsed == null) continue;

        final mentionsUnread =
            key.contains('unread') || key.contains('notread');
        final mentionsCount =
            key.contains('count') ||
            key.contains('total') ||
            key.contains('number');

        if (mentionsUnread && mentionsCount) return parsed;
        if (mentionsUnread) return parsed;
        if (key == 'count' || key == 'value') genericCount ??= parsed;
      }

      if (genericCount != null) return genericCount;

      for (final nested in value.values) {
        final parsedNested = _findCountValue(nested);
        if (parsedNested != null) return parsedNested;
      }
    }

    if (value is List) {
      for (final item in value) {
        final parsedNested = _findCountValue(item);
        if (parsedNested != null) return parsedNested;
      }
    }

    return null;
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}
