import 'package:flutter/material.dart';

class HomeGreetingSection extends StatelessWidget {
  final String? name;

  const HomeGreetingSection({super.key, this.name});

  String _greetingForHour(int hour) {
    if (hour >= 5 && hour < 12) return 'صباح الخير';
    return 'مساء الخير';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = _greetingForHour(now.hour);
    final displayName = (name != null && name!.trim().isNotEmpty) ? name! : '';

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            // Greeting texts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        greeting,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E2939),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (displayName.isNotEmpty)
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF016630),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'لنزرع غدًا أفضل 🌱 — اعتنِ بمحاصيلك اليوم',
                    style: TextStyle(fontSize: 13, color: Color(0xFF4A5565)),
                  ),
                ],
              ),
            ),

            // Small decorative avatar with plant emoji
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Text('🌱', style: TextStyle(fontSize: 22))),
            ),
          ],
        ),
      ),
    );
  }
}
