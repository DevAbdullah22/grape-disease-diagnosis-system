import 'package:flutter/material.dart';
import 'package:flutter_application_55555/features/auth/data/repositories/auth_repository.dart';
import 'package:flutter_application_55555/core/services/fcm_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_55555/core/services/backend_service.dart';
import 'package:flutter_application_55555/features/profile/application/profile_controller.dart';
import 'package:flutter_application_55555/features/support/presentation/screens/support_screen.dart';

void main() {
  runApp(MaterialApp(home: ProfileScreen()));
}

/// شاشة الملف الشخصي - تصميم متجاوب بالكامل ويدعم العربية
/// الفصل بين المنطق وواجهة المستخدم (UI فقط)
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileController _controller = ProfileController(
    backendService: BackendService(),
    authRepository: AuthRepository(),
    firebaseAuth: FirebaseAuth.instance,
    sendFcmTokenToBackend: FcmService.sendFcmTokenToBackend,
  );

  // متغيرات حالة السويتشات (يفترض أن تأتي من Repository)
  bool reminderEnabled = false;
  bool weatherEnabled = false;
  bool tipsEnabled = false;
  bool libraryUpdatesEnabled = false;

  // خارطة تحميل لكل خيار، حتى لا نجمد الشاشة بأكملها
  final Map<String, bool> _loadingStates = {};

  bool isLoading = false;
  String? errorMessage;
  String? fullName;
  String? photoUrl;
  String? location;

  @override
  void initState() {
    super.initState();
    _loadProfileAndSubscriptions();
  }

  Future<void> _loadProfileAndSubscriptions() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final result = await _controller.loadProfileAndSubscriptions();
    reminderEnabled = result.reminderEnabled;
    weatherEnabled = result.weatherEnabled;
    tipsEnabled = result.tipsEnabled;
    libraryUpdatesEnabled = result.libraryUpdatesEnabled;
    errorMessage = result.errorMessage;
    fullName = result.fullName;
    photoUrl = result.photoUrl;
    location = result.location;

    if (mounted) setState(() => isLoading = false);
  }

  // مثال على معالجة تبديل السويتش مع حالة تحميل
  Future<void> _toggleSwitch(Function(bool) setter, bool value) async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      // هنا يفترض استدعاء repository وتحديث الحالة
      await Future.delayed(const Duration(milliseconds: 200));
      setter(value);
    } catch (e) {
      errorMessage = 'حدث خطأ أثناء تحديث الإعدادات';
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Toggle and update backend subscription (with per-switch loading state)
  Future<void> _toggleAndUpdate(String type, Function(bool) setter, bool value) async {
    setState(() {
      _loadingStates[type] = true;
      errorMessage = null;
    });
    final result = await _controller.updateSubscription(type: type, value: value);
    if (result.success) {
      setter(value);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ الإعداد'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${result.error}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
    if (mounted) setState(() => _loadingStates[type] = false);
  }

  Future<void> _handleLogout() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final result = await _controller.signOut();
      if (!mounted) return;
      if (result.success) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushNamedAndRemoveUntil('/login', (r) => false);
      } else {
        setState(() {
          errorMessage = result.message;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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
          leading: IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {},
            tooltip: 'القائمة',
          ),
          title: const Text(
            'تشخيص أمراض العنب',
            style: TextStyle(
              color: Color(0xFF016630),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: isLoading
            ? const SafeArea(
                top: false,
                child: Center(child: CircularProgressIndicator()),
              )
            : SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // بطاقة المستخدم محسّنة
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 18),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C950),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 34,
                                  backgroundColor: Colors.white24,
                                  backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
                                      ? NetworkImage(photoUrl!) as ImageProvider
                                      : null,
                                  child: (photoUrl == null || photoUrl!.isEmpty)
                                      ? Text(
                                          (fullName != null && fullName!.trim().isNotEmpty)
                                              ? fullName!.trim()[0].toUpperCase()
                                              : 'م',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                               
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              fullName ?? 'مستخدم',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                          
                          ],
                        ),
                      ),
                      // إعدادات التنبيهات مع تحسينات بصرية
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
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
                            Row(
                              children: const [
                                Icon(
                                  Icons.notifications_active_outlined,
                                  color: Color(0xFF016630),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'تنبيهات سريعة',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            _buildSwitchRow(
                              title: 'تنبيه موعد العلاج',
                              value: reminderEnabled,
                              loading: _loadingStates['Treatment'] ?? false,
                              onChanged: (v) => _toggleAndUpdate(
                                'Treatment',
                                (val) => setState(() => reminderEnabled = val),
                                v,
                              ),
                            ),
                            _buildSwitchRow(
                              title: 'تنبيه طقس مهم',
                              value: weatherEnabled,
                              loading: _loadingStates['Weather'] ?? false,
                              onChanged: (v) => _toggleAndUpdate(
                                'Weather',
                                (val) => setState(() => weatherEnabled = val),
                                v,
                              ),
                            ),
                            _buildSwitchRow(
                              title: 'نصائح الموسم',
                              value: tipsEnabled,
                              loading: _loadingStates['Recommendations'] ?? false,
                              onChanged: (v) => _toggleAndUpdate(
                                'Recommendations',
                                (val) => setState(() => tipsEnabled = val),
                                v,
                              ),
                            ),
                            _buildSwitchRow(
                              title: 'جديد في المكتبة',
                              value: libraryUpdatesEnabled,
                              loading: _loadingStates['Library'] ?? false,
                              onChanged: (v) => _toggleAndUpdate(
                                'Library',
                                (val) => setState(() => libraryUpdatesEnabled = val),
                                v,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Center(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      // خيارات أخرى
                      _buildOptionButton(
                        'المساعدة والدعم',
                        Icons.help_outline,
                        () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SupportScreen()),
                          );
                        },
                      ),
                      _buildOptionButton(
                        'الخصوصية والأمان',
                        Icons.privacy_tip_outlined,
                        () {},
                      ),
                      const SizedBox(height: 8),
                      // زر تسجيل الخروج
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.logout, color: Colors.red),
                          label: const Text(
                            'تسجيل الخروج',
                            style: TextStyle(color: Colors.red),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: _handleLogout,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    
      ),
    );
  }

  // عنصر تبديل إعداد مبسّط (سطر واحد)
  Widget _buildSwitchRow({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool loading = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ),
          if (loading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          Transform.scale(
            scale: 1.2,
            child: Switch(
              value: value,
              onChanged: loading ? null : onChanged,
              activeColor: const Color(0xFF00C950),
            ),
          ),
        ],
      ),
    );
  }

  // زر خيار إضافي
  Widget _buildOptionButton(String label, IconData icon, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: Icon(icon, color: const Color(0xFF016630)),
          label: Text(label, style: const TextStyle(color: Color(0xFF016630))),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFE0E0E0)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onPressed: onTap,
        ),
      ),
    );
  }
}
