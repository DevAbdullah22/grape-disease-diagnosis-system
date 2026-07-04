import 'dart:io';
import 'package:flutter_application_55555/core/services/config.dart';
import 'package:flutter_application_55555/core/services/backend_service.dart';
import 'package:flutter_application_55555/features/diagnosis/presentation/cubit/diagnosis_details_cubit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_application_55555/core/api_client.dart';
import 'package:flutter_application_55555/core/weather_service.dart';
import 'package:flutter_application_55555/features/diagnosis/data/datasources/diagnosis_remote_datasource.dart';
import 'package:flutter_application_55555/features/diagnosis/data/repositories_impl/diagnosis_repository_impl.dart';
import 'package:flutter_application_55555/features/diagnosis/data/datasources/diagnosis_local_data_source.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/repositories/diagnosis_repository.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/diagnose.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/get_reference_images.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/get_diagnosis_details.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/get_treatment_recommendations.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/get_treatment_recommendation.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/execute_treatment_step.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/get_diagnosis_history.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/get_last_diagnosis.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/sync_backend_user.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/get_diagnosis_plan_details.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/execute_treatment_step_with_result.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/log_treatment_reminder_notification.dart';
import 'package:flutter_application_55555/features/library/data/datasources/library_image_resolver_datasource.dart';
import 'package:flutter_application_55555/features/library/data/datasources/library_local_datasource.dart';
import 'package:flutter_application_55555/features/library/data/datasources/library_remote_datasource.dart';
import 'package:flutter_application_55555/features/notifications/data/datasources/notifications_remote_datasource.dart';
import 'package:flutter_application_55555/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:flutter_application_55555/features/library/domain/repositories/library_repository.dart';
import 'package:flutter_application_55555/features/library/data/repositories_impl/library_repository_impl.dart';
import 'package:flutter_application_55555/features/library/domain/usecases/get_library_favorites.dart';
import 'package:flutter_application_55555/features/library/domain/usecases/get_library_items.dart';
import 'package:flutter_application_55555/features/library/domain/usecases/get_library_item.dart';
import 'package:flutter_application_55555/features/library/domain/usecases/get_library_items_by_category.dart';
import 'package:flutter_application_55555/features/library/domain/usecases/get_library_categories.dart';
import 'package:flutter_application_55555/features/library/domain/usecases/resolve_library_image_url.dart';
import 'package:flutter_application_55555/features/library/domain/usecases/toggle_library_favorite.dart';
import 'package:flutter_application_55555/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:flutter_application_55555/features/notifications/data/repositories/notifications_repository_impl.dart';
import 'package:flutter_application_55555/features/notifications/domain/usecases/get_notifications.dart';
import 'package:flutter_application_55555/features/notifications/domain/usecases/get_unread_notifications_count.dart';
import 'package:flutter_application_55555/features/profile/domain/repositories/profile_repository.dart';
import 'package:flutter_application_55555/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:flutter_application_55555/features/profile/domain/usecases/get_profile.dart';

final GetIt locator = GetIt.instance;

const String _openWeatherApiKey = String.fromEnvironment('OPENWEATHER_API_KEY');

