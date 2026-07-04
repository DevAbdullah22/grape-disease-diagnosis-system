import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _openUri(BuildContext context, Uri uri) async {
    try {
      if (!await canLaunchUrl(uri)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكن فتح الرابط'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      await launchUrl(uri);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('فشل في فتح الرابط'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const darkGreen = Color(0xFF016630);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FFFB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          centerTitle: true,
          title: const Text(
            'الدعم الفني',
            style: TextStyle(
              color: darkGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: const IconThemeData(color: darkGreen),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                const Center(
                  child: Icon(
                    Icons.support_agent,
                    size: 68,
                    color: darkGreen,
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'كيف نساعدك؟',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Buttons
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    final uri = Uri.parse('tel:+966XXXXXXXXX');
                    await _openUri(context, uri);
                  },
                  child: Row(
                    children: const [
                      Icon(Icons.phone, size: 22, color: Colors.white),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'اتصل بالدعم',
                          textAlign: TextAlign.start,
                          style: TextStyle(fontSize: 17, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    final uri = Uri.parse('https://wa.me/966XXXXXXXXX');
                    await _openUri(context, uri);
                  },
                  child: Row(
                    children: const [
                      Icon(Icons.chat, size: 22, color: Colors.white),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'تواصل عبر واتساب',
                          textAlign: TextAlign.start,
                          style: TextStyle(fontSize: 17, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkGreen,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    final uri = Uri.parse('mailto:support@example.com');
                    await _openUri(context, uri);
                  },
                  child: Row(
                    children: const [
                      Icon(Icons.email, size: 22, color: Colors.white),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'إرسال بريد إلكتروني',
                          textAlign: TextAlign.start,
                          style: TextStyle(fontSize: 17, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF8F0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'إذا واجهتك مشكلة في التشخيص، أرسل صورة واضحة للورقة المصابة.',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
