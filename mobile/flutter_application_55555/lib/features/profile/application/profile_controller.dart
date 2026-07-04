import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_55555/core/services/backend_service.dart';
import 'package:flutter_application_55555/features/auth/data/repositories/auth_repository.dart';

class ProfileLoadResult {
  final bool reminderEnabled;
  final bool weatherEnabled;
  final bool tipsEnabled;
  final bool libraryUpdatesEnabled;
  final String? errorMessage;
  final String? fullName;
  final String? photoUrl;
  final String? location;

  const ProfileLoadResult({
    required this.reminderEnabled,
    required this.weatherEnabled,
    required this.tipsEnabled,
    required this.libraryUpdatesEnabled,
    required this.errorMessage,
    required this.fullName,
    required this.photoUrl,
    required this.location,
  });
}

class ProfileSubscriptionUpdateResult {
  final bool success;
  final Object? error;

  const ProfileSubscriptionUpdateResult({
    required this.success,
    required this.error,
  });
}

class ProfileLogoutResult {
  final bool success;
  final String message;

  const ProfileLogoutResult({
    required this.success,
    required this.message,
  });
}

class ProfileController {
  final BackendService backendService;
  final AuthRepository authRepository;
  final FirebaseAuth firebaseAuth;
  final Future<void> Function() sendFcmTokenToBackend;

  ProfileController({
    required this.backendService,
    required this.authRepository,
    required this.firebaseAuth,
    required this.sendFcmTokenToBackend,
  });

  Future<ProfileLoadResult> loadProfileAndSubscriptions() async {
    bool reminderEnabled = false;
    bool weatherEnabled = false;
    bool tipsEnabled = false;
    bool libraryUpdatesEnabled = false;
    String? fullName;
    String? photoUrl;
    String? location;
    String? errorMessage;

    try {
      try {
        await backendService.sendUserToBackend();
      } catch (_) {}

      final subs = await backendService.getUserSubscriptions();
      try {
        final profile = await backendService.getUserProfile();
        if (profile is Map<String, dynamic>) {
          fullName =
              (profile['FullName'] ??
                      profile['fullName'] ??
                      profile['displayName'])
                  ?.toString();
          photoUrl =
              (profile['PhotoUrl'] ??
                      profile['photoUrl'] ??
                      profile['photoURL'])
                  ?.toString();
          location = (profile['Location'] ?? profile['location'])?.toString();
        }
      } catch (_) {
        final fbUser = firebaseAuth.currentUser;
        fullName ??= fbUser?.displayName;
        photoUrl ??= fbUser?.photoURL;
      }
      for (final s in subs) {
        final type = (s['Type'] ?? s['type'] ?? '').toString().toLowerCase();
        final enabled = (s['IsEnabled'] ?? s['isEnabled'] ?? false) as bool;
        if (type == 'treatment') reminderEnabled = enabled;
        if (type == 'weather') weatherEnabled = enabled;
        if (type == 'recommendations') tipsEnabled = enabled;
        if (type == 'library') libraryUpdatesEnabled = enabled;
      }
    } catch (e) {
      errorMessage = 'خطأ جلب البيانات: $e';
    }

    return ProfileLoadResult(
      reminderEnabled: reminderEnabled,
      weatherEnabled: weatherEnabled,
      tipsEnabled: tipsEnabled,
      libraryUpdatesEnabled: libraryUpdatesEnabled,
      errorMessage: errorMessage,
      fullName: fullName,
      photoUrl: photoUrl,
      location: location,
    );
  }

  Future<ProfileSubscriptionUpdateResult> updateSubscription({
    required String type,
    required bool value,
  }) async {
    try {
      try {
        await backendService.sendUserToBackend();
      } catch (_) {}

      await backendService.updateSubscription(type: type, isEnabled: value);
      return const ProfileSubscriptionUpdateResult(success: true, error: null);
    } catch (e) {
      return ProfileSubscriptionUpdateResult(success: false, error: e);
    }
  }

  Future<ProfileLogoutResult> signOut() async {
    try {
      try {
        await sendFcmTokenToBackend();
      } catch (e) {
        print('Warning sending FCM before signOut: $e');
      }

      AuthResult res;
      try {
        res = await authRepository.signOut();
      } catch (e) {
        print('Exception from authRepo.signOut(): $e');
        return ProfileLogoutResult(
          success: false,
          message: 'حدث خطأ أثناء تسجيل الخروج: $e',
        );
      }

      return ProfileLogoutResult(
        success: res.success,
        message: res.message ?? '',
      );
    } catch (e) {
      print('Unexpected error during logout flow: $e');
      return ProfileLogoutResult(
        success: false,
        message: 'حدث خطأ أثناء تسجيل الخروج: $e',
      );
    }
  }
}
