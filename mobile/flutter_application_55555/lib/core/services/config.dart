/// ملف ضبط بسيط لتخزين عنوان الـ API المركزي
///
/// الهدف: تسهيل تغيير baseUrl من مكان واحد عند التطوير
/// (محليًا) أو النشر (production).
class Config {
  // Override at build/run time with:
  // --dart-define=API_BASE_URL=https://api.example.com
  static const String defaultApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5067',
  );

  /// يمكنك تغيير هذه القيمة عند بدء التطبيق إذا أردت
  /// مثال في main():
  /// Config.apiBaseUrl = 'https://api.example.com';
  static String apiBaseUrl = defaultApiBaseUrl;
}
