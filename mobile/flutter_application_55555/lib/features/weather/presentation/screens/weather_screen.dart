import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_application_55555/core/api_client.dart';
import 'package:flutter_application_55555/core/weather_service.dart';
import 'package:flutter_application_55555/features/weather/application/weather_controller.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';


import 'package:get_it/get_it.dart';
import 'package:flutter_application_55555/features/weather/presentation/widgets/weather_farm_card.dart';
import 'package:flutter_application_55555/features/weather/presentation/screens/select_farm_location_screen.dart';
final sl = GetIt.instance;

/// Model used locally for saved weather/farm locations.
/// `id` can be a server GUID (when synced) or a local key.
class SavedLocation {
  String id; // mutable so we can replace temporary id with server id after sync
  final String name;
  final double lat;
  final double lon;
  final String? notes;
  final DateTime createdAt;

  SavedLocation({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lat': lat,
        'lon': lon,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SavedLocation.fromJson(Map<String, dynamic> json) => SavedLocation(
        id: json['id'] ?? UniqueKey().toString(),
        name: json['name'] ?? '',
        lat: (json['lat'] as num).toDouble(),
        lon: (json['lon'] as num).toDouble(),
        notes: json['notes']?.toString(),
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
                ?? DateTime.now()
            : DateTime.now(),
      );

  factory SavedLocation.fromBackendJson(Map<String, dynamic> json) =>
      SavedLocation(
        id: (json['id'] ?? json['Id'] ?? UniqueKey().toString()).toString(),
        name: (json['name'] ?? json['Name'] ?? json['name_en'] ?? '')
            .toString(),
        lat:
            ((json['latitude'] ?? json['Latitude'] ?? json['lat']) as num?)
                ?.toDouble() ??
            0.0,
        lon:
            ((json['longitude'] ?? json['Longitude'] ?? json['lon']) as num?)
                ?.toDouble() ??
            0.0,
        notes: json['notes']?.toString(),
      );
}

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController _searchController = TextEditingController();
  final WeatherService _service = sl.get<WeatherService>();
  late final WeatherController _controller;

  List<SavedLocation> _locations = [];
  String? _defaultLocationId;
  final Map<String, WeatherInfo?> _weatherCache = {};
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WeatherController(
      apiClient: sl.get<ApiClient>(),
      firebaseAuth: FirebaseAuth.instance,
    );
    _loadSavedLocations();
  }

