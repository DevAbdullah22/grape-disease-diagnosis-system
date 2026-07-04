import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter_application_55555/core/services/fcm_service.dart';
import 'package:flutter_application_55555/features/diagnosis/presentation/screens/diagnosis_screen.dart';
import 'package:flutter_application_55555/features/diagnosis/presentation/screens/diagnosis_details_plan_screen.dart';
import 'package:flutter_application_55555/features/diagnosis/presentation/screens/treatment_execution_screen.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/diagnose.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/get_reference_images.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/get_diagnosis_details.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/get_treatment_recommendation.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/execute_treatment_step.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/get_diagnosis_history.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/sync_backend_user.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/get_diagnosis_plan_details.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/execute_treatment_step_with_result.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/log_treatment_reminder_notification.dart';
import 'package:flutter_application_55555/features/notifications/presentation/injection/notifications_injection.dart';
import 'package:flutter_application_55555/features/library/presentation/screen/library_screen.dart';
import 'package:flutter_application_55555/features/profile/presentation/screens/profile_screen.dart';
import 'package:flutter_application_55555/features/weather/presentation/screens/weather_screen.dart';
import 'package:flutter_application_55555/features/app/presentation/screens/main_navigation_screen.dart';
import 'package:flutter_application_55555/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter_application_55555/features/auth/presentation/screens/register_screen.dart';
import 'package:flutter_application_55555/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:flutter_application_55555/features/library/domain/usecases/get_library_categories.dart';
import 'package:flutter_application_55555/features/library/domain/usecases/get_library_favorites.dart';
import 'package:flutter_application_55555/features/library/domain/usecases/get_library_item.dart';
import 'package:flutter_application_55555/features/library/domain/usecases/get_library_items.dart';
import 'package:flutter_application_55555/features/library/domain/usecases/get_library_items_by_category.dart';
import 'package:flutter_application_55555/features/library/domain/usecases/resolve_library_image_url.dart';
import 'package:flutter_application_55555/features/library/domain/usecases/toggle_library_favorite.dart';

import 'core/service_locator.dart';

/// ===========================================
/// 🔥 1) Background handler
/// ===========================================
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📩 Background FCM received: ${message.messageId}');
}

/// ===========================================
/// 🔥 2) MAIN
/// ===========================================
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Forward Flutter framework errors to console
  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
  };

  // Run guarded zone to catch uncaught async errors
  runZonedGuarded(
    () async {
      await Firebase.initializeApp();

      // Register background handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Init DI
      await initLocator();

      // Notification permissions (best-effort)
      try {
        if (Platform.isAndroid) {
          final status = await Permission.notification.status;
          if (status.isDenied) {
            await Permission.notification.request();
          }
        }
      } catch (_) {}

      try {
        if (Platform.isIOS) {
          await FirebaseMessaging.instance.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );
        }
      } catch (_) {}

      // Initialize local notifications channel
      try {
        final flutterLocalNotificationsPlugin =
            FlutterLocalNotificationsPlugin();
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'high_importance_channel',
          'High Importance Notifications',
          description: 'Used for important notifications',
          importance: Importance.max,
        );
        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(channel);

        // initialize local notifications with tap handler
        await flutterLocalNotificationsPlugin.initialize(
          const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          ),
          onDidReceiveNotificationResponse: (NotificationResponse resp) {
            final payload = resp.payload;
            if (payload == 'notifications') {
              navigatorKey.currentState?.pushNamed('/notifications');
            }
          },
          onDidReceiveBackgroundNotificationResponse: null,
        );

        // Foreground FCM Listener (safe to register)
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          // ignore: avoid_print
          print('📬 Foreground FCM received: ${message.messageId}');
          if (message.notification != null) {
            final payload = (message.data['screen'] == 'notifications')
                ? 'notifications'
                : null;
            flutterLocalNotificationsPlugin.show(
              message.hashCode,
              message.notification!.title,
              message.notification!.body,
              NotificationDetails(
                android: AndroidNotificationDetails(
                  'high_importance_channel',
                  'High Importance Notifications',
                  importance: Importance.max,
                  icon: '@mipmap/ic_launcher',
                ),
              ),
              payload: payload,
            );
          }
        });

        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          // ignore: avoid_print
          print('📥 App opened from FCM: ${message.data}');
          final data = message.data;
          final screen = data['Screen'] ?? data['screen'];
          final diagnosisId =
              data['DiagnosisId'] ?? data['diagnosisId'] ?? data['relatedId'];
          if (screen != null) {
            if (screen == 'notifications') {
              navigatorKey.currentState?.pushNamed('/notifications');
              return;
            }
          }
          if (screen != null && diagnosisId != null) {
            if (screen == 'treatment_execution') {
              navigatorKey.currentState?.pushNamed(
                '/treatment_execution',
                arguments: {'diagnosisId': diagnosisId.toString()},
              );
            } else if (screen == 'diagnosis_details' ||
                screen == 'treatment_plan') {
              navigatorKey.currentState?.pushNamed(
                '/diagnosis_details',
                arguments: {'diagnosisId': diagnosisId.toString()},
              );
            }
          }
        });
      } catch (_) {}

      // Auth-state listener
      try {
        FirebaseAuth.instance.authStateChanges().listen((user) async {
          if (user != null) {
            // ignore: avoid_print
            print("🔑 User logged in → Sending FCM token...");
            await FcmService.sendFcmTokenToBackend();
          }
        });
      } catch (_) {}

      runApp(const MyApp());

      // Handle terminated state (app opened from a notification when closed)
      FirebaseMessaging.instance.getInitialMessage().then((message) {
        if (message != null) {
          final data = message.data;
          final screen = data['Screen'] ?? data['screen'];
          final diagnosisId =
              data['DiagnosisId'] ?? data['diagnosisId'] ?? data['relatedId'];
          if (screen != null && diagnosisId != null) {
            if (screen == 'treatment_execution') {
              navigatorKey.currentState?.pushNamed(
                '/treatment_execution',
                arguments: {'diagnosisId': diagnosisId.toString()},
              );
            } else if (screen == 'diagnosis_details' ||
                screen == 'treatment_plan') {
              navigatorKey.currentState?.pushNamed(
                '/diagnosis_details',
                arguments: {'diagnosisId': diagnosisId.toString()},
              );
            }
          }
        }
      });
    },
    (error, stack) {
      // Log uncaught errors from the zone
      // ignore: avoid_print
      print('UNCAUGHT ERROR: $error');
      // ignore: avoid_print
      print(stack);
    },
  );
}

