import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthResult {
  final bool success;
  final String? message;
  final User? user;

  AuthResult({
    required this.success,
    this.message,
    this.user,
  });
}

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  // =========================================================
  // Google Sign-In
  // =========================================================
 Future<AuthResult> signInWithGoogle() async {
  try {
    // 🔥 امسح أي جلسة قديمة أولًا
    await _auth.signOut();
    await _googleSignIn.signOut();

    final GoogleSignInAccount? googleUser =
        await _googleSignIn.signIn();

    if (googleUser == null) {
      return AuthResult(
        success: false,
        message: "تم إلغاء تسجيل الدخول عبر Google",
      );
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential =
        await _auth.signInWithCredential(credential);

    return AuthResult(
      success: true,
      user: userCredential.user,
    );
  } catch (e) {
    return AuthResult(
      success: false,
      message: "حدث خطأ أثناء Google Sign-In",
    );
  }
}

  // =========================================================
  // Email Sign-In
  // =========================================================
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential =
          await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = credential.user;

      if (user != null && !user.emailVerified) {
        await _auth.signOut();
        return AuthResult(
          success: false,
          message:
              'يرجى تفعيل البريد الإلكتروني قبل تسجيل الدخول.',
        );
      }

      return AuthResult(
        success: true,
        user: user,
      );
    } on FirebaseAuthException catch (e) {
      String msg;

      switch (e.code) {
        case 'invalid-email':
          msg = 'صيغة البريد الإلكتروني غير صحيحة.';
          break;
        case 'user-not-found':
          msg = 'لا يوجد مستخدم بهذا البريد.';
          break;
        case 'wrong-password':
          msg = 'كلمة المرور غير صحيحة.';
          break;
        case 'user-disabled':
          msg = 'هذا الحساب معطل.';
          break;
        case 'too-many-requests':
          msg = 'محاولات كثيرة. حاول لاحقاً.';
          break;
        default:
          msg = 'خطأ في تسجيل الدخول.';
      }

      return AuthResult(success: false, message: msg);
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'خطأ غير معروف أثناء تسجيل الدخول.',
      );
    }
  }

  // =========================================================
  // Sign Up
  // =========================================================
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final credential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = credential.user;

      if (user != null) {
        await user.updateDisplayName(fullName.trim());
        await user.sendEmailVerification();
        await _auth.signOut();
      }

      return AuthResult(
        success: true,
        message:
            'تم إنشاء الحساب. تحقق من بريدك الإلكتروني.',
      );
    } on FirebaseAuthException catch (e) {
      String msg;

      switch (e.code) {
        case 'weak-password':
          msg = 'كلمة المرور ضعيفة.';
          break;
        case 'email-already-in-use':
          msg = 'البريد مستخدم مسبقاً.';
          break;
        case 'invalid-email':
          msg = 'صيغة البريد غير صحيحة.';
          break;
        default:
          msg = 'خطأ في إنشاء الحساب.';
      }

      return AuthResult(success: false, message: msg);
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'خطأ غير معروف أثناء إنشاء الحساب.',
      );
    }
  }

  // =========================================================
  // Reset Password
  // =========================================================
  Future<AuthResult> resetPassword({
    required String email,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(
        email: email.trim(),
      );

      return AuthResult(
        success: true,
        message: 'تم إرسال رابط إعادة التعيين.',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'خطأ أثناء الإرسال.',
      );
    }
  }

  // =========================================================
  // Sign Out
  // =========================================================
  Future<AuthResult> signOut() async {
    try {
      // attempt Google sign-out if applicable, but ignore failures
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // not a Google user or already signed out
      }

      // firebase sign-out only if a user is logged in
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }

      return AuthResult(
        success: true,
        message: 'تم تسجيل الخروج بنجاح',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'خطأ أثناء تسجيل الخروج.',
      );
    }
  }
}