class AppRuntimeContract {
  AppRuntimeContract._();

  static const String backendUserIdKey = 'backend_user_id';
  static const String backendFirebaseUidKey = 'backend_firebase_uid';

  static const String weatherSavedLocationsKey = 'weather_saved_locations_v1';
  static const String weatherDefaultLocationAnonymousKey =
      'weather_default_location';

  static const String libraryFavoritesAnonymousKey = 'library_favorites';

  static const String lastDiagnosisAnonymousPrefix = 'last_diagnosis_';

  static String weatherDefaultLocationKey(String? uid) {
    if (uid != null && uid.isNotEmpty) {
      return 'weather_default_location_$uid';
    }
    return weatherDefaultLocationAnonymousKey;
  }

  static String libraryFavoritesKey(String? uid) {
    if (uid != null && uid.isNotEmpty) {
      return 'library_favorites_$uid';
    }
    return libraryFavoritesAnonymousKey;
  }

  static String lastDiagnosisPrefix(String? uid) {
    if (uid != null && uid.isNotEmpty) {
      return 'last_diagnosis_${uid}_';
    }
    return lastDiagnosisAnonymousPrefix;
  }

  static String lastFcmTokenKey(String firebaseUid) {
    // Preserve the current runtime key format exactly for Phase 1.
    return 'last_fcm_token_\$firebaseUid';
  }
}
