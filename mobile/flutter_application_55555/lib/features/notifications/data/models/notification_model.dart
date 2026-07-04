import 'package:flutter_application_55555/features/notifications/domain/entities/app_notification.dart';

class NotificationModel extends AppNotification {
  final Map<String, dynamic> raw;

  NotificationModel({required this.raw})
      : super(
          id: raw['id']?.toString() ?? raw['Id']?.toString() ?? '',
          title: raw['title']?.toString() ?? raw['Title']?.toString() ?? '',
          body: raw['body']?.toString() ?? raw['Body']?.toString() ?? '',
          type: raw['type']?.toString() ?? raw['Type']?.toString() ?? '',
          read: _parseRead(raw),
        );

  static bool _parseRead(Map<String, dynamic> raw) {
    try {
      final candidates = ['read', 'isRead', 'isread', 'seen', 'isSeen', 'isseen'];
      for (final k in candidates) {
        if (raw.containsKey(k) && raw[k] != null) {
          final v = raw[k];
          if (v is bool) return v;
          final s = v.toString().toLowerCase();
          if (s == 'true' || s == '1') return true;
          if (s == 'false' || s == '0') return false;
        }
      }
    } catch (_) {}
    return false;
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final map = <String, dynamic>{};
    json.forEach((k, v) {
      final key = k.isNotEmpty ? (k[0].toLowerCase() + k.substring(1)) : k;
      map[key] = v;
    });
    return NotificationModel(raw: map);
  }

  /// Return a copy preserving the raw map (useful to update 'read' flag without losing raw).
  NotificationModel copyWith({bool? read}) {
    final newRaw = Map<String, dynamic>.from(raw);
    if (read != null) {
      // set common keys used to derive `read` in _parseRead
      newRaw['read'] = read;
      newRaw['isRead'] = read;
      newRaw['seen'] = read;
      newRaw['isSeen'] = read;
    }
    return NotificationModel(raw: newRaw);
  }
}

