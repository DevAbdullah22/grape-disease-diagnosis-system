import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_55555/core/contracts/app_runtime_contract.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_55555/core/services/backend_service.dart';
import 'package:flutter_application_55555/core/services/fcm_service.dart';
import 'package:flutter_application_55555/features/notifications/domain/entities/app_notification.dart';
import 'package:flutter_application_55555/features/notifications/domain/usecases/get_notifications.dart';

part 'notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  static const Color _tagRed = Color(0xFFFFE5E5);
  static const Color _tagRedText = Color(0xFFFF3B30);
  static const Color _tagYellow = Color(0xFFFFF7E0);
  static const Color _tagYellowText = Color(0xFFFFA800);
  static const Color _tagBlue = Color(0xFFE5F0FF);
  static const Color _tagBlueText = Color(0xFF0066FF);
  static const Color _tagPurple = Color(0xFFF3E8FF);
  static const Color _tagPurpleText = Color(0xFFB620E0);

  final GetNotifications _getNotifications;

  NotificationsCubit({required GetNotifications getNotifications})
    : _getNotifications = getNotifications,
      super(NotificationsState.initial());

  void _safeEmit(NotificationsState newState) {
    if (isClosed) return;
    emit(newState);
  }

  void onTabChanged(int tabIndex) {
    _safeEmit(state.copyWith(tabIndex: tabIndex));
  }

  Future<void> syncUserAndReload() async {
    _safeEmit(
      state.copyWith(
        loading: true,
        error: null,
        loadStatus: NotificationsLoadStatus.loading,
      ),
    );
    try {
      final backend = BackendService();
      await backend.sendUserToBackend(force: true);
      await FcmService.sendFcmTokenToBackend();
    } catch (e) {
      debugPrint('Failed to sync backend user: $e');
    }
    if (isClosed) return;
    await loadNotifications();
  }

  Future<void> loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backendId = prefs.getString(AppRuntimeContract.backendUserIdKey);
      debugPrint(
        'NotificationsScreen: loading notifications for ${AppRuntimeContract.backendUserIdKey}=$backendId',
      );
      final list = await _getNotifications.call(userId: backendId);
      _safeEmit(
        state.copyWith(
          notifications: list,
          loading: false,
          backendIdForDebug: backendId,
          debugInfo: 'fetched ${list.length} notifications',
          loadStatus: NotificationsLoadStatus.success,
        ),
      );
    } catch (e) {
      _safeEmit(
        state.copyWith(
          error: e.toString(),
          loading: false,
          debugInfo: 'error while loading: ${e.toString()}',
          loadStatus: NotificationsLoadStatus.error,
        ),
      );
    }
  }

  Future<void> markAllRead() async {
    final unreadIds = state.notifications
        .where((n) => !n.read)
        .map((n) => n.id)
        .toList();
    if (unreadIds.isEmpty) return;

    _safeEmit(
      state.copyWith(
        notifications: state.notifications
            .map((n) => n.copyWith(read: true))
            .toList(),
      ),
    );

    try {
      final backend = BackendService();
      await backend.markNotificationsRead(notificationIds: unreadIds);
    } catch (e) {
      debugPrint('Failed to mark all notifications read on backend: $e');
    }
  }

  Future<void> deleteNotification(AppNotification n) async {
    final removed = n;
    final originalIndex = state.notifications.indexWhere(
      (it) => it.id == removed.id,
    );

    if (originalIndex != -1) {
      final updated = List<AppNotification>.from(state.notifications);
      updated.removeAt(originalIndex);
      _safeEmit(state.copyWith(notifications: updated));
    }

    try {
      final backend = BackendService();
      await backend.deleteNotifications(notificationIds: [removed.id]);
      _emitUiAction(
        NotificationsShowDeleteSuccessSnackBar(
          removed: removed,
          originalIndex: originalIndex,
        ),
      );
    } catch (e) {
      final updated = List<AppNotification>.from(state.notifications);
      if (originalIndex >= 0 && originalIndex <= updated.length) {
        updated.insert(originalIndex, removed);
      } else {
        updated.add(removed);
      }
      _safeEmit(
        state.copyWith(
          notifications: updated,
          uiAction: const NotificationsShowDeleteErrorSnackBar(
            message: 'فشل حذف الإشعار. تأكد من اتصال الإنترنت وحاول مجدداً.',
          ),
          uiActionVersion: state.uiActionVersion + 1,
        ),
      );
      debugPrint('Failed to delete notification on backend: $e');
    }
  }

  void undoDelete({
    required AppNotification removed,
    required int originalIndex,
  }) {
    final updated = List<AppNotification>.from(state.notifications);
    if (originalIndex >= 0 && originalIndex <= updated.length) {
      updated.insert(originalIndex, removed);
    } else {
      updated.add(removed);
    }
    _safeEmit(state.copyWith(notifications: updated));
  }

  Future<void> openDetails(AppNotification tapped) async {
    final index = state.notifications.indexWhere((it) => it.id == tapped.id);
    final n = tapped;
    debugPrint(
      'notification tapped: type=${n.type}, id=${n.id} (orig index $index)',
    );

    String relatedId = '';
    try {
      final raw = (n as dynamic).raw;
      relatedId = extractRelatedIdFromRaw(raw);
      debugPrint('extracted related id from raw: $relatedId');
    } catch (e) {
      debugPrint('extract raw error (not a raw map?): $e');
    }

    if (relatedId.trim().isEmpty) relatedId = n.id.trim();

    if (index != -1) {
      final updated = List<AppNotification>.from(state.notifications);
      updated[index] = updated[index].copyWith(read: true);
      _safeEmit(state.copyWith(notifications: updated));
    }
    try {
      final backend = BackendService();
      await backend.markNotificationsRead(notificationIds: [n.id]);
    } catch (e) {
      debugPrint('Failed to mark notification read on backend: $e');
    }

    _emitUiAction(
      NotificationsShowDetailsSheet(notification: n, relatedId: relatedId),
    );
  }

  void openLibraryItemDetails({
    required AppNotification n,
    required String relatedId,
  }) {
    debugPrint(
      'NotificationsScreen: opening library item details id=$relatedId raw=${(n as dynamic).raw}',
    );
    _emitUiAction(NotificationsNavigateToLibraryItem(relatedId: relatedId));
  }

  void openDiagnosisDetails({
    required AppNotification n,
    required String relatedId,
  }) {
    _emitUiAction(
      NotificationsNavigateToDiagnosisDetails(
        notification: n,
        relatedId: relatedId,
      ),
    );
  }

  List<AppNotification> getDisplayedNotifications() {
    var displayed = List<AppNotification>.from(state.notifications);

    final tabIndex = state.tabIndex;
    if (tabIndex == 1) {
      displayed = displayed.where((n) {
        final t = n.type.toLowerCase();
        return t.contains('مرض') ||
            t.contains('علاج') ||
            t.contains('disease') ||
            t.contains('treatment');
      }).toList();
    } else if (tabIndex == 2) {
      displayed = displayed.where((n) {
        final t = n.type.toLowerCase();
        return t.contains('طقس') || t.contains('weather');
      }).toList();
    } else if (tabIndex == 3) {
      displayed = displayed.where((n) {
        final t = n.type.toLowerCase();
        return t.contains('مقال') ||
            t.contains('article') ||
            t.contains('library') ||
            t.contains('مكتبة');
      }).toList();
    }

    DateTime? dtOf(AppNotification n) => datetimeFromRaw((n as dynamic).raw);

    int priorityScore(AppNotification n) {
      final t = n.type.toLowerCase();
      if (t.contains('مرض') || t.contains('علاج')) return 0;
      if (t.contains('طقس')) return 1;
      if (t.contains('مقال') ||
          t.contains('article') ||
          t.contains('library')) {
        return 2;
      }
      return 3;
    }

    displayed.sort((a, b) {
      if (a.read != b.read) return a.read ? 1 : -1;
      final pa = priorityScore(a);
      final pb = priorityScore(b);
      if (pa != pb) return pa.compareTo(pb);
      final dta = dtOf(a);
      final dtb = dtOf(b);
      if (dta != null && dtb != null) return dtb.compareTo(dta);
      if (dta != null) return -1;
      if (dtb != null) return 1;
      return 0;
    });

    return displayed;
  }

  int getUnreadCount(List<AppNotification> notifications) {
    return notifications.where((n) => !n.read).length;
  }

  String buildMessageForList(AppNotification n) {
    String scheduledLabel = '';
    String farmLabel = '';
    try {
      final raw = (n as dynamic).raw as Map<String, dynamic>?;
      if (raw != null) {
        final sched =
            raw['scheduledAt'] ??
            raw['nextDoseAt'] ??
            raw['createdAt'] ??
            raw['sentAt'];
        if (sched != null) {
          DateTime? dt;
          try {
            dt = DateTime.tryParse(sched.toString());
          } catch (_) {
            dt = null;
          }
          if (dt != null) {
            scheduledLabel =
                ' (مجدولة لـ ${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} - ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')})';
          } else {
            scheduledLabel = ' (مجدولة)';
          }
        } else {
          scheduledLabel = ' (مجدولة)';
        }

        try {
          final possibleKeys = [
            'farmName',
            'farm',
            'farm_name',
            'farmNameAr',
            'farmNameArabic',
            'اسم_المزرعة',
            'farmNameEn',
            'farmName_ar',
          ];
          for (final k in possibleKeys) {
            if (raw.containsKey(k) && raw[k] != null) {
              final val = raw[k];
              final s = val.toString().trim();
              if (s.isNotEmpty) {
                farmLabel = s;
                break;
              }
            }
          }
          if (farmLabel.isEmpty && raw['data'] is Map) {
            final data = raw['data'] as Map<String, dynamic>;
            for (final k in ['farmName', 'farm', 'اسم_المزرعة']) {
              if (data.containsKey(k) && data[k] != null) {
                final s = data[k].toString().trim();
                if (s.isNotEmpty) {
                  farmLabel = s;
                  break;
                }
              }
            }
          }
        } catch (_) {}
      }
    } catch (_) {}

    return '${farmLabel.isNotEmpty ? 'المزرعة: $farmLabel\n' : ''}${n.body}$scheduledLabel';
  }

  String extractRelatedIdFromRaw(dynamic raw) {
    try {
      if (raw == null) return '';
      if (raw is Map<String, dynamic>) {
        final candidates = [
          'diagnosisId',
          'DiagnosisId',
          'relatedId',
          'relatedid',
          'related',
          'articleId',
          'ArticleId',
          'postId',
          'id',
        ];
        for (final k in candidates) {
          if (raw.containsKey(k) && raw[k] != null) return raw[k].toString();
        }
        for (final entry in raw.entries) {
          final key = entry.key.toString().toLowerCase();
          if ((key.contains('id') ||
                  key.contains('diagnosis') ||
                  key.contains('article') ||
                  key.contains('related')) &&
              entry.value != null) {
            return entry.value.toString();
          }
        }
        if (raw.containsKey('data') && raw['data'] is Map) {
          return extractRelatedIdFromRaw(raw['data']);
        }
      }
    } catch (_) {}
    return '';
  }

  bool isWeatherType(String type) {
    final t = type.toLowerCase();
    return t.contains('طقس') || t.contains('weather');
  }

  bool isArticleType(String type) {
    final t = type.toLowerCase();
    return t.contains('مقال') ||
        t.contains('article') ||
        t.contains('library') ||
        t.contains('مكتبة') ||
        t.contains('مقالة') ||
        t.contains('posts') ||
        t.contains('post');
  }

  Map<String, Object?> styleForType(String type) {
    final t = type.toLowerCase();

    if (t.contains('طقس')) {
      return {
        'tagColor': _tagYellow,
        'tagTextColor': _tagYellowText,
        'borderColor': _tagYellow,
        'trailingIcon': Icons.warning,
        'trailingIconColor': _tagYellowText,
        'showDot': true,
      };
    }

    if (t.contains('مرض') || t.contains('علاج')) {
      return {
        'tagColor': _tagRed,
        'tagTextColor': _tagRedText,
        'borderColor': _tagRed,
        'trailingIcon': Icons.close,
        'trailingIconColor': _tagRedText,
        'showDot': true,
      };
    }

    if (t.contains('مقال') ||
        t.contains('article') ||
        t.contains('library') ||
        t.contains('مكتبة') ||
        t.contains('مقالة')) {
      return {
        'tagColor': _tagPurple,
        'tagTextColor': _tagPurpleText,
        'borderColor': _tagPurple,
        'trailingIcon': Icons.article,
        'trailingIconColor': _tagPurpleText,
        'showDot': false,
      };
    }

    return {
      'tagColor': _tagBlue,
      'tagTextColor': _tagBlueText,
      'borderColor': _tagBlue,
      'trailingIcon': Icons.info_outline,
      'trailingIconColor': _tagBlueText,
      'showDot': true,
    };
  }

  String timeLabelFromRaw(dynamic raw) {
    try {
      if (raw == null) return '';
      if (raw is Map<String, dynamic>) {
        final candidates = [
          'createdAt',
          'sentAt',
          'time',
          'timestamp',
          'created_at',
        ];
        for (final k in candidates) {
          if (raw.containsKey(k) && raw[k] != null) {
            final s = raw[k].toString();
            final dt = DateTime.tryParse(s);
            if (dt != null) {
              return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} - ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
            }
          }
        }
        if (raw['data'] is Map) return timeLabelFromRaw(raw['data']);
      }
    } catch (_) {}
    return '';
  }

  String extractFarmFromRaw(dynamic raw) {
    try {
      if (raw == null) return '';
      if (raw is Map<String, dynamic>) {
        final possibleKeys = [
          'farmName',
          'farm',
          'farm_name',
          'farmNameAr',
          'farmNameArabic',
          'اسم_المزرعة',
          'farmNameEn',
          'farmName_ar',
        ];
        for (final k in possibleKeys) {
          if (raw.containsKey(k) && raw[k] != null) {
            final s = raw[k].toString().trim();
            if (s.isNotEmpty) return s;
          }
        }
        if (raw['data'] is Map) return extractFarmFromRaw(raw['data']);
      }
    } catch (_) {}
    return '';
  }

  DateTime? datetimeFromRaw(dynamic raw) {
    try {
      if (raw == null) return null;
      if (raw is Map<String, dynamic>) {
        final candidates = [
          'sentAt',
          'createdAt',
          'scheduledAt',
          'time',
          'timestamp',
          'created_at',
        ];
        for (final k in candidates) {
          if (raw.containsKey(k) && raw[k] != null) {
            final s = raw[k].toString();
            final dt = DateTime.tryParse(s);
            if (dt != null) return dt;
          }
        }
        if (raw['data'] is Map) return datetimeFromRaw(raw['data']);
      }
    } catch (_) {}
    return null;
  }

  NotificationsDiagnosisDetails extractDiagnosisDetails(AppNotification n) {
    String diseaseName = '';
    double? confidence;
    String? description;
    String? diseaseImageUrl;
    try {
      final raw = (n as dynamic).raw;
      if (raw is Map<String, dynamic>) {
        diseaseName =
            (raw['diseaseName'] ??
                    raw['DiseaseName'] ??
                    raw['disease'] ??
                    raw['disease_name'] ??
                    raw['diseaseNameAr'] ??
                    '')
                .toString();
        final confRaw =
            raw['confidence'] ?? raw['Confidence'] ?? raw['confidenceScore'];
        if (confRaw != null) confidence = double.tryParse(confRaw.toString());
        description =
            raw['description']?.toString() ?? raw['Description']?.toString();
        diseaseImageUrl =
            raw['diseaseImageUrl']?.toString() ??
            raw['imageUrl']?.toString() ??
            raw['DiseaseImageUrl']?.toString();
      }
    } catch (_) {}
    return NotificationsDiagnosisDetails(
      diseaseName: diseaseName,
      confidence: confidence,
      description: description,
      diseaseImageUrl: diseaseImageUrl,
    );
  }

  void _emitUiAction(NotificationsUiAction action) {
    _safeEmit(
      state.copyWith(
        uiAction: action,
        uiActionVersion: state.uiActionVersion + 1,
      ),
    );
  }
}
