import 'package:flutter/material.dart';
import 'package:flutter_application_55555/features/auth/data/repositories/auth_repository.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthRepository _authRepository = AuthRepository();
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;
  String? errorMessage;

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final result = await _authRepository.resetPassword(
      email: _emailController.text.trim(),
    );

    if (result.success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message ??
                "تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك.",
          ),
        ),
      );
    } else {
      setState(() => errorMessage = result.message ?? 'حدث خطأ غير متوقع.');
    }

    setState(() => isLoading = false);
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
                        'إعادة تعيين كلمة المرور',
                        style: TextStyle(
                          color: Color(0xFF016630),
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // نص توضيحي
                      const Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          "أدخل بريدك الإلكتروني لإرسال رابط إعادة التعيين",
                          style: TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // البريد الإلكتروني
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
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: Colors.grey,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF3FFF7),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return "أدخل البريد الإلكتروني";
                          }
                          if (!RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(v.trim())) {
                            return "صيغة البريد الإلكتروني غير صحيحة";
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      // زر الإرسال
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _resetPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C950),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "إرسال رابط إعادة التعيين",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "رجوع إلى تسجيل الدخول",
                          style: TextStyle(
                            color: Color(0xFF016630),
                            fontWeight: FontWeight.bold,
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
}

// import 'package:flutter/material.dart';
// import 'package:flutter_application_55555/repositories/auth_repository.dart';

// class ForgotPasswordScreen extends StatefulWidget {
//   const ForgotPasswordScreen({super.key});

//   @override
//   State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
// }

// class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
//   final AuthRepository _authRepository = AuthRepository();
//   final TextEditingController _emailController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();

//   bool isLoading = false;
//   String? errorMessage;

//   Future<void> _resetPassword() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() {
//       isLoading = true;
//       errorMessage = null;
//     });

//     final result = await _authRepository.resetPassword(
//       email: _emailController.text.trim(),
//     );

//     if (result.success) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             result.message ??
//                 "تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك.",
//           ),
//         ),
//       );
//     } else {
//       setState(() => errorMessage = result.message ?? 'حدث خطأ غير متوقع.');
//     }

//     setState(() => isLoading = false);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("نسيت كلمة المرور")),
//       body: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               TextFormField(
//                 controller: _emailController,
//                 decoration: const InputDecoration(
//                   labelText: "البريد الإلكتروني",
//                 ),
//                 validator: (v) {
//                   if (v == null || v.trim().isEmpty) {
//                     return "أدخل البريد الإلكتروني";
//                   }
//                   if (!RegExp(
//                     r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
//                   ).hasMatch(v.trim())) {
//                     return "صيغة البريد الإلكتروني غير صحيحة";
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),
//               if (errorMessage != null)
//                 Text(errorMessage!, style: const TextStyle(color: Colors.red)),
//               const SizedBox(height: 12),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: isLoading ? null : _resetPassword,
//                   child: isLoading
//                       ? const CircularProgressIndicator(color: Colors.white)
//                       : const Text("إرسال رابط إعادة التعيين"),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
