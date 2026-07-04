import 'package:flutter/material.dart';
import 'package:flutter_application_55555/core/weather_service.dart';

class HomeWeatherCard extends StatelessWidget {
  final bool loading;
  final String? error;
  final WeatherInfo? weather;
  final bool isUsingDefault;
  final VoidCallback onTap;
  final VoidCallback onRetry;
  final VoidCallback onOpenLocationSettings;

  const HomeWeatherCard({
    super.key,
    required this.loading,
    required this.error,
    required this.weather,
    required this.isUsingDefault,
    required this.onTap,
    required this.onRetry,
    required this.onOpenLocationSettings,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        child: Container(
          key: ValueKey<String>(loading
              ? 'loading'
              : (error != null ? 'error' : (weather != null ? 'weather' : 'empty'))),
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFB9F8CF)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: loading
                ? _buildLoadingSkeleton(context)
                : error != null
                    ? _buildErrorRow(context)
                    : weather != null
                        ? _buildWeatherRow(context)
                        : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 140, height: 20, color: Colors.grey.shade200),
              const SizedBox(height: 8),
              Container(width: 100, height: 40, color: Colors.grey.shade300),
              const SizedBox(height: 6),
              Container(width: 60, height: 14, color: Colors.grey.shade200),
            ],
          ),
          const Spacer(),
          Container(width: 48, height: 48, color: Colors.grey.shade200),
        ],
      ),
    );
  }

  Widget _buildErrorRow(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            error ?? '',
            style: const TextStyle(color: Colors.red),
          ),
        ),
        if ((error ?? '').contains('خدمة الموقع'))
          OutlinedButton(
            onPressed: onOpenLocationSettings,
            child: const Text('تفعيل الموقع'),
          )
        else
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('إعادة المحاولة'),
          ),
      ],
    );
  }

  Widget _buildWeatherRow(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  weather!.city,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF1E2939),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (isUsingDefault) const SizedBox(width: 8),
                if (isUsingDefault)
                  const Icon(
                    Icons.star,
                    size: 16,
                    color: Colors.amber,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${weather!.tempC.toStringAsFixed(1)}°',
              style: const TextStyle(
                fontSize: 40,
                color: Color(0xFF1E2939),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'مئوية',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF4A5565),
              ),
            ),
          ],
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              weather!.description,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF1E2939),
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'الرطوبة: ${weather!.humidity}%',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4A5565),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        if (weather!.icon.isNotEmpty)
          Image.network(
            'https://openweathermap.org/img/wn/${weather!.icon}@2x.png',
            width: 48,
            height: 48,
          ),
      ],
    );
  }
}
