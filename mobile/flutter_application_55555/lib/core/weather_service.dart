import 'dart:convert';

import 'package:http/http.dart' as http;

/// خدمة بسيطة للتعامل مع OpenWeatherMap
/// ملاحظة: احتفظ بمفتاح الـ API في مكان آمن (مثلاً متغيرات بيئة) بدلاً من كتابته مباشرة في الكود.
class WeatherInfo {
  final String city;
  final double tempC;
  final String description;
  final int humidity;
  final String icon;
  final double? lat;
  final double? lon;
  final double windSpeed; // km/h
  final double rainProbability; // 0.0 - 100.0
  final DateTime lastUpdated;

  WeatherInfo({
    required this.city,
    required this.tempC,
    required this.description,
    required this.humidity,
    required this.icon,
    this.lat,
    this.lon,
    this.windSpeed = 0.0,
    this.rainProbability = 0.0,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory WeatherInfo.fromJson(Map<String, dynamic> json) {
    final weather = (json['weather'] as List).isNotEmpty
        ? json['weather'][0]
        : null;
    final coord = json['coord'];

    // wind speed from API is typically meters/sec — convert to km/h
    final double windMps = (json['wind']?['speed'] as num?)?.toDouble() ?? 0.0;
    final double windKmh = windMps * 3.6;

    // try extract rain probability if present (some APIs provide 'pop' as 0..1)
    double rainProb = 0.0;
    if (json.containsKey('pop')) {
      final v = (json['pop'] as num?)?.toDouble() ?? 0.0;
      rainProb = (v <= 1.0) ? (v * 100.0) : v;
    }

    return WeatherInfo(
      city: json['name'] ?? '',
      tempC: (json['main']?['temp'] as num?)?.toDouble() ?? 0.0,
      description: weather != null ? (weather['description'] ?? '') : '',
      humidity: (json['main']?['humidity'] as num?)?.toInt() ?? 0,
      icon: weather != null ? (weather['icon'] ?? '') : '',
      lat: coord != null ? (coord['lat'] as num?)?.toDouble() : null,
      lon: coord != null ? (coord['lon'] as num?)?.toDouble() : null,
      windSpeed: windKmh,
      rainProbability: rainProb,
      lastUpdated: DateTime.now(),
    );
  }
}

class WeatherService {
  // TODO: for production move this key to secure storage / env
  final String apiKey;
  final String defaultLang;
  final http.Client _client;

  /// [defaultLang] lets callers choose the language code sent to OpenWeatherMap
  /// (e.g. "ar" for Arabic, "en" for English).  The service methods themselves
  /// also accept an optional `lang` parameter which overrides this value; the
  /// WeatherScreen passes its current locale so the UI will automatically
  /// display Arabic when the app's locale is Arabic.
  WeatherService({
    required this.apiKey,
    this.defaultLang = 'ar',
    http.Client? client,
  }) : _client = client ?? http.Client();

  Future<WeatherInfo> fetchCurrentWeatherByCity(
    String city, {
    String? lang,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw Exception(
        'OpenWeatherMap API key not configured. Set OPENWEATHER_API_KEY via --dart-define or register WeatherService with a valid apiKey.',
      );
    }

    final uri = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
      'q': city,
      'units': 'metric',
      'appid': apiKey,
      'lang': lang ?? defaultLang,
    });

    final res = await _client.get(uri);
    if (res.statusCode == 200) {
      final Map<String, dynamic> data =
          json.decode(res.body) as Map<String, dynamic>;
      return WeatherInfo.fromJson(data);
    }

    throw Exception('Failed to load weather: ${res.statusCode} ${res.body}');
  }

  Future<WeatherInfo> fetchCurrentWeatherByCoords(
    double lat,
    double lon, {
    String? lang,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw Exception(
        'OpenWeatherMap API key not configured. Set OPENWEATHER_API_KEY via --dart-define or register WeatherService with a valid apiKey.',
      );
    }

    final uri = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
      'lat': lat.toString(),
      'lon': lon.toString(),
      'units': 'metric',
      'appid': apiKey,
      'lang': lang ?? defaultLang,
    });

    final res = await _client.get(uri);
    if (res.statusCode == 200) {
      final Map<String, dynamic> data =
          json.decode(res.body) as Map<String, dynamic>;
      return WeatherInfo.fromJson(data);
    }

    throw Exception('Failed to load weather: ${res.statusCode} ${res.body}');
  }

  void dispose() {
    _client.close();
  }
}
