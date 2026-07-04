import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_55555/core/weather_service.dart';
import 'package:flutter_application_55555/core/service_locator.dart';
import 'package:flutter_application_55555/core/contracts/app_runtime_contract.dart';
import 'package:flutter_application_55555/core/services/backend_service.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/get_diagnosis_details.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/get_last_diagnosis.dart';
import 'package:flutter_application_55555/features/library/domain/entities/library_item.dart';
import 'package:flutter_application_55555/features/library/domain/usecases/get_library_items.dart';
import 'package:flutter_application_55555/features/notifications/domain/usecases/get_unread_notifications_count.dart';

import 'dart:convert';
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_55555/features/library/presentation/screen/library_item_details_screen.dart';
import 'package:flutter_application_55555/features/diagnosis/presentation/cubit/diagnosis_details_cubit.dart';
import 'package:flutter_application_55555/features/diagnosis/presentation/screens/diagnosis_details_screen.dart';
import 'package:flutter_application_55555/features/notifications/presentation/injection/notifications_injection.dart';
import 'package:flutter_application_55555/features/weather/presentation/screens/weather_screen.dart';
import 'package:flutter_application_55555/features/diagnosis/presentation/screens/agricultural_record_screen.dart';
import 'package:flutter_application_55555/features/app/presentation/screens/main_navigation_screen.dart';

import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_55555/features/home/presentation/widgets/home/home_weather_card.dart';
import 'package:flutter_application_55555/features/home/presentation/widgets/home/home_main_actions_grid.dart';
import 'package:flutter_application_55555/features/home/presentation/widgets/home/home_favorites_section.dart';
import 'package:flutter_application_55555/features/home/presentation/widgets/home/home_last_diagnosis_section.dart';
import 'package:flutter_application_55555/features/home/presentation/widgets/home/home_greeting_section.dart';

/// الشاشة الرئيسية - تصميم متجاوب ودعم العربية وحالات التحميل والأخطاء
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

void checkFcmToken() async {
  final token = await FirebaseMessaging.instance.getToken();
  print("ðŸ”¥ FCM TOKEN FROM DEVICE: $token");
}

class _HomeScreenState extends State<HomeScreen> {
  WeatherInfo? _weather;
  bool _isUsingDefault = false;
  bool _loadingWeather = true;
  String? _weatherError;
  // favorite items loaded from SharedPreferences
  List<LibraryItem> _favoriteItems = [];

  // unread notifications count for badge
  int _unreadNotifications = 0;

  // listen to Firebase auth state changes to clear or reload per-user local data
  StreamSubscription<User?>? _authSubscription;

  // متغيرات نتيجة التشخيص الأخيرة (من الباك اند)
  String? _lastDiagnosisDisease;
  double? _lastDiagnosisConfidence;
  String? _lastDiagnosisImage;
  String? _lastDiagnosisDate;
  String? _lastDiagnosisId;