  /// If this is first run and no saved locations exist, offer to add current location.
  Future<void> _maybeOfferAddCurrentOnFirstRun() async {
    if (_locations.isNotEmpty) return;
    // give the UI a moment to settle
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('إضافة مزرعة جديدة'),
          content: const Text('هل تريد إضافة موقعك الحالي كمزرعتك الأولى؟'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('لا')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('نعم')),
          ],
        );
      },
    );
    if (confirm == true) {
      await _addCurrentLocation();
    }
  }

  /// Load locally-saved locations then try to merge with server farms (if
  /// the user is registered on the backend). Merged list is cached locally.
  Future<void> _loadSavedLocations() async {
    // 1) load local cache
    final raw = await _controller.loadSavedLocationsRaw();
    if (raw != null) {
      final List parsed = json.decode(raw) as List;
      setState(() {
        _locations = parsed
            .map((e) => SavedLocation.fromJson(e as Map<String, dynamic>))
            .toList();
        _sortLocations();
      });
    }

    // 2) try load farms from backend and merge (server wins for IDs)
    try {
      final server = await _fetchFarmsFromBackend();
      var changed = false;
      for (final s in server) {
        final existsById = _locations.any((l) => l.id == s.id);
        final existsByCoords = _locations.any(
          (l) => (l.lat == s.lat && l.lon == s.lon),
        );
        if (!existsById && !existsByCoords) {
          _locations.add(s);
          changed = true;
        } else if (existsByCoords && !existsById) {
          // replace the local temporary id with server id so future deletes sync
          final idx = _locations.indexWhere(
            (l) => (l.lat == s.lat && l.lon == s.lon),
          );
          if (idx >= 0) {
            _locations[idx].id = s.id;
            changed = true;
          }
        }
      }
      if (changed) {
        _sortLocations();
        await _saveLocations();
      }
    } catch (_) {
      // ignore backend errors — app continues with local cache
    }

    // load default location id (if any) so list can show default marker
    try {
      final rawDefault = await _controller.loadDefaultLocationRaw();
      if (rawDefault != null) {
        final Map<String, dynamic> d = json.decode(rawDefault) as Map<String, dynamic>;
        final defId = d['id']?.toString();
        if (mounted) {
          setState(() {
            _defaultLocationId = defId;
            _sortLocations();
          });
        } else {
          _defaultLocationId = defId;
          _sortLocations();
        }
      }
    } catch (_) {}

    await _refreshAllWeather();

    // if first run with no locations, ask user to add current location
    await _maybeOfferAddCurrentOnFirstRun();
  }

  /// Fetch farms for current backend user (returns empty list if not-logged / no backend id)
  Future<List<SavedLocation>> _fetchFarmsFromBackend() async {
    final data = await _controller.fetchFarmsFromBackend();
    return data
        .map((e) => SavedLocation.fromBackendJson(e))
        .toList();
  }

  Future<void> _saveLocations() async {
    await _controller.saveLocations(
      _locations.map((e) => e.toJson()).toList(),
    );
  }

  Future<void> _refreshAllWeather() async {
    if (mounted) setState(() => _loading = true);
    try {
      // ask service for the current locale; default to arabic if something
      // goes wrong.
      final lang = Localizations.localeOf(context).languageCode;
      for (final loc in _locations) {
        try {
          final info = await _service.fetchCurrentWeatherByCoords(
            loc.lat,
            loc.lon,
            lang: lang,
          );
          _weatherCache[loc.id] = info;
        } catch (_) {
          // ignore individual failures
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Return true if a location with similar coordinates or same name already exists.
  bool _isDuplicateLocation(SavedLocation loc) {
    const eps = 0.01; // ~1km tolerance for coordinates
    final name = loc.name.toLowerCase().trim();
    return _locations.any((l) {
      if (l.name.toLowerCase().trim() == name) return true;
      if ((l.lat - loc.lat).abs() <= eps && (l.lon - loc.lon).abs() <= eps) return true;
      return false;
    });
  }

  /// Ensure ordering: default farm first (if set), then others by createdAt desc
  void _sortLocations() {
    _locations.sort((a, b) {
      if (_defaultLocationId != null) {
        if (a.id == _defaultLocationId && b.id != _defaultLocationId) return -1;
        if (b.id == _defaultLocationId && a.id != _defaultLocationId) return 1;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  Future<void> _addByCity() async {
    // Deprecated: use new flow that prompts for search input from BottomSheet
    final city = _searchController.text.trim();
    if (city.isEmpty) return;
    await _addByCityQuery(city);
  }

  Future<void> _addByCityQuery(String city) async {
    if (mounted) setState(() {
      _loading = true;
      _error = null;
    });

    WeatherInfo? info;
    double lat = 0.0, lon = 0.0;
    try {
      info = await _service.fetchCurrentWeatherByCity(
        city,
        lang: Localizations.localeOf(context).languageCode,
      );
      lat = info.lat ?? 0.0;
      lon = info.lon ?? 0.0;
    } catch (_) {
      // offline or failed lookup — allow adding the farm with unknown weather
      info = null;
    }

    final defaultName = city;
    final name = await _promptForFarmName(defaultName);
    if (name == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final loc = SavedLocation(
      id: UniqueKey().toString(),
      name: name,
      lat: lat,
      lon: lon,
    );

    // prevent duplicates
    if (_isDuplicateLocation(loc)) {
      if (mounted) setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الموقع موجود بالفعل في قائمتك')),
      );
      return;
    }

    // optimistic add (weather may be null)
    if (mounted) {
      setState(() {
        _locations.add(loc);
        _sortLocations();
        _weatherCache[loc.id] = info;
      });
    }

    // attempt backend creation
    try {
      final serverId = await _createFarmOnBackend(loc);
      if (serverId != null) {
        final idx = _locations.indexWhere((l) => l.id == loc.id);
        if (idx >= 0) {
          final oldId = _locations[idx].id;
          _locations[idx].id = serverId;
          if (_defaultLocationId == oldId) {
            _defaultLocationId = serverId;
          }
          final moved = _weatherCache.remove(oldId);
          if (moved != null) _weatherCache[serverId] = moved;
          _sortLocations();
          if (mounted) setState(() {});
        }
      }
    } catch (_) {}

    await _saveLocations();
    if (mounted) setState(() => _loading = false);
  }

  /// Prompt user for a farm name. Returns null if cancelled.
  Future<String?> _promptForFarmName(String defaultName) async {
    final ctl = TextEditingController(text: defaultName);
    final res = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('اسم المزرعة'),
          content: TextField(
            controller: ctl,
            decoration: const InputDecoration(hintText: 'أدخل اسم المزرعة'),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('إلغاء')),
            TextButton(
              onPressed: () {
                final val = ctl.text.trim();
                Navigator.pop(ctx, val.isEmpty ? 'مزرعتي' : val);
              },
              child: const Text('حفظ'),
            ),
          ],
        );
      },
    );
    return res;
  }

  Future<void> _addCurrentLocation() async {
    if (mounted) setState(() {
      _loading = true;
      _error = null;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _error = 'يجب منح صلاحية الموقع لإضافة الموقع الحالي');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      WeatherInfo? info;
      try {
        info = await _service.fetchCurrentWeatherByCoords(pos.latitude, pos.longitude);
      } catch (_) {
        info = null; // allow offline add
      }

      final defaultName = (info != null && info.city.isNotEmpty) ? info.city : 'مزرعتي';
      final name = await _promptForFarmName(defaultName);
      if (name == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final loc = SavedLocation(
        id: UniqueKey().toString(),
        name: name,
        lat: pos.latitude,
        lon: pos.longitude,
      );

      // prevent duplicates
      if (_isDuplicateLocation(loc)) {
        if (mounted) setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الموقع موجود بالفعل في قائمتك')),
        );
        return;
      }

      setState(() {
        _locations.add(loc);
        _sortLocations();
        _weatherCache[loc.id] = info;
      });

      try {
        final serverId = await _createFarmOnBackend(loc);
        if (serverId != null) {
          final idx = _locations.indexWhere((l) => l.id == loc.id);
          if (idx >= 0) {
            final oldId = _locations[idx].id;
            _locations[idx].id = serverId;
            if (_defaultLocationId == oldId) _defaultLocationId = serverId;
            final moved = _weatherCache.remove(oldId);
            if (moved != null) _weatherCache[serverId] = moved;
            _sortLocations();
            if (mounted) setState(() {});
          }
        }
      } catch (_) {
        // ignore backend error
      }

      await _saveLocations();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _removeLocation(String id) async {
    // legacy local remove + backend delete (kept for compatibility)
    final idx = _locations.indexWhere((l) => l.id == id);
    if (idx >= 0) {
      _locations.removeAt(idx);
      _weatherCache.remove(id);
      await _saveLocations();
    }
  }

  Future<void> _refreshWeatherForLocation(SavedLocation loc) async {
    try {
      final info = await _service.fetchCurrentWeatherByCoords(loc.lat, loc.lon);
      if (mounted) setState(() => _weatherCache[loc.id] = info);
      
    } catch (_) {}
  }

  Future<void> _deleteLocationWithUndo(SavedLocation loc) async {
    final id = loc.id;
    final idx = _locations.indexWhere((l) => l.id == id);
    if (idx < 0) return;

    // remove locally immediately
    setState(() {
      _locations.removeAt(idx);
      _weatherCache.remove(id);
      if (_defaultLocationId == id) {
        _defaultLocationId = null;
      }
    });
    await _saveLocations();

    final snack = SnackBar(
      content: const Text('تم حذف المزرعة'),
      action: SnackBarAction(label: 'تراجع', onPressed: () {}),
      duration: const Duration(seconds: 4),
    );

    final controller = ScaffoldMessenger.of(context).showSnackBar(snack);
    final reason = await controller.closed;

    if (reason == SnackBarClosedReason.action) {
      // undo — re-insert and refresh
      if (mounted) {
        setState(() {
          _locations.insert(idx, loc);
          _sortLocations();
        });
      }
      await _saveLocations();
      await _refreshWeatherForLocation(loc);
    } else {
      // commit delete to backend if appropriate
      try {
        final isServerId = RegExp(r'^[0-9a-fA-F\-]{20,}$').hasMatch(id);
        if (isServerId) await _deleteFarmOnBackend(id);
      } catch (_) {
        // ignore backend failures — data already removed locally
      }
    }
  }

  /// Create farm on backend (returns server id) — no-op if no backend user
  Future<String?> _createFarmOnBackend(SavedLocation loc) async {
    return _controller.createFarmOnBackend(
      name: loc.name,
      lat: loc.lat,
      lon: loc.lon,
    );
  }

  /// Delete farm on backend if exists
  Future<void> _deleteFarmOnBackend(String id) async {
    await _controller.deleteFarmOnBackend(id);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'الطقس',
            style: TextStyle(
              color: Color(0xFF016630),
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(color: Color(0xFF008236)),
          actions: [],
        ),
        body: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
              const SizedBox(height: 8),

              if (_loading)
                LinearProgressIndicator(
                  color: const Color(0xFF008236),
                  backgroundColor: Colors.green[50],
                ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],

              const SizedBox(height: 8),

              Expanded(
                child: _locations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.agriculture,
                              size: 84,
                              color: Color(0xFF9CCC65),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'ما عندك مزارع بعد',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E2939),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Text(
                                'أضف مزرعتك الأولى لمتابعة الطقس الزراعي',
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshAllWeather,
                        child: ListView.separated(
                          padding: const EdgeInsets.only(top: 8, bottom: 96),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _locations.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            final loc = _locations[i];
                            final info = _weatherCache[loc.id];
                            

                            // adapt card minimum height to the current text scale so the layout
                            // remains safe on large accessibility text settings.
                            final _textScale = MediaQuery.of(
                              ctx,
                            ).textScaleFactor;
                            final _minCardHeight = math.max(
                              78.0,
                              78.0 * (_textScale > 1.4 ? 1.4 : _textScale),
                            );

                            return Container(
                              constraints: BoxConstraints(minHeight: _minCardHeight),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: WeatherFarmCard(
                                name: loc.name,
                                info: info,
                                isPrimary: _defaultLocationId != null && _defaultLocationId == loc.id,
                                onTap: () {
                                  Navigator.of(context).pop({
                                    'id': loc.id,
                                    'lat': loc.lat,
                                    'lon': loc.lon,
                                    'name': loc.name,
                                  });
                                },
                                onLongPress: () => _showDetails(info, loc),
                                onDelete: () => _deleteLocationWithUndo(loc),
                              ),
                            );
                            }, // itemBuilder
                        ), // ListView.separated
                      ), // RefreshIndicator
              ), // Expanded
              ], // Column children
            ), // Column
          ), // Padding
        ), // SafeArea
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddOptions,
          tooltip: 'أضف موقع جديد',
          backgroundColor: const Color(0xFF008236),
          elevation: 4,
          child: const Icon(
            Icons.add_location_alt_outlined,
            color: Colors.white,
          ),
        ),
      ), // Scaffold
    );
  }

  void _showAddOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('إضافة مزرعة جديدة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.search, color: Color(0xFF008236)),
                    title: const Text('بحث بالمنطقة أو المدينة'),
                    subtitle: const Text('ابحث عن إحداثيات ثم اختر اسم المزرعة'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _promptForSearchAndAdd();
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.my_location, color: Color(0xFF008236)),
                    title: const Text('استخدام الموقع الحالي'),
                    subtitle: const Text('أضف موقعك الفعلي بسرعة'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _addCurrentLocation();
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.map, color: Color(0xFF008236)),
                    title: const Text('اختيار من الخريطة'),
                    subtitle: const Text('اختر موقع المزرعة بدقة على الخريطة'),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final picked = await Navigator.push(context, MaterialPageRoute(builder: (_) => const SelectFarmLocationScreen()));
                      if (picked is LatLng) {
                        // ask for farm name
                        final name = await _promptForFarmName('مزرعتي');
                        if (name == null) return;
                        final loc = SavedLocation(
                          id: UniqueKey().toString(),
                          name: name,
                          lat: picked.latitude,
                          lon: picked.longitude,
                        );

                        if (_isDuplicateLocation(loc)) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الموقع موجود بالفعل في قائمتك')));
                          return;
                        }

                        // attempt to fetch weather but allow offline
                        WeatherInfo? info;
                        try {
                          info = await _service.fetchCurrentWeatherByCoords(loc.lat, loc.lon);
                        } catch (_) {
                          info = null;
                        }

                        setState(() {
                          _locations.add(loc);
                          _sortLocations();
                          _weatherCache[loc.id] = info;
                        });

                        try {
                          final serverId = await _createFarmOnBackend(loc);
                          if (serverId != null) {
                            final idx = _locations.indexWhere((l) => l.id == loc.id);
                            if (idx >= 0) {
                              final oldId = _locations[idx].id;
                              _locations[idx].id = serverId;
                                if (_defaultLocationId == oldId) _defaultLocationId = serverId;
                                final moved = _weatherCache.remove(oldId);
                                if (moved != null) _weatherCache[serverId] = moved;
                                _sortLocations();
                                if (mounted) setState(() {});
                            }
                          }
                        } catch (_) {}

                        await _saveLocations();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _promptForSearchAndAdd() async {
    final qController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ابحث عن المنطقة أو المدينة'),
        content: TextField(
          controller: qController,
          decoration: const InputDecoration(hintText: 'مثال: الوادي أو الرياض'),
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => Navigator.pop(ctx, true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('بحث')),
        ],
      ),
    );
    if (confirmed == true) {
      final q = qController.text.trim();
      if (q.isEmpty) return;
      await _addByCityQuery(q);
    }
  }

  void _showDetails(WeatherInfo? info, SavedLocation loc) {
    if (info == null) return;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      loc.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '${info.tempC.toStringAsFixed(1)}°C',
                    style: const TextStyle(fontSize: 20),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                info.description,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Text('الرطوبة: ${info.humidity}%'),
              const SizedBox(height: 8),
              Text(
                'الإحداثيات: ${loc.lat.toStringAsFixed(4)}, ${loc.lon.toStringAsFixed(4)}',
              ),
              const SizedBox(height: 12),
              if (info.icon.isNotEmpty)
                Center(
                  child: Image.network(
                    'https://openweathermap.org/img/wn/${info.icon}@2x.png',
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () async {
                      // mark this saved location as the default location in SharedPreferences
                      await _controller.saveDefaultLocation(
                        id: loc.id,
                        lat: loc.lat,
                        lon: loc.lon,
                        name: loc.name,
                      );
                      setState(() {
                        _defaultLocationId = loc.id;
                        _sortLocations();
                      });
                      await _saveLocations();
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم تعيين الموقع كموقع افتراضي'),
                        ),
                      );
                    },
                    child: const Text('تعيين كموقع افتراضي'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('إغلاق'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
