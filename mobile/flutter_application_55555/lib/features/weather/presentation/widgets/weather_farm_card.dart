import 'package:flutter/material.dart';
import 'package:flutter_application_55555/core/weather_service.dart';
import 'package:flutter_application_55555/core/agriculture_advisor.dart';

class WeatherFarmCard extends StatelessWidget {
  final String name;
  final WeatherInfo? info;
  final bool isPrimary;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;

  // simple english→arabic map used when API returns english description but the
  // app is running in Arabic locale.  OpenWeatherMap already supports the
  // "lang" parameter, but this guard ensures offline or misconfigured
  // requests still show something readable.
  static const Map<String, String> _enToAr = {
    'clear sky': 'سماء صافية',
    'few clouds': 'غيوم متفرقة',
    'scattered clouds': 'غيوم متناثرة',
    'broken clouds': 'غيوم متكسرة',
    'shower rain': 'أمطار خفيفة',
    'rain': 'مطر',
    'thunderstorm': 'عاصفة رعدية',
    'snow': 'ثلج',
    'mist': 'ضباب',
    'overcast clouds': 'غيوم ملبدة',
  };

  const WeatherFarmCard({
    Key? key,
    required this.name,
    this.info,
    this.isPrimary = false,
    this.onTap,
    this.onLongPress,
    this.onDelete,
  }) : super(key: key);

  Color _adviceColor(String advice) {
    if (advice.contains('لا تسقي') || advice.contains('لا تسقي'))
      return Colors.red.shade200;
    if (advice.contains('🔥') ||
        advice.contains('تجنب') ||
        advice.contains('يُفضل') ||
        advice.contains('يفضل'))
      return Colors.orange.shade200;
    if (advice.contains('🟢') || advice.contains('مناسبة'))
      return Colors.green.shade200;
    return Colors.grey.shade200;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final temp = info?.tempC ?? 0.0;
    final humidity = info?.humidity ?? 0;
    final wind = info?.windSpeed ?? 0.0;
    final rain = info?.rainProbability ?? 0.0;
    final icon = info?.icon ?? '';

    // pick description text. prefer the value returned by API; if it only
    // contains ascii characters and the current locale is Arabic attempt a
    // simple dictionary lookup so the user doesn't see "clear sky" etc.
    String desc;
    if (info != null && info!.description.isNotEmpty) {
      desc = info!.description;
      final isAscii = RegExp(r"^[\x00-\x7F]+").hasMatch(desc);
      if (isAscii) {
        final lower = desc.toLowerCase();
        if (_enToAr.containsKey(lower)) {
          desc = _enToAr[lower]!;
        }
      }
    } else {
      desc = 'جارٍ التحميل...';
    }

    final advice = info != null
        ? AgricultureAdvisor.getIrrigationAdvice(
            temp: temp,
            humidity: humidity,
            windSpeed: wind,
            rainProbability: rain,
          )
        : 'جارٍ التحليل...';

    final adviceBg = _adviceColor(advice);
    final stress = info != null
        ? AgricultureAdvisor.getStressLevel(temp, humidity)
        : '-';

    final bgColor = isPrimary ? const Color(0xFFE8F5E9) : Colors.white;
    final borderColor = isPrimary
        ? const Color(0xFF81C784)
        : const Color(0xFFB9F8CF);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: isPrimary ? 1.8 : 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isPrimary)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF81C784)),
                  ),
                  child: const Text(
                    'المزرعة الرئيسية',
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: info != null
                        ? const Color(0xFFEFFCF4)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: (icon.isNotEmpty)
                      ? Image.network(
                          // use 4x size for crisper graphics on high‑DPI devices
                          'https://openweathermap.org/img/wn/$icon@4x.png',
                          width: 60,
                          height: 60,
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, err, stack) =>
                              const Icon(Icons.cloud_off, color: Colors.grey),
                        )
                      : const Icon(
                          Icons.location_on_outlined,
                          color: Colors.grey,
                          size: 32,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Color(0xFF1E2939),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        desc,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  info != null ? '${info!.tempC.toStringAsFixed(1)}°C' : '--°C',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E2939),
                  ),
                ),
                const SizedBox(width: 6),
                if (onDelete != null)
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onDelete,
                    tooltip: 'حذف المزرعة',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.water_drop,
                            size: 16,
                            color: Colors.blueAccent,
                          ),
                          const SizedBox(width: 6),
                          Text('الرطوبة', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        info != null ? '${info!.humidity}%' : '-',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🌬'),
                          const SizedBox(width: 6),
                          Text('الرياح', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        info != null
                            ? '${info!.windSpeed.toStringAsFixed(1)} كم/س'
                            : '-',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('🌧'),
                          const SizedBox(width: 6),
                          Text('احتمال المطر', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        info != null
                            ? '${info!.rainProbability.toStringAsFixed(0)}%'
                            : '-',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            // Recommendation box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: adviceBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                advice,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.thermostat, size: 16),
                    const SizedBox(width: 6),
                    Text('إجهاد: $stress'),
                  ],
                ),
                Text(
                  'آخر تحديث: ${info != null ? _formatTime(info!.lastUpdated.toLocal()) : '-'}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
