import 'package:flutter/material.dart';
import 'package:flutter_application_55555/features/auth/data/repositories/auth_repository.dart';
import 'package:flutter_application_55555/core/services/backend_service.dart';
import 'package:flutter_application_55555/core/services/fcm_service.dart';
import 'package:flutter_application_55555/features/app/presentation/screens/main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthRepository _authRepository = AuthRepository();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  // ==============================
  // Google Sign-In
  // ==============================
  Future<void> _signInWithGoogle() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await _authRepository.signInWithGoogle();

      if (!mounted) return;

      if (result.success && result.user != null) {
        // Sync user to backend and send FCM token before navigating
        try {
          final backend = BackendService();
          await backend.sendUserToBackend(force: true);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('تعذّر مزامنة المستخدم مع الخادم: $e')),
            );
          }
        }

        try {
          await FcmService.sendFcmTokenToBackend();
        } catch (_) {}

        resetMainNavigationToHome(Directionality.of(context));
        Navigator.of(
          context,
          rootNavigator: true,
        ).pushNamedAndRemoveUntil('/home', (r) => false);
      } else {
        setState(() {
          errorMessage = result.message ?? 'فشل تسجيل الدخول عبر Google';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'فشل تسجيل الدخول عبر Google';
      });
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await _authRepository.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (result.success) {
        // إذا طلب تفعيل البريد
        if (result.message != null &&
            result.message!.contains('تفعيل البريد')) {
          setState(() {
            errorMessage = result.message;
          });
        } else {
          // مزامنة المستخدم مع الباكند
          try {
            final backend = BackendService();
            await backend.sendUserToBackend();
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('تعذر مزامنة المستخدم مع الخادم: $e')),
              );
            }
          }

          // إرسال FCM token
          try {
            await FcmService.sendFcmTokenToBackend();
          } catch (_) {}

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.message ?? 'تم تسجيل الدخول بنجاح!')),
          );

          // 🔥 لا يوجد Navigator هنا
          // تنظيف الستاك والانتقال للشاشة الرئيسية مباشرةً حتى
          // لا يبقى route '/login' فوق واجهة التطبيق.
          resetMainNavigationToHome(Directionality.of(context));
          Navigator.of(
            context,
            rootNavigator: true,
          ).pushNamedAndRemoveUntil('/home', (r) => false);
        }
      } else {
        setState(() {
          errorMessage = result.message ?? 'حدث خطأ غير متوقع.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'حدث خطأ أثناء تسجيل الدخول';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF3FFF7),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                      Image.asset(
                        'assets/grape_logo.png',
                        height: 70,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.image,
                          size: 70,
                          color: Colors.green,
                        ),
                      ),

                      const SizedBox(height: 12),
                      const Text(
                        'تسجيل الدخول',
                        style: TextStyle(
                          color: Color(0xFF016630),
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // ==============================
                      // Google Button
                      // ==============================
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: isLoading ? null : _signInWithGoogle,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFDDDDDD)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator()
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.g_mobiledata,
                                      color: Colors.red,
                                      size: 28,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      "المتابعة باستخدام Google",
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      /// البريد الإلكتروني
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text('البريد الإلكتروني'),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'أدخل بريدك الإلكتروني',
                          prefixIcon: const Icon(Icons.email_outlined),
                          filled: true,
                          fillColor: const Color(0xFFF3FFF7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'أدخل البريد الإلكتروني';
                          }
                          if (!v.contains('@')) {
                            return 'صيغة البريد غير صحيحة';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      /// كلمة المرور
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text('كلمة المرور'),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'أدخل كلمة المرور',
                          prefixIcon: const Icon(Icons.lock_outline),
                          filled: true,
                          fillColor: const Color(0xFFF3FFF7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) => v != null && v.length >= 6
                            ? null
                            : 'كلمة المرور ضعيفة',
                      ),

                      const SizedBox(height: 16),

                      if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                      /// زر تسجيل الدخول
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C950),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'تسجيل الدخول',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/forgot'),
                        child: const Text(
                          "نسيت كلمة المرور؟",
                          style: TextStyle(color: Color(0xFF016630)),
                        ),
                      ),

                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/signup'),
                        child: const Text(
                          'إنشاء حساب جديد',
                          style: TextStyle(color: Color(0xFF016630)),
                        ),
                      ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