/// ===========================================
/// 🔥 APP ROOT
/// ===========================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<Diagnose>.value(value: locator<Diagnose>()),
        RepositoryProvider<GetReferenceImages>.value(
          value: locator<GetReferenceImages>(),
        ),
        RepositoryProvider<GetDiagnosisDetails>.value(
          value: locator<GetDiagnosisDetails>(),
        ),
        RepositoryProvider<GetTreatmentRecommendation>.value(
          value: locator<GetTreatmentRecommendation>(),
        ),
        RepositoryProvider<ExecuteTreatmentStep>.value(
          value: locator<ExecuteTreatmentStep>(),
        ),
        RepositoryProvider<GetDiagnosisHistory>.value(
          value: locator<GetDiagnosisHistory>(),
        ),
        RepositoryProvider<SyncBackendUser>.value(
          value: locator<SyncBackendUser>(),
        ),
        RepositoryProvider<GetDiagnosisPlanDetails>.value(
          value: locator<GetDiagnosisPlanDetails>(),
        ),
        RepositoryProvider<ExecuteTreatmentStepWithResult>.value(
          value: locator<ExecuteTreatmentStepWithResult>(),
        ),
        RepositoryProvider<LogTreatmentReminderNotification>.value(
          value: locator<LogTreatmentReminderNotification>(),
        ),
        RepositoryProvider<GetLibraryItems>.value(
          value: locator<GetLibraryItems>(),
        ),
        RepositoryProvider<GetLibraryItem>.value(
          value: locator<GetLibraryItem>(),
        ),
        RepositoryProvider<GetLibraryItemsByCategory>.value(
          value: locator<GetLibraryItemsByCategory>(),
        ),
        RepositoryProvider<GetLibraryCategories>.value(
          value: locator<GetLibraryCategories>(),
        ),
        RepositoryProvider<GetLibraryFavorites>.value(
          value: locator<GetLibraryFavorites>(),
        ),
        RepositoryProvider<ToggleLibraryFavorite>.value(
          value: locator<ToggleLibraryFavorite>(),
        ),
        RepositoryProvider<ResolveLibraryImageUrl>.value(
          value: locator<ResolveLibraryImageUrl>(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        home: const FcmLifecycleHandler(child: AuthGate()),
        debugShowCheckedModeBanner: false,
        routes: {
          '/login': (ctx) => const LoginScreen(),
          '/signup': (ctx) => SignUpScreen(),
          '/forgot': (ctx) => const ForgotPasswordScreen(),
          '/home': (ctx) => const MainNavigationScreen(),
          '/diagnosis': (ctx) => const DiagnosisScreen(),
          '/diagnosis_details': (ctx) {
            final args =
                ModalRoute.of(ctx)?.settings.arguments as Map<String, dynamic>?;
            final id = args != null
                ? args['diagnosisId']?.toString() ?? ''
                : '';
            return DiagnosisDetailsPlanScreen(diagnosisId: id);
          },
          '/treatment_execution': (ctx) {
            final args =
                ModalRoute.of(ctx)?.settings.arguments as Map<String, dynamic>?;
            final id = args != null
                ? args['diagnosisId']?.toString() ?? ''
                : '';
            return TreatmentExecutionScreen(diagnosisId: id);
          },
          '/notifications': (ctx) => buildNotificationsScreen(),
          '/library': (ctx) => const LibraryScreen(),
          '/profile': (ctx) => const ProfileScreen(),
          '/weather': (ctx) => const WeatherScreen(),
        },
      ),
    );
  }
}

/// A small widget that ensures we check/send the FCM token on app start and
/// every time the app returns to the foreground (resumed). This helps ensure
/// the backend has the up-to-date token even after device/emulator restarts.
class FcmLifecycleHandler extends StatefulWidget {
  final Widget child;
  const FcmLifecycleHandler({required this.child, super.key});

  @override
  State<FcmLifecycleHandler> createState() => _FcmLifecycleHandlerState();
}

class _FcmLifecycleHandlerState extends State<FcmLifecycleHandler>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Ensure token is checked/sent at app start
    _checkAndSendToken();
  }

  Future<void> _checkAndSendToken() async {
    try {
      // ignore: avoid_print
      print('🔎 Checking FCM token on app start/resume...');
      await FcmService.sendFcmTokenToBackend();
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error while checking/sending FCM token: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndSendToken();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// ===========================================
/// 🔥 AUTH GATE
/// ===========================================
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const MainNavigationScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
