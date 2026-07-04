// use io prefix for file operations

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' as io;
import 'package:flutter_application_55555/core/widgets/listen_widget.dart';

import '../../domain/usecases/diagnose.dart';
import '../cubit/diagnosis_screen_cubit.dart';
import '../injection/diagnosis_injection.dart';

// Feature UI must not initialize the service locator; main.dart does that.

/// شاشة التشخيص - دعم التقاط/اختيار صورة ورفعها إلى API
class DiagnosisScreen extends StatefulWidget {
  const DiagnosisScreen({super.key});

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  late final DiagnosisScreenCubit _cubit;

  // using ListenWidget for tips playback

  @override
  void initState() {
    super.initState();
    _cubit = DiagnosisScreenCubit(context.read<Diagnose>());
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DiagnosisScreenCubit>.value(
      value: _cubit,
      child: BlocBuilder<DiagnosisScreenCubit, DiagnosisScreenState>(
        builder: (context, state) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                title: const Text(
                  'تشخيص أمراض العنب',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
              ),
              body: SafeArea(
                top: false,
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        const SizedBox(height: 8),
                        const Text(
                          'التقط صورة واضحة للأوراق المصابة للحصول على تشخيص دقيق',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        _buildImagePickerCard(state),
                        const SizedBox(height: 24),
                        _buildTipsCard(state),
                        const SizedBox(height: 16),
                        if (state.resultMessage != null)
                          Card(
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                state.resultMessage!,
                                style: const TextStyle(color: Colors.green),
                              ),
                            ),
                          ),
                        if (state.errorMessage != null)
                          Card(
                            color: Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                state.errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (state.isUploading) _buildLoadingOverlay(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImagePickerCard(DiagnosisScreenState state) {
    if (state.pickedFile == null) {
      return _buildEmptyStateCard(state);
    } else {
      return _buildImagePreviewCard(state);
    }
  }

  Widget _buildEmptyStateCard(DiagnosisScreenState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.upload, size: 72, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'اختر طريقة رفع الصورة',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'التقط صورة جديدة أو اختر من المعرض',
            style: TextStyle(fontSize: 16, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  label: const Text(
                    'التقاط صورة',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: state.isUploading
                      ? null
                      : () => _pickImage(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.green),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.photo_library, color: Colors.green),
                  label: const Text(
                    'اختيار من المعرض',
                    style: TextStyle(color: Colors.green),
                  ),
                  onPressed: state.isUploading
                      ? null
                      : () => _pickImage(ImageSource.gallery),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreviewCard(DiagnosisScreenState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: state.isUploading
                ? null
                : () {
                    showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        child: InteractiveViewer(
                          child: Image.file(io.File(state.pickedFile!.path)),
                        ),
                      ),
                    );
                  },
            child: Image.file(
              io.File(state.pickedFile!.path),
              height: 300,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  ' تم اختيار الصورة بنجاح',
                  style: TextStyle(color: Colors.green, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.refresh, color: Colors.green),
                  label: const Text(
                    'تغيير الصورة',
                    style: TextStyle(color: Colors.green),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.green),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: state.isUploading
                      ? null
                      : () => _pickImage(ImageSource.gallery),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text(
                    'حذف الصورة',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: state.isUploading ? null : _cubit.clearPickedImage,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.search, color: Colors.white),
            label: const Text(
              'ابدأ التشخيص',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: state.isUploading ? null : _uploadImage,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.4),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'جارٍ تحليل الصورة...',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'قد يستغرق ذلك 10–20 ثانية',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipsCard(DiagnosisScreenState state) {
    const tipsMarkdown =
        '- صوّر في ضوء النهار\n- اجعل الورقة واضحة\n- تجنب الظلال\n- اقترب من مكان الإصابة';

    return ListenWidget(
      contentId: 'diagnosis_tips',
      title: 'نصائح لصورة أفضل',
      shortDescription: null,
      markdownContent: tipsMarkdown,
      playerTitle: 'نصائح الصورة',
      builder: (context, scope) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 248, 255, 249),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color.fromARGB(255, 123, 255, 130)),
          ),
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: EdgeInsets.only(bottom: scope.extraBottomPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // examples row before textual tips (kept unchanged)
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: state.isUploading
                                ? null
                                : () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => Dialog(
                                        child: InteractiveViewer(
                                          child: Image.asset(
                                            'assets/exp_trueimg.jpg',
                                            fit: BoxFit.contain,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Padding(
                                                      padding: EdgeInsets.all(
                                                        24,
                                                      ),
                                                      child: Icon(
                                                        Icons.image,
                                                        size: 96,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                            child: Container(
                              height: 200,
                              width: 200,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'مثال صورة صحيحة',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        Center(
                                          child: Image.asset(
                                            'assets/exp_trueimg.jpg',
                                            width: 180,
                                            height: 180,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(
                                                      Icons.image,
                                                      size: 36,
                                                      color: Colors.grey,
                                                    ),
                                          ),
                                        ),
                                        const Positioned(
                                          top: 4,
                                          right: 4,
                                          child: CircleAvatar(
                                            radius: 12,
                                            backgroundColor: Colors.white,
                                            child: Icon(
                                              Icons.check,
                                              color: Colors.green,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: state.isUploading
                                ? null
                                : () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => Dialog(
                                        child: InteractiveViewer(
                                          child: Image.asset(
                                            'assets/exp_falseimg.jpg',
                                            fit: BoxFit.contain,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Padding(
                                                      padding: EdgeInsets.all(
                                                        24,
                                                      ),
                                                      child: Icon(
                                                        Icons.broken_image,
                                                        size: 96,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                            child: Container(
                              height: 200,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red.shade200,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'مثال صورة غير واضحة',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        Center(
                                          child: Image.asset(
                                            'assets/exp_falseimg.jpg',
                                            width: 180,
                                            height: 180,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(
                                                      Icons.broken_image,
                                                      size: 36,
                                                      color: Colors.grey,
                                                    ),
                                          ),
                                        ),
                                        const Positioned(
                                          top: 4,
                                          right: 4,
                                          child: CircleAvatar(
                                            radius: 12,
                                            backgroundColor: Colors.white,
                                            child: Icon(
                                              Icons.close,
                                              color: Colors.red,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // title + listen button from ListenWidget
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'نصائح لصورة أفضل',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        scope.listenButton,
                      ],
                    ),
                    const SizedBox(height: 12),
                    // markdown body provided by ListenWidget
                    scope.markdownBody,
                  ],
                ),
              ),
              // bottom player overlay
              scope.bottomPlayer,
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    await _cubit.pickImage(source, onError: _showErrorDialog);
  }

  Future<void> _uploadImage() async {
    await _cubit.uploadImage(
      onError: _showErrorDialog,
      onSuccess: (result, imagePath) {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => buildDiagnosisResultScreen(
                result: result,
                imagePath: imagePath,
              ),
            ),
          );
        }
      },
    );
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حدث خطأ'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }
}
