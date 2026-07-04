import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter_application_55555/core/api_client.dart';
import 'package:flutter_application_55555/core/service_locator.dart';
import 'package:flutter_application_55555/features/weather/presentation/screens/weather_screen.dart';
import 'package:flutter_application_55555/core/services/config.dart';

class HomeLastDiagnosisSection extends StatelessWidget {
  final String? disease;
  final double? confidence;
  final String? image;
  final String? date;
  final VoidCallback? onViewDetails;

  const HomeLastDiagnosisSection({
    super.key,
    required this.disease,
    required this.confidence,
    required this.image,
    required this.date,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    if (disease == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'آخر نتيجة تشخيص',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF1E2939),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'لا توجد نتائج تشخيص محفوظة بعد.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      );
    }

    String confidenceStr = confidence != null ? '${(confidence! * 100).toStringAsFixed(0)}%' : '';
    // date is already formatted by caller (dd/MM/yyyy) or null/placeholder
    String dateStr = date ?? '';
    if (dateStr.isEmpty && date != null && date!.isNotEmpty) {
      dateStr = 'تاريخ غير متوفر';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'آخر نتيجة تشخيص',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF1E2939),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFB9F8CF)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Builder(
                    builder: (_) {
                      String finalImage = image ?? '';
                      final String defaultBase = Config.apiBaseUrl;
                      try {
                        if (finalImage.startsWith('http')) {
                          // leave as is
                        } else if (finalImage.startsWith('file://') || finalImage.startsWith('content://')) {
                          // leave as is
                        } else if (finalImage.startsWith('/')) {
                          String base;
                          try {
                            base = sl.get<ApiClient>().baseUrl;
                          } catch (_) {
                            base = defaultBase;
                          }
                          if (finalImage.isNotEmpty) {
                            finalImage = base.endsWith('/') ? base.substring(0, base.length - 1) + finalImage : base + finalImage;
                          }
                        } else if (finalImage.isNotEmpty) {
                          String base;
                          try {
                            base = sl.get<ApiClient>().baseUrl;
                          } catch (_) {
                            base = defaultBase;
                          }
                          finalImage = base.endsWith('/') ? base + finalImage : '$base/$finalImage';
                        }
                      } catch (_) {
                        finalImage = '';
                      }

                      if (finalImage.startsWith('http')) {
                        return Image.network(finalImage, height: 56, width: 71, fit: BoxFit.cover);
                      }
                      if (finalImage.startsWith('file://') || finalImage.startsWith('content://')) {
                        try {
                          final uri = Uri.parse(finalImage);
                          final path = uri.toFilePath();
                          final f = io.File(path);
                          if (f.existsSync()) {
                            return Image.file(f, height: 56, width: 71, fit: BoxFit.cover);
                          }
                        } catch (_) {}
                        return Container(
                          height: 56,
                          width: 71,
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.broken_image,
                            color: Colors.grey,
                          ),
                        );
                      }
                      if (finalImage.isEmpty) {
                        return Image.asset('assets/leaf.png', height: 56, width: 71, fit: BoxFit.cover);
                      }
                      return Image.network(finalImage, height: 56, width: 71, fit: BoxFit.cover);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              disease ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF1E2939),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'دقة: $confidenceStr',
                        style: const TextStyle(fontSize: 14, color: Color(0xFF4A5565)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dateStr,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF4A5565)),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFB9F8CF)),
                            backgroundColor: const Color(0xFFEFFCF4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.info, color: Color(0xFF00A63E)),
                          label: const Text('عرض التفاصيل', style: TextStyle(color: Color(0xFF00A63E))),
                          onPressed: onViewDetails,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
