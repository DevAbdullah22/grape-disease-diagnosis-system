import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_55555/core/services/config.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/get_diagnosis_plan_details.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/execute_treatment_step_with_result.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/log_treatment_reminder_notification.dart';

class DiagnosisDetailsPlanScreen extends StatefulWidget {
  final String diagnosisId;
  const DiagnosisDetailsPlanScreen({super.key, required this.diagnosisId});

  @override
  State<DiagnosisDetailsPlanScreen> createState() =>
      _DiagnosisDetailsPlanScreenState();
}

class _DiagnosisDetailsPlanScreenState
    extends State<DiagnosisDetailsPlanScreen> {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  Map<String, dynamic>? planData;
  bool isLoading = true;
  String? error;
  bool _confirming = false;
  Timer? _tickTimer;

  // Theme colors used in the screen
  final Color primaryGreen = const Color(0xFF016630);
  final Color softBg = const Color(0xFFF3FFF7);
  final Color cardBg = Colors.white;
  final Color progressBg = const Color(0xFFF3FFF7);
  final Color progressBar = const Color(0xFF00C950);
  final Color tagYellow = const Color(0xFFFFE5B2);
  final Color tagTextYellow = const Color(0xFFFFA800);
  final Color stepGreen = const Color(0xFF00C950);
  final Color stepBlue = const Color(0xFF0066FF);
  final Color stepGray = const Color(0xFFBDBDBD);
  final Color stepBorder = const Color(0xFFE0E0E0);
  final Color stepBg = const Color(0xFFF3FFF7);
  final Color stepSuccessText = const Color(0xFF00C950);
  final Color stepPendingText = const Color(0xFF0066FF);
  final Color stepInfoText = const Color(0xFFBDBDBD);

  @override
  void initState() {
    super.initState();
    _initLocalNotifications();
    fetchPlanData();

    // refresh time-sensitive UI every minute (minutes precision)
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

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> fetchPlanData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final usecase = context.read<GetDiagnosisPlanDetails>();
      final decoded = await usecase.call(widget.diagnosisId);
      if (!mounted) return;
      setState(() {
        planData = decoded;
        isLoading = false;
      });
      _scheduleNextDoseNotification(decoded);
      if (mounted) {
        setState(() {
          _confirming = false;
        });
      }
    } catch (e) {
      debugPrint('fetchPlanData exception: $e');
      setState(() {
        error = '\u0641\u0634\u0644 \u0627\u0644\u0627\u062a\u0635\u0627\u0644: $e';
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text('\u062e\u0637\u0623 \u0641\u064a \u0627\u0644\u0627\u062a\u0635\u0627\u0644: $e'),
          ),
        );
      }
    }
  }

  Future<void> _confirmDose() async {
    if (_confirming) return;
    if (widget.diagnosisId.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('\u0645\u0639\u0631\u0651\u0641 \u0627\u0644\u062a\u0634\u062e\u064a\u0635 \u063a\u064a\u0631 \u0635\u0627\u0644\u062d'),
          ),
        );
      }
      return;
    }
    setState(() => _confirming = true);
    try {
      final usecase = context.read<ExecuteTreatmentStepWithResult>();
      final payload = await usecase.call(diagnosisId: widget.diagnosisId);

      await fetchPlanData();
      var msg = '\u062a\u0645 \u062a\u0623\u0643\u064a\u062f \u062a\u0646\u0641\u064a\u0630 \u0627\u0644\u062c\u0631\u0639\u0629';
      if (payload['message'] != null) {
        final raw = payload['message']?.toString();
        if (raw != null && raw.isNotEmpty) {
          msg = raw;
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      // include stack trace in console and show concise message
      // ignore: avoid_print
      print('[confirmDose] Exception: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            content: Text('\u062e\u0637\u0623 \u0641\u064a \u0627\u0644\u0627\u062a\u0635\u0627\u0644: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  Future<void> _scheduleNextDoseNotification(Map<String, dynamic> plan) async {
    if (plan['doses'] == null) return;
    final doses = plan['doses'] as List<dynamic>;
    // ابحث عن أول جرعة حالتها "تأكيد تنفيذ الجرعة" أو "بانتظار التنفيذ"
    final nextDose = doses.cast<Map<String, dynamic>>().firstWhere(
      (d) =>
          d['status'] == 'تأكيد تنفيذ الجرعة' ||
          d['status'] == 'بانتظار التنفيذ',
      orElse: () => <String, dynamic>{},
    );
    if (nextDose.isEmpty) return;
    final dateStr = (nextDose['date'] ?? '') as String;
    if (dateStr.isEmpty) return;
    // تحويل التاريخ إلى DateTime
    DateTime? doseDate;
    try {
      doseDate = DateTime.parse(dateStr);
    } catch (_) {
      return;
    }
    // إذا كان التاريخ في المستقبل فقط
    if (doseDate.isBefore(DateTime.now())) return;

    // جدولة الإشعار
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'next_dose_channel',
          'تذكير الجرعة',
          channelDescription: 'إشعار لتذكير المستخدم بموعد الجرعة القادمة',
          importance: Importance.max,
          priority: Priority.high,
        );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // تحويل DateTime إلى TZDateTime
    // تحتاج إلى إضافة حزمة timezone واستخدامها هنا

    tz.initializeTimeZones();
    final tz.TZDateTime tzDoseDate = tz.TZDateTime.from(doseDate, tz.local);

    try {
      final nid = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await flutterLocalNotificationsPlugin.zonedSchedule(
        nid,
        'تذكير جرعة العلاج',
        'موعد الجرعة القادمة: ${nextDose['date']}',
        tzDoseDate,
        notificationDetails,
        payload: 'notifications',
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
      // سجل الإشعار في قاعدة البيانات عبر الـ backend لكي يبقى سجل مركزي
      try {
        final logUsecase = context.read<LogTreatmentReminderNotification>();
        final userId = plan['userId'];
        await logUsecase.call(
          diagnosisId: widget.diagnosisId,
          userId: userId?.toString(),
          body:
              "\u0645\u0648\u0639\u062f \u0627\u0644\u062c\u0631\u0639\u0629 \u0627\u0644\u0642\u0627\u062f\u0645\u0629: ${nextDose['date']}",
          scheduledAt: tzDoseDate.toLocal(),
        );
      } catch (_) {}
    } on PlatformException catch (pe) {
      // Known issue on Android 12+: exact alarms require permission
      // ignore: avoid_print
      print('[scheduleNextDose] PlatformException: ${pe.code} ${pe.message}');

      if (pe.code == 'exact_alarms_not_permitted' ||
          (pe.message ?? '').contains('exact')) {
        // Offer user to open settings to enable exact alarms (API 31+)
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('مطلوب إذن'),
              content: const Text(
                'يتطلب جدولة إشعارات دقيقة إذناً من نظام أندرويد. هل تريد فتح إعدادات التطبيق لتمكين الإذن؟',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('إلغاء'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    const channel = MethodChannel(
                      'app.channel.schedule_exact_alarm',
                    );
                    try {
                      await channel.invokeMethod('requestExactAlarm');
                    } catch (e) {
                      // ignore: avoid_print
                      print('[scheduleNextDose] requestExactAlarm failed: $e');
                    }
                    if (mounted)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'افتح إعدادات التطبيق وافعل إذن "الجرعات الدقيقة"',
                          ),
                        ),
                      );
                  },
                  child: const Text('فتح الإعدادات'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      // other errors - ignore for now but log
      // ignore: avoid_print
      print('[scheduleNextDose] error scheduling local notification: $e');
    }
  }

  // Format DateTime as DD/MM/YYYY HH:MM (local time)
  String _formatDateTime(DateTime dt) {
    final l = dt.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year} ${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }

  // Arabic relative string (minutes precision)
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

  String _arabicDoseNumber(int n) {
    // ١ ٢ ٣ ٤ ...
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: softBg,
        appBar: AppBar(
          backgroundColor: cardBg,
          elevation: 0.5,
          title: const Text(
            'تفاصيل التشخيص',
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
              : planData == null
              ? const Center(
                  child: Text(
                    'لا توجد بيانات متاحة',
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
                        _buildPlanHeader(),
                        const SizedBox(height: 16),
                        _buildDoseTable(),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildPlanHeader() {
    final data = planData!;
    return Center(
      child: Column(
        children: [
          const Text(
            'تتبع خطة العلاج والجرعات',
            style: TextStyle(color: Color(0xFF4A5565), fontSize: 15),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Builder(
                      builder: (ctx) {
                        final imgVal = data['imageUrl'] ?? data['image'] ?? '';
                        final imgStr = imgVal == null ? '' : imgVal.toString();

                        // Empty -> default asset
                        if (imgStr.isEmpty) {
                          return Image.asset(
                            'assets/leaf.png',
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          );
                        }

                        // data URI (base64)
                        if (imgStr.startsWith('data:') &&
                            imgStr.contains('base64,')) {
                          try {
                            final base64Part = imgStr.split('base64,').last;
                            final bytes = base64Decode(base64Part);
                            return Image.memory(
                              bytes,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                            );
                          } catch (_) {
                            return Container(
                              width: 70,
                              height: 70,
                              color: stepBg,
                              child: const Icon(
                                Icons.broken_image,
                                color: Color(0xFF016630),
                              ),
                            );
                          }
                        }

                        // Plain base64 (no data: prefix)
                        final base64Regex = RegExp(r'^[A-Za-z0-9+/=\s]+$');
                        if (imgStr.length > 100 &&
                            base64Regex.hasMatch(imgStr)) {
                          try {
                            final bytes = base64Decode(
                              imgStr.replaceAll('\n', '').replaceAll('\r', ''),
                            );
                            return Image.memory(
                              bytes,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                            );
                          } catch (_) {
                            // fallthrough to other handlers
                          }
                        }

                        // Full network URL
                        if (imgStr.startsWith('http')) {
                          return Image.network(
                            imgStr,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 70,
                                height: 70,
                                color: stepBg,
                                child: const Icon(
                                  Icons.crop_landscape,
                                  color: Color(0xFF016630),
                                  size: 32,
                                ),
                              );
                            },
                          );
                        }

                        // Relative path returned by API (e.g., '/uploads/..' or 'uploads/..')
                        if (imgStr.startsWith('/') ||
                            imgStr.startsWith('uploads') ||
                            imgStr.contains('/')) {
                          final host = Config.apiBaseUrl;
                          final tryUrl = imgStr.startsWith('/')
                              ? host + imgStr
                              : '$host/$imgStr';
                          return Image.network(
                            tryUrl,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/leaf.png',
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                              );
                            },
                          );
                        }

                        // Fallback: try as bundled asset path, else default
                        try {
                          return Image.asset(
                            imgStr,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/leaf.png',
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                              );
                            },
                          );
                        } catch (_) {
                          return Image.asset(
                            'assets/leaf.png',
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['diseaseName'] ?? '',
                          style: TextStyle(
                            color: primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
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
                              data['diagnosisDate'] ?? '',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF4A5565),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const SizedBox(height: 8),
                        const Text(
                          'تقدم العلاج',
                          style: TextStyle(
                            color: Color(0xFF4A5565),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${data['executedDoses'] ?? 0} من ${data['totalDoses'] ?? 0} جرعات',
                              style: TextStyle(
                                fontSize: 13,
                                color: primaryGreen,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: LinearProgressIndicator(
                                value:
                                    (data['executedDoses'] ?? 0) /
                                    ((data['totalDoses'] ?? 1) as num),
                                backgroundColor: progressBg,
                                color: progressBar,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoseTable() {
    final doses = planData!['doses'] as List<dynamic>? ?? [];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: stepBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.volume_up, color: primaryGreen, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        'الاستماع',
                        style: TextStyle(
                          color: primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'جدول الجرعات',
                  style: TextStyle(
                    color: primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Icon(Icons.medication, color: primaryGreen),
              ],
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < doses.length; i++) ...[
              _buildDoseStep(doses[i] as Map<String, dynamic>),
              if (i < doses.length - 1) _buildStepLine(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDoseStep(Map<String, dynamic> dose) {
    final String status = dose['status'] ?? '';
    Color statusColor;
    IconData icon;
    Color iconColor;
    switch (status) {
      case 'تم التنفيذ بنجاح':
        statusColor = stepSuccessText;
        icon = Icons.check_circle;
        iconColor = stepGreen;
        break;
      case 'تأكيد تنفيذ الجرعة':
        statusColor = stepPendingText;
        icon = Icons.edit;
        iconColor = stepBlue;
        break;
      default:
        statusColor = stepInfoText;
        icon = Icons.info;
        iconColor = stepGray;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: stepBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: stepBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dose['title'] ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: primaryGreen,
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
                    Builder(
                      builder: (_) {
                        final dateStr = (dose['date'] ?? '').toString();
                        final dt = DateTime.tryParse(dateStr);
                        final primary = dt != null
                            ? _formatDateTime(dt)
                            : dateStr.split('T').first;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              primary,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF4A5565),
                              ),
                            ),
                            if (dt != null &&
                                (dose['status'] == 'تأكيد تنفيذ الجرعة' ||
                                    dose['status'] == 'بانتظار التنفيذ'))
                              Text(
                                _timeRemainingString(dt),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      'المبيد المستخدم:',
                      style: TextStyle(fontSize: 13, color: Color(0xFF4A5565)),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dose['pesticide'] ?? '',
                      style: TextStyle(fontSize: 13, color: primaryGreen),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 13,
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                if (status == 'تأكيد تنفيذ الجرعة')
                  ElevatedButton.icon(
                    onPressed: _confirming ? null : _confirmDose,
                    icon: _confirming
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: Text(
                      _confirming ? 'جارٍ التأكيد...' : 'تأكيد تنفيذ الجرعة',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      width: 2,
      height: 32,
      color: stepBorder,
    );
  }


}