  @override
  void initState() {
    super.initState();
    _loadDefaultLocationFromPrefs();
    _loadFavoriteItems();
    _loadUnreadNotifications();
    // determine which tab index corresponds to Home and listen for changes
    // so favorites are refreshed when returning to this tab.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _myTabIndex = Directionality.of(context) == TextDirection.rtl ? 3 : 0;
      mainNavController.addListener(_onMainNavChanged);
    });
    _loadLastDiagnosis();

    // subscribe to auth state changes to clear per-user persisted data on sign-out
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      _handleAuthChange,
    );
  }

  Future<void> _loadUnreadNotifications() async {
    try {
      if (!locator.isRegistered<GetUnreadNotificationsCount>()) {
        await initLocator();
      }
      final backendId = await _resolveBackendUserId();
      if (backendId == null || backendId.isEmpty) {
        if (mounted) setState(() => _unreadNotifications = 0);
        return;
      }

      final service = locator.get<GetUnreadNotificationsCount>();
      final unread = await service.call(backendId);
      if (mounted) {
        setState(() => _unreadNotifications = unread < 0 ? 0 : unread);
      }
    } catch (_) {
      // ignore errors silently
    }
  }

  Future<String?> _resolveBackendUserId() async {
    final prefs = await SharedPreferences.getInstance();
    var backendId = prefs.getString(AppRuntimeContract.backendUserIdKey);
    if (backendId != null && backendId.isNotEmpty) return backendId;

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return null;

    try {
      await BackendService().sendUserToBackend(firebaseUser: firebaseUser);
      backendId = prefs.getString(AppRuntimeContract.backendUserIdKey);
    } catch (_) {
      // ignore; caller will handle missing id
    }
    return backendId;
  }

  late int _myTabIndex;

  void _onMainNavChanged() {
    if (!mounted) return;
    if (mainNavController.index == _myTabIndex) {
      _loadFavoriteItems();
      // reload last diagnosis and unread notifications when returning to Home
      _loadLastDiagnosis();
      _loadUnreadNotifications();
    }
  }

  @override
  void dispose() {
    try {
      mainNavController.removeListener(_onMainNavChanged);
    } catch (_) {}
    try {
      _authSubscription?.cancel();
    } catch (_) {}
    super.dispose();
  }

  Future<void> _removeFromFavorites(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final favKey = AppRuntimeContract.libraryFavoritesKey(uid);
      final ids = prefs.getStringList(favKey) ?? <String>[];
      ids.remove(id);
      await prefs.setStringList(favKey, ids);
      if (mounted) {
        setState(() {
          _favoriteItems.removeWhere((it) => it.id == id);
        });
      }
    } catch (_) {}
  }

  Future<void> _loadLastDiagnosis() async {
    try {
      if (!locator.isRegistered<GetLastDiagnosis>()) {
        await initLocator();
      }
      if (!locator.isRegistered<GetDiagnosisDetails>()) {
        await initLocator();
      }

      final prefs = await SharedPreferences.getInstance();
      final backendId = prefs.getString(AppRuntimeContract.backendUserIdKey);
      final lastService = locator.get<GetLastDiagnosis>();
      final detailsService = locator.get<GetDiagnosisDetails>();

      final last = await lastService.call(userId: backendId);
      if (!mounted) return;

      if (last == null ||
          last.diagnosisId == null ||
          last.diagnosisId!.isEmpty) {
        setState(() {
          _lastDiagnosisDisease = null;
          _lastDiagnosisConfidence = null;
          _lastDiagnosisImage = null;
          _lastDiagnosisDate = null;
          _lastDiagnosisId = null;
        });
        return;
      }

      DateTime? parseIso(String? value) {
        if (value == null || value.isEmpty) return null;
        var input = value;
        if (!input.endsWith('Z') &&
            !input.contains('+') &&
            !input.contains('-')) {
          input = '${input}Z';
        }
        try {
          return DateTime.parse(input).toLocal();
        } catch (_) {
          return null;
        }
      }

      final selectedIso =
          (last.diagnosisDate != null && last.diagnosisDate!.isNotEmpty)
          ? last.diagnosisDate
          : last.date;
      final parsedDate = parseIso(selectedIso);
      final formattedDate = (parsedDate != null && parsedDate.year > 1)
          ? '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}'
          : null;

      final detailsResult = await detailsService.call(last.diagnosisId!);
      if (!mounted) return;

      detailsResult.fold(
        (_) {
          setState(() {
            _lastDiagnosisDisease = last.diseaseName;
            _lastDiagnosisConfidence = null;
            _lastDiagnosisImage = last.imageUrl;
            _lastDiagnosisDate = formattedDate;
            _lastDiagnosisId = last.diagnosisId;
          });
        },
        (details) {
          setState(() {
            _lastDiagnosisDisease = details.diseaseName;
            _lastDiagnosisConfidence = details.confidence;
            _lastDiagnosisImage = details.imageUrl;
            _lastDiagnosisDate = formattedDate;
            _lastDiagnosisId = last.diagnosisId;
          });
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _lastDiagnosisDisease = null;
        _lastDiagnosisConfidence = null;
        _lastDiagnosisImage = null;
        _lastDiagnosisDate = null;
        _lastDiagnosisId = null;
      });
    }
  }

  // Handlers used by the extracted widgets (preserve original logic but keep UI in widgets)
  Future<void> _onWeatherCardTap() async {
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(builder: (_) => const WeatherScreen()),
    );
    if (!mounted) return;
    if (result != null) {
      final lat = (result['lat'] is num)
          ? (result['lat'] as num).toDouble()
          : double.tryParse(result['lat']?.toString() ?? '');
      final lon = (result['lon'] is num)
          ? (result['lon'] as num).toDouble()
          : double.tryParse(result['lon']?.toString() ?? '');
      final name = result['name']?.toString();
      if (lat != null && lon != null) {
        // Ask whether to set as default before changing the home card.
        final shouldSave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('تعيين كموقع افتراضي؟'),
            content: Text(
              'هل تريد حفظ "${name ?? 'الموقع المحدد'}" كموقع افتراضي؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('لا'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('نعم'),
              ),
            ],
          ),
        );

        if (shouldSave == true) {
          // user confirmed -> update card and persist default
          await _setWeatherForCoords(lat, lon, name: name);
          await _saveDefaultLocation(
            result['id']?.toString(),
            lat,
            lon,
            name: name,
          );
        } else {
          // user declined -> do nothing (keep existing home card)
        }
      }
    }
  }

  void _onMainCardTapped(String label) {
    if (label == 'التشخيص') {
      final isRtl = Directionality.of(context) == TextDirection.rtl;
      final diagIndex = isRtl ? 2 : 1;
      mainNavController.jumpToTab(diagIndex);
      return;
    }
    if (label == 'المكتبة') {
      final isRtl = Directionality.of(context) == TextDirection.rtl;
      final libIndex = isRtl ? 1 : 2;
      mainNavController.jumpToTab(libIndex);
      return;
    }
    if (label == 'السجل') {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء تسجيل الدخول لعرض السجل')),
        );
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AgriculturalRecordScreen(userId: uid),
        ),
      );
      return;
    }
    if (label == 'الإشعارات') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => buildNotificationsScreen()));
      return;
    }
  }

  void _onFavoriteViewAll() {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final libIndex = isRtl ? 1 : 2;
    mainNavController.jumpToTab(libIndex);
  }

  void _onFavoriteItemTap(LibraryItem item) {
    if (item.id.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LibraryItemDetailsScreen(id: item.id),
        ),
      );
    }
  }

  // Handle Firebase auth state changes: clear per-user local data on sign-out
  // and reload per-user data on sign-in.
  Future<void> _handleAuthChange(User? user) async {
    if (user == null) {
      // User signed out: clear in-memory state only. Persisted values are
      // stored per-user (UID-scoped) so they should remain for their owners.
      if (mounted) {
        setState(() {
          _favoriteItems = [];
          _lastDiagnosisDisease = null;
          _lastDiagnosisConfidence = null;
          _lastDiagnosisImage = null;
          _lastDiagnosisDate = null;
          _unreadNotifications = 0;
        });
      }
    } else {
      // user signed in: reload per-user persisted data
      await _loadFavoriteItems();
      await _loadLastDiagnosis();
      await _loadUnreadNotifications();
    }
  }

  /// Persist selected location as the default location shown on the home card.
  Future<void> _saveDefaultLocation(
    String? id,
    double lat,
    double lon, {
    String? name,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final key = AppRuntimeContract.weatherDefaultLocationKey(uid);
      final payload = json.encode({
        'id': id ?? '',
        'lat': lat,
        'lon': lon,
        'name': name ?? '',
      });
      await prefs.setString(key, payload);
      setState(() {
        _isUsingDefault = true;
      });
    } catch (_) {}
  }

  /// Load default location from prefs and set weather for it; otherwise fall back to current-location fetch.
  Future<void> _loadDefaultLocationFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final key = AppRuntimeContract.weatherDefaultLocationKey(uid);
      final raw = prefs.getString(key);
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> data =
            json.decode(raw) as Map<String, dynamic>;
        final lat = (data['lat'] as num?)?.toDouble();
        final lon = (data['lon'] as num?)?.toDouble();
        final name = data['name']?.toString();
        if (lat != null && lon != null) {
          await _setWeatherForCoords(lat, lon, name: name);
          setState(() {
            _isUsingDefault = true;
          });
          return;
        }
      }
    } catch (_) {}
    await _fetchWeather();
  }

  Future<void> _loadFavoriteItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final favKey = AppRuntimeContract.libraryFavoritesKey(uid);
      final ids = prefs.getStringList(favKey) ?? <String>[];
      if (ids.isEmpty) {
        if (mounted) setState(() => _favoriteItems = []);
        return;
      }
      // ensure DI/usecase available
      if (!locator.isRegistered<GetLibraryItems>()) {
        await initLocator();
      }
      final items = await locator.get<GetLibraryItems>().call();
      final favs = items.where((it) => ids.contains(it.id)).toList();
      if (mounted) setState(() => _favoriteItems = favs);
    } catch (e) {
      // ignore errors
    }
  }

  Future<void> _fetchWeather() async {
    _loadingWeather = true;
    _weatherError = null;
    _isUsingDefault = false;
    if (mounted) setState(() {});

    try {
      // Ensure locator is initialized (handles cases where app was hot-reloaded
      // or initLocator() wasn't run yet).
      if (!locator.isRegistered<WeatherService>()) {
        await initLocator();
      }
      // Check location services
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _weatherError = 'خدمة الموقع معطلة. الرجاء تفعيل خدمة الموقع.';
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _weatherError = 'تم رفض صلاحية الموقع.';
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _weatherError =
                'صلاحية الموقع مرفوضة نهائياً. الرجاء تمكينها من إعدادات التطبيق.';
          });
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final service = sl.get<WeatherService>();
      final info = await service.fetchCurrentWeatherByCoords(
        position.latitude,
        position.longitude,
      );
      if (mounted) {
        setState(() {
          _weather = info;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _weatherError = e.toString();
        });
      }
    } finally {
      _loadingWeather = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _openLocationSettingsAndRetry() async {
    try {
      // Open the device location settings so user can enable location services
      await Geolocator.openLocationSettings();
    } catch (_) {}

    // After opening settings the user may enable location there. The OS
    // does not notify the app when the user flips the toggle, so poll for
    // the service to become enabled for a short period and then retry.
    const timeout = Duration(seconds: 12);
    const interval = Duration(milliseconds: 700);
    final start = DateTime.now();
    while (DateTime.now().difference(start) < timeout) {
      try {
        final enabled = await Geolocator.isLocationServiceEnabled();
        if (enabled) {
          await _fetchWeather();
          return;
        }
      } catch (_) {}
      await Future.delayed(interval);
    }

    // Final attempt after timeout (will set an error message if still disabled).
    await _fetchWeather();
  }

  /// Fetch and show weather for specific coordinates (used when user selects a saved location)
  Future<void> _setWeatherForCoords(
    double lat,
    double lon, {
    String? name,
  }) async {
    _loadingWeather = true;
    _weatherError = null;
    if (mounted) setState(() {});

    try {
      final service = sl.get<WeatherService>();
      final info = await service.fetchCurrentWeatherByCoords(lat, lon);
      if (mounted) {
        setState(() {
          // if caller provided a custom name, use it; otherwise keep API city
          _weather = (name != null && name.isNotEmpty)
              ? WeatherInfo(
                  city: name,
                  tempC: info.tempC,
                  description: info.description,
                  humidity: info.humidity,
                  icon: info.icon,
                  lat: info.lat,
                  lon: info.lon,
                )
              : info;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _weatherError = e.toString();
        });
      }
    } finally {
      _loadingWeather = false;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // build UI
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFEFFEF8),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(61),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0x1A000000), width: 0.8),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.menu, color: Colors.green),
                        onPressed: () {},
                      ),
                    ),
                    const Text(
                      'تشخيص أمراض العنب',
                      style: TextStyle(
                        color: Color(0xFF016630),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.search, color: Colors.green),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                HomeGreetingSection(
                  name: (() {
                    final u = FirebaseAuth.instance.currentUser;
                    if (u == null) return null;
                    final dn = u.displayName;
                    if (dn != null && dn.trim().isNotEmpty) return dn.trim();
                    final em = u.email;
                    if (em != null && em.contains('@'))
                      return em.split('@').first;
                    return null;
                  })(),
                ),
                HomeWeatherCard(
                  loading: _loadingWeather,
                  error: _weatherError,
                  weather: _weather,
                  isUsingDefault: _isUsingDefault,
                  onTap: _onWeatherCardTap,
                  onRetry: _fetchWeather,
                  onOpenLocationSettings: _openLocationSettingsAndRetry,
                ),
                const SizedBox(height: 24),
                HomeMainActionsGrid(
                  onAction: _onMainCardTapped,
                  notificationsCount: _unreadNotifications,
                ),
                const SizedBox(height: 24),
                HomeFavoritesSection(
                  favoriteItems: _favoriteItems,
                  onViewAll: _onFavoriteViewAll,
                  onRemove: (id) => _removeFromFavorites(id),
                  onTapItem: _onFavoriteItemTap,
                ),
                const SizedBox(height: 24),
                HomeLastDiagnosisSection(
                  disease: _lastDiagnosisDisease,
                  confidence: _lastDiagnosisConfidence,
                  image: _lastDiagnosisImage,
                  date: _lastDiagnosisDate,
                  onViewDetails: () async {
                    if (_lastDiagnosisId == null || _lastDiagnosisId!.isEmpty)
                      return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) {
                          final cubit = locator<DiagnosisDetailsCubit>();
                          cubit.fetch(_lastDiagnosisId!);
                          return DiagnosisDetailsScreen(
                            cubit: cubit,
                            diagnosisId: _lastDiagnosisId!,
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