Future<void> initLocator({String? baseUrl}) async {
  // use Config.apiBaseUrl when caller does not provide one (cannot use it as a
  // default parameter because it's not a const)
  final String resolvedBaseUrl = baseUrl ?? Config.apiBaseUrl;
  // Register core
  locator.registerLazySingleton<ApiClient>(() => ApiClient(resolvedBaseUrl));
  // Weather service (OpenWeatherMap)
  locator.registerLazySingleton<WeatherService>(() {
    // default language code based on device locale (only the language part)
    String lang = 'ar';
    try {
      lang = Platform.localeName.split('_').first;
    } catch (_) {}
    return WeatherService(
      apiKey: _openWeatherApiKey,
      defaultLang: lang,
    );
  });
  locator.registerLazySingleton<BackendService>(
    () => BackendService(baseUrl: resolvedBaseUrl),
  );

  // Data sources
  locator.registerLazySingleton<DiagnosisRemoteDataSource>(
    () => DiagnosisRemoteDataSource(locator<ApiClient>()),
  );
  locator.registerLazySingleton<DiagnosisLocalDataSource>(
    () =>
        DiagnosisLocalDataSourceImpl(backendService: locator<BackendService>()),
  );
  locator.registerLazySingleton<LibraryRemoteDataSource>(
    () => LibraryRemoteDataSource(locator<ApiClient>()),
  );
  locator.registerLazySingleton<LibraryLocalDataSource>(
    () => LibraryLocalDataSourceImpl(firebaseAuth: FirebaseAuth.instance),
  );
  locator.registerLazySingleton<LibraryImageResolverDataSource>(
    () => LibraryImageResolverDataSourceImpl(locator<ApiClient>()),
  );
  locator.registerLazySingleton<NotificationsRemoteDataSource>(
    () => NotificationsRemoteDataSource(locator<ApiClient>()),
  );
  locator.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSource(locator<ApiClient>()),
  );

  // Repositories (register as interface type)
  locator.registerLazySingleton<DiagnosisRepository>(
    () => DiagnosisRepositoryImpl(
      locator<DiagnosisRemoteDataSource>(),
      locator<DiagnosisLocalDataSource>(),
    ),
  );
  locator.registerLazySingleton<LibraryRepository>(
    () => LibraryRepositoryImpl(
      remote: locator<LibraryRemoteDataSource>(),
      local: locator<LibraryLocalDataSource>(),
      imageResolver: locator<LibraryImageResolverDataSource>(),
    ),
  );
  locator.registerLazySingleton<NotificationsRepository>(
    () => NotificationsRepositoryImpl(locator<NotificationsRemoteDataSource>()),
  );
  locator.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(locator<ProfileRemoteDataSource>()),
  );

  // Usecases (Diagnose requires a DiagnosisRepository)
  locator.registerLazySingleton<Diagnose>(
    () => Diagnose(locator<DiagnosisRepository>()),
  );
  locator.registerLazySingleton<GetReferenceImages>(
    () => GetReferenceImages(locator<DiagnosisRepository>()),
  );
  locator.registerLazySingleton<GetDiagnosisDetails>(
    () => GetDiagnosisDetails(locator<DiagnosisRepository>()),
  );

  // Cubits
  locator.registerFactory<DiagnosisDetailsCubit>(
    () => DiagnosisDetailsCubit(locator<GetDiagnosisDetails>()),
  );
  locator.registerLazySingleton<GetTreatmentRecommendations>(
    () => GetTreatmentRecommendations(locator<DiagnosisRepository>()),
  );
  locator.registerLazySingleton<GetTreatmentRecommendation>(
    () => GetTreatmentRecommendation(locator<DiagnosisRepository>()),
  );
  locator.registerLazySingleton<ExecuteTreatmentStep>(
    () => ExecuteTreatmentStep(locator<DiagnosisRepository>()),
  );
  locator.registerLazySingleton<ExecuteTreatmentStepWithResult>(
    () => ExecuteTreatmentStepWithResult(locator<DiagnosisRepository>()),
  );
  locator.registerLazySingleton<GetDiagnosisPlanDetails>(
    () => GetDiagnosisPlanDetails(locator<DiagnosisRepository>()),
  );
  locator.registerLazySingleton<GetDiagnosisHistory>(
    () => GetDiagnosisHistory(locator<DiagnosisRepository>()),
  );
  locator.registerLazySingleton<GetLastDiagnosis>(
    () => GetLastDiagnosis(locator<DiagnosisRepository>()),
  );
  locator.registerLazySingleton<SyncBackendUser>(
    () => SyncBackendUser(locator<DiagnosisRepository>()),
  );
  locator.registerLazySingleton<LogTreatmentReminderNotification>(
    () => LogTreatmentReminderNotification(locator<DiagnosisRepository>()),
  );
  locator.registerLazySingleton<GetLibraryItems>(
    () => GetLibraryItems(locator<LibraryRepository>()),
  );
  locator.registerLazySingleton<GetLibraryItem>(
    () => GetLibraryItem(locator<LibraryRepository>()),
  );
  locator.registerLazySingleton<GetLibraryItemsByCategory>(
    () => GetLibraryItemsByCategory(locator<LibraryRepository>()),
  );
  locator.registerLazySingleton<GetLibraryCategories>(
    () => GetLibraryCategories(locator<LibraryRepository>()),
  );
  locator.registerLazySingleton<GetLibraryFavorites>(
    () => GetLibraryFavorites(locator<LibraryRepository>()),
  );
  locator.registerLazySingleton<ToggleLibraryFavorite>(
    () => ToggleLibraryFavorite(locator<LibraryRepository>()),
  );
  locator.registerLazySingleton<ResolveLibraryImageUrl>(
    () => ResolveLibraryImageUrl(locator<LibraryRepository>()),
  );
  locator.registerLazySingleton<GetNotifications>(
    () => GetNotifications(locator<NotificationsRepository>()),
  );
  locator.registerLazySingleton<GetUnreadNotificationsCount>(
    () => GetUnreadNotificationsCount(locator<NotificationsRepository>()),
  );
  locator.registerLazySingleton<GetProfile>(
    () => GetProfile(locator<ProfileRepository>()),
  );
}
