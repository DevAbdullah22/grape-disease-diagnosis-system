part of 'notifications_cubit.dart';

enum NotificationsLoadStatus { initial, loading, success, error }

class NotificationsState {
  static const Object _unset = Object();

  final List<AppNotification> notifications;
  final bool loading;
  final String? error;
  final String? backendIdForDebug;
  final String? debugInfo;
  final int tabIndex;
  final NotificationsLoadStatus loadStatus;
  final NotificationsUiAction? uiAction;
  final int uiActionVersion;

  const NotificationsState({
    required this.notifications,
    required this.loading,
    required this.error,
    required this.backendIdForDebug,
    required this.debugInfo,
    required this.tabIndex,
    required this.loadStatus,
    required this.uiAction,
    required this.uiActionVersion,
  });

  factory NotificationsState.initial() {
    return const NotificationsState(
      notifications: <AppNotification>[],
      loading: true,
      error: null,
      backendIdForDebug: null,
      debugInfo: null,
      tabIndex: 0,
      loadStatus: NotificationsLoadStatus.initial,
      uiAction: null,
      uiActionVersion: 0,
    );
  }

  NotificationsState copyWith({
    Object? notifications = _unset,
    bool? loading,
    Object? error = _unset,
    Object? backendIdForDebug = _unset,
    Object? debugInfo = _unset,
    int? tabIndex,
    NotificationsLoadStatus? loadStatus,
    Object? uiAction = _unset,
    int? uiActionVersion,
  }) {
    return NotificationsState(
      notifications: identical(notifications, _unset)
          ? this.notifications
          : notifications as List<AppNotification>,
      loading: loading ?? this.loading,
      error: identical(error, _unset) ? this.error : error as String?,
      backendIdForDebug: identical(backendIdForDebug, _unset)
          ? this.backendIdForDebug
          : backendIdForDebug as String?,
      debugInfo: identical(debugInfo, _unset)
          ? this.debugInfo
          : debugInfo as String?,
      tabIndex: tabIndex ?? this.tabIndex,
      loadStatus: loadStatus ?? this.loadStatus,
      uiAction: identical(uiAction, _unset)
          ? this.uiAction
          : uiAction as NotificationsUiAction?,
      uiActionVersion: uiActionVersion ?? this.uiActionVersion,
    );
  }
}

abstract class NotificationsUiAction {
  const NotificationsUiAction();
}

class NotificationsShowDeleteSuccessSnackBar extends NotificationsUiAction {
  final AppNotification removed;
  final int originalIndex;

  const NotificationsShowDeleteSuccessSnackBar({
    required this.removed,
    required this.originalIndex,
  });
}

class NotificationsShowDeleteErrorSnackBar extends NotificationsUiAction {
  final String message;

  const NotificationsShowDeleteErrorSnackBar({required this.message});
}

class NotificationsShowDetailsSheet extends NotificationsUiAction {
  final AppNotification notification;
  final String relatedId;

  const NotificationsShowDetailsSheet({
    required this.notification,
    required this.relatedId,
  });
}

class NotificationsNavigateToLibraryItem extends NotificationsUiAction {
  final String relatedId;

  const NotificationsNavigateToLibraryItem({required this.relatedId});
}

class NotificationsNavigateToDiagnosisDetails extends NotificationsUiAction {
  final AppNotification notification;
  final String relatedId;

  const NotificationsNavigateToDiagnosisDetails({
    required this.notification,
    required this.relatedId,
  });
}

class NotificationsDiagnosisDetails {
  final String diseaseName;
  final double? confidence;
  final String? description;
  final String? diseaseImageUrl;

  const NotificationsDiagnosisDetails({
    required this.diseaseName,
    required this.confidence,
    required this.description,
    required this.diseaseImageUrl,
  });
}
