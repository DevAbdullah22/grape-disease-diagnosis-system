import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/execute_treatment_step_with_result.dart';

class TreatmentExecutionScreen extends StatefulWidget {
  final String diagnosisId;
  const TreatmentExecutionScreen({super.key, required this.diagnosisId});

  @override
  State<TreatmentExecutionScreen> createState() =>
      _TreatmentExecutionScreenState();
}

class _TreatmentExecutionScreenState extends State<TreatmentExecutionScreen> {
  Map<String, dynamic>? executionData;
  bool isLoading = true;
  String? error;
  Timer? _tickTimer;

  @override
  void initState() {
    super.initState();
    fetchExecutionData();

    // refresh minute-precision relative UI
    _tickTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchExecutionData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final usecase = context.read<ExecuteTreatmentStepWithResult>();
      final payload = await usecase.call(diagnosisId: widget.diagnosisId);
      setState(() {
        executionData = payload;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = '\u0641\u0634\u0644 \u0627\u0644\u0627\u062a\u0635\u0627\u0644: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _showNextDoseNotification(Map<String, dynamic> data) async {
    try {
      final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      await flutterLocalNotificationsPlugin.initialize(
        const InitializationSettings(android: initializationSettingsAndroid),
      );

      final next = data['nextDoseAt'];
      final message = data['message'] ?? '';

      final title = next != null ? 'موعد الجرعة التالية' : 'تنفيذ الجرعة';
      final body = next != null
          ? 'الموعد: ${next.toString().split('T').first}'
          : (message.isNotEmpty ? message : 'تم تنفيذ الجرعة بنجاح');

      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    } catch (e) {
      // ignore errors from local notifications
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3FFF7),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: const Text(
            'تنفيذ العلاج',
            style: TextStyle(
              color: Color(0xFF016630),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          top: false,
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : error != null
              ? Center(
                  child: Text(error!, style: const TextStyle(color: Colors.red)),
                )
              : executionData == null
              ? const Center(
                  child: Text(
                    'لا توجد بيانات تنفيذ متاحة',
                    style: TextStyle(color: Colors.grey, fontSize: 18),
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        _buildDoseTimeline(),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  // Format DateTime as DD/MM/YYYY HH:MM (local time)
  String _formatDateTime(DateTime dt) {
    final l = dt.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year} - ${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }

  // minute-precision Arabic relative string
  String _timeRemainingString(DateTime target) {
    final diff = target.difference(DateTime.now());
    if (diff.inSeconds <= 0) return 'الآن';
    final hours = diff.inHours;
    final minutes = diff.inMinutes.abs() % 60;
    if (hours > 0) {
      if (minutes > 0) return 'بعد ${hours} س ${minutes} د';
      return 'بعد ${hours} س';
    }
    return 'بعد ${diff.inMinutes} د';
  }

  // جدول الجرعات بنفس تصميم شاشة خطة العلاج
  Widget _buildDoseTimeline() {
    final data = executionData!;
    // مثال: جرعات وهمية بناءً على بيانات التنفيذ (يمكنك تعديلها حسب منطقك)
    final int totalDoses = data['totalDoses'] ?? 1;
    final int currentDose = data['doseNumber'] ?? 1;
    final String nextDoseAt = data['nextDoseAt'] ?? '';
    final String executedAt = data['executedAt'] ?? '';
    final String message = data['message'] ?? '';
    String formatDate(String? raw) {
      if (raw == null || raw.isEmpty) return '';
      final dt = DateTime.tryParse(raw);
      if (dt == null) return raw;
      final formatted = _formatDateTime(dt);
      final diff = dt.difference(DateTime.now());
      if (diff.inSeconds > 0) {
        return '$formatted • ${_timeRemainingString(dt)}';
      }
      return formatted;
    }

    List<Widget> doseWidgets = [];
    for (int i = 1; i <= totalDoses; i++) {
      bool isExecuted = i < currentDose;
      bool isCurrent = i == currentDose;
      bool isPending = i > currentDose;
      doseWidgets.add(
        Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3FFF7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isExecuted
                        ? Icons.check_circle
                        : isCurrent
                        ? Icons.edit
                        : Icons.info,
                    color: isExecuted
                        ? const Color(0xFF00C950)
                        : isCurrent
                        ? const Color(0xFF0066FF)
                        : const Color(0xFFBDBDBD),
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'الجرعة ${_arabicDoseNumber(i)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF016630),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.grey,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isExecuted || isCurrent
                                  ? formatDate(executedAt)
                                  : formatDate(nextDoseAt),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF4A5565),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text(
                              'المبيد المستخدم:',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF4A5565),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '---',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF016630),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        if (isExecuted)
                          const Text(
                            'تم التنفيذ بنجاح',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF00C950),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        if (isCurrent)
                          ElevatedButton.icon(
                            onPressed: () {
                              // زر تأكيد التنفيذ (يمكنك ربطه بمنطق التنفيذ)
                            },
                            icon: const Icon(Icons.check),
                            label: const Text('تأكيد تنفيذ الجرعة'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0066FF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        if (isPending)
                          const Text(
                            'بانتظار التنفيذ',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFFBDBDBD),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (i < totalDoses)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                width: 2,
                height: 32,
                color: const Color(0xFFE0E0E0),
              ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'جدول الجرعات',
          style: TextStyle(
            color: Color(0xFF016630),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 16),
        ...doseWidgets,
        const SizedBox(height: 16),
        Text(
          message,
          style: const TextStyle(fontSize: 15, color: Colors.black54),
        ),
      ],
    );
  }

  String _arabicDoseNumber(int n) {
    const nums = [
      'الأولى',
      'الثانية',
      'الثالثة',
      'الرابعة',
      'الخامسة',
      'السادسة',
      'السابعة',
      'الثامنة',
      'التاسعة',
      'العاشرة',
    ];
    return n <= nums.length ? nums[n - 1] : n.toString();
  }
}
