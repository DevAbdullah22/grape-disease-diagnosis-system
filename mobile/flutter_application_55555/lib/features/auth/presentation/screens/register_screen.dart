import 'package:flutter/material.dart';
import 'package:flutter_application_55555/features/auth/data/repositories/auth_repository.dart';
import 'package:flutter_application_55555/core/services/backend_service.dart';
import 'package:flutter_application_55555/core/services/fcm_service.dart';

class SignUpScreen extends StatefulWidget {
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final AuthRepository _authRepository = AuthRepository();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

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

      // check both success flag and returned user
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

        Navigator.pushReplacementNamed(context, '/home');
      } else {
        // canceled or failed - show message if available
        setState(() {
          errorMessage = result.message ?? "فشل تسجيل الدخول عبر Google";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "فشل تسجيل الدخول عبر Google";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // ==============================
  // Email Sign-Up
  // ==============================
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final result = await _authRepository.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _nameController.text.trim(),
      );

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("تم إنشاء الحساب! تحقق من بريدك الإلكتروني."),
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
        });
      } else {
        setState(() {
          errorMessage = result.message ?? "حدث خطأ غير متوقع";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                        'assets/grape_logo.png',
                        height: 70,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.image,
                                size: 70, color: Colors.green),
                      ),
                      const SizedBox(height: 12),
                       const Text(
                        "مرحبًا بك في تطبيق تشخيص أمراض عنب",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF016630),
                        ),
                      ),

                      // ==============================
                      // Google Button (احترافي)
                      // ==============================
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed:
                              isLoading ? null : _signInWithGoogle,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(
                              color: Color(0xFFDDDDDD),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator()
                              : Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
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

                      // خط فاصل
                      Row(
                        children: const [
                          Expanded(child: Divider()),
                          Padding(
                            padding:
                                EdgeInsets.symmetric(horizontal: 8),
                            child: Text("أو"),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        "إنشاء حساب جديد",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Color(0xFF016630),
                        ),
                      ),

                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: _nameController,
                        hint: "الاسم الكامل",
                        icon: Icons.person_outline,
                      ),

                      const SizedBox(height: 12),

                      _buildTextField(
                        controller: _emailController,
                        hint: "البريد الإلكتروني",
                        icon: Icons.email_outlined,
                        keyboardType:
                            TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 12),

                      _buildTextField(
                        controller: _passwordController,
                        hint: "كلمة المرور",
                        icon: Icons.lock_outline,
                        obscureText: true,
                      ),

                      const SizedBox(height: 16),

                      if (errorMessage != null)
                        Padding(
                          padding:
                              const EdgeInsets.only(bottom: 8),
                          child: Text(
                            errorMessage!,
                            style:
                                const TextStyle(color: Colors.red),
                          ),
                        ),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              isLoading ? null : _signUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF00C950),
                            padding:
                                const EdgeInsets.symmetric(
                                    vertical: 14),
                          ),
                          child: const Text(
                            "إنشاء حساب",
                            style: TextStyle(
                              color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType =
        TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: (v) {
        if (v == null || v.trim().isEmpty) {
          return "هذا الحقل مطلوب";
        }
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon:
            Icon(icon, color: const Color(0xFFBDBDBD)),
        filled: true,
        fillColor: const Color(0xFFF3FFF7),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
