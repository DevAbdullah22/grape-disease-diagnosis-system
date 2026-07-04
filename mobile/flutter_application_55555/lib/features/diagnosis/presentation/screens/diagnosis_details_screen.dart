import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io' as io;
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

import 'package:flutter_application_55555/core/widgets/listen_widget.dart';
import 'package:flutter_application_55555/features/diagnosis/presentation/cubit/diagnosis_details_cubit.dart';
import 'package:flutter_application_55555/features/diagnosis/presentation/screens/treatment_recommendations_screen.dart';

/// شاشة تفاصيل التشخيص
class DiagnosisDetailsScreen extends StatelessWidget {
  final DiagnosisDetailsCubit cubit;
  final String diagnosisId;
  final String? imageUrl;
  final DateTime? date;
  final String? disease;
  final String? status;
  final double? confidence;
  final List<String>? referenceImages;
  final String? description;

  const DiagnosisDetailsScreen({
    Key? key,
    required this.cubit,
    required this.diagnosisId,
    this.imageUrl,
    this.date,
    this.disease,
    this.status,
    this.confidence,
    this.referenceImages,
    this.description,
  }) : super(key: key);

  static const Color primaryGreen = Color(0xFF016630);
  static const Color softBg = Color(0xFFF3FFF7);
  static const Color tagGreen = Color(0xFFCFFFE3);
  static const Color tagTextGreen = Color(0xFF008236);
  static const Color dangerRed = Color(0xFFDC2626);
  static const Color neutralText = Color(0xFF4A5565);

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cubit,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: softBg,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            title: const Text(
              'تفاصيل التشخيص',
              style: TextStyle(
                color: primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.green),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          body: SafeArea(
            top: false,
            child: BlocBuilder<DiagnosisDetailsCubit, DiagnosisDetailsState>(
              builder: (context, state) {
                if (state is DiagnosisDetailsInitial ||
                    state is DiagnosisDetailsLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is DiagnosisDetailsError) {
                  return _buildError(state.message, context);
                } else if (state is DiagnosisDetailsLoaded) {
                  return _buildContent(context, state);
                } else {
                  return Container();
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(String msg, BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(msg, style: const TextStyle(color: dangerRed)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              context.read<DiagnosisDetailsCubit>().fetch(
                diagnosisId,
                imageUrl: imageUrl,
                date: date,
                disease: disease,
                status: status,
                confidence: confidence,
                referenceImages: referenceImages,
                description: description,
              );
            },
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, DiagnosisDetailsLoaded state) {
    final details = state.details;
    final displayDate = state.initialDate;
    final displayDisease =
        state.initialDisease ?? details.diseaseName ?? 'غير محدد';
    final displayStatus = _statusLabel(
      state.initialStatus ?? details.status ?? 'غير معروف',
    );
    final descriptionText =
        state.initialDescription ?? details.description ?? 'لا يوجد وصف متاح';
    final hasDiagnosisId = diagnosisId.trim().isNotEmpty;
    final refImages = state.initialReferenceImages ?? details.referenceImages;
    final navDisease = state.initialDisease ?? details.diseaseName ?? '';
    final navConfidence = state.initialConfidence ?? details.confidence;
    final navDescription =
        state.initialDescription ?? details.description ?? '';
    final navImageUrl = state.initialImageUrl ?? details.imageUrl;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            _buildHeroCard(
              displayDisease: displayDisease,
              displayStatus: displayStatus,
              displayDate: displayDate,
              imageUrl: navImageUrl,
            ),
            const SizedBox(height: 12),
            _buildReferenceImagesCard(refImages),
            const SizedBox(height: 12),
            const SizedBox(height: 16),
            _buildDescriptionCardWithAudio(descriptionText),
            const SizedBox(height: 16),
            _buildActions(
              context: context,
              hasDiagnosisId: hasDiagnosisId,
              diseaseForNavigation: navDisease,
              confidenceForNavigation: navConfidence,
              descriptionForNavigation: navDescription,
              imageUrlForNavigation: navImageUrl,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'غير متوفر';
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  // Convert raw status values (English / Arabic) into a user-friendly Arabic label.
  String _statusLabel(String? status) {
    final s = (status ?? '').toLowerCase();
    if (s.contains('not') && s.contains('treated')) return 'غير مُعالَج';
    if (s.contains('معالج') || (s.contains('treated') && !s.contains('not')))
      return 'تمت المعالجة';
    if (s.contains('قيد') || s.contains('progress')) return 'قيد المعالجة';
    return status?.trim() ?? 'غير معروف';
  }

  Widget _chip({
    required String label,
    required Color textColor,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: neutralText,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildListenIcon(ListenRenderScope scope) {
    return IconButton(
      onPressed: scope.toggleSpeak,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      visualDensity: VisualDensity.compact,
      splashRadius: 18,
      tooltip: scope.isSpeaking ? 'إيقاف الاستماع' : 'تشغيل الاستماع',
      icon: Icon(
        scope.isSpeaking
            ? Icons.pause_circle_outline_rounded
            : Icons.volume_up_rounded,
        color: primaryGreen,
        size: 22,
      ),
    );
  }

  Widget _buildImage(String? url) {
    if (url == null || url.isEmpty) return _imageFallback();

    if (url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _imageFallback(),
      );
    }
    if (url.startsWith('file://') || url.startsWith('content://')) {
      try {
        final file = io.File(Uri.parse(url).toFilePath());
        if (file.existsSync()) {
          return Image.file(file, fit: BoxFit.cover);
        }
      } catch (_) {}
    }
    try {
      final file = io.File(url);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    } catch (_) {}
    return _imageFallback();
  }

  Widget _imageFallback() {
    return Container(
      color: const Color(0xFFEAF8EE),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.crop_landscape, size: 48, color: primaryGreen),
          const SizedBox(height: 12),
          Text('الصورة غير متوفرة', style: TextStyle(color: primaryGreen)),
        ],
      ),
    );
  }

  Widget _buildHeroCard({
    required String displayDisease,
    required String displayStatus,
    required DateTime? displayDate,
    String? imageUrl,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildImage(imageUrl),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.eco, color: primaryGreen),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        displayDisease,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(
                      label: displayStatus,
                      textColor: tagTextGreen,
                      background: tagGreen,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Colors.grey,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(displayDate),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceImagesCard(List<String>? images) {
    return _sectionCard(
      title: 'صور مشابهة للحالة',
      child: (images == null || images.isEmpty)
          ? Center(
              child: Text(
                'لا توجد صور مرجعية',
                style: TextStyle(color: neutralText, fontSize: 14),
              ),
            )
          : SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final imageUrl = images[index];
                  Widget thumb;
                  if (imageUrl.startsWith('http')) {
                    thumb = Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: 160,
                      height: 120,
                      errorBuilder: (c, e, s) => _imageFallback(),
                    );
                  } else {
                    thumb = Image.file(
                      io.File(imageUrl),
                      fit: BoxFit.cover,
                      width: 160,
                      height: 120,
                      errorBuilder: (c, e, s) => _imageFallback(),
                    );
                  }

                  return GestureDetector(
                    onTap: () => _showImageFull(context, imageUrl),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: thumb,
                    ),
                  );
                },
              ),
            ),
    );
  }

  void _showImageFull(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: InteractiveViewer(
              child: imageUrl.startsWith('http')
                  ? Image.network(
                      imageUrl,
                      errorBuilder: (c, e, s) => _imageFallback(),
                    )
                  : Image.file(
                      io.File(imageUrl),
                      errorBuilder: (c, e, s) => _imageFallback(),
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDescriptionCard(String descriptionText) {
    return _sectionCard(
      title: 'الوصف',
      child: Text(
        descriptionText,
        style: const TextStyle(
          color: Color(0xFF1E2939),
          fontSize: 15,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildDescriptionCardWithAudio(String descriptionText) {
    return ListenWidget(
      key: const ValueKey('diagnosis_description_card'),
      contentId: 'diagnosis_description_${descriptionText.hashCode}',
      title: 'الوصف',
      shortDescription: null,
      markdownContent: descriptionText,
      playerTitle: 'الوصف',
      builder: (context, scope) => Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: scope.extraBottomPadding),
            child: _sectionCard(
              title: 'الوصف',
              trailing: descriptionText.trim().isNotEmpty
                  ? _buildListenIcon(scope)
                  : null,
              child: Text(
                descriptionText,
                style: const TextStyle(
                  color: Color(0xFF1E2939),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ),
          ),
          scope.bottomPlayer,
        ],
      ),
    );
  }

  Widget _buildActions({
    required BuildContext context,
    required bool hasDiagnosisId,
    required String diseaseForNavigation,
    required double? confidenceForNavigation,
    required String descriptionForNavigation,
    required String? imageUrlForNavigation,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00C950),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          icon: const Icon(Icons.remove_red_eye, color: Colors.white),
          label: const Text(
            'المونتجات الموصى بها',
            style: TextStyle(color: Colors.white),
          ),
          onPressed: hasDiagnosisId
              ? () {
                  final imagePath = imageUrlForNavigation?.trim();
                  final hasImage = imagePath != null && imagePath.isNotEmpty;
                  final isNetworkImage =
                      hasImage && imagePath.startsWith('http');

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          TreatmentRecommendationsScreen.withProvider(
                            diseaseName: diseaseForNavigation,
                            diagnosisId: diagnosisId,
                            confidence: confidenceForNavigation,
                            description: descriptionForNavigation,
                            diseaseImageUrl: isNetworkImage ? imagePath : null,
                            diagnosisImagePath: hasImage && !isNetworkImage
                                ? imagePath
                                : null,
                          ),
                    ),
                  );
                }
              : null,
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFB9F8CF)),
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          icon: const Icon(Icons.share, color: Color(0xFF008236)),
          label: const Text(
            'مشاركة',
            style: TextStyle(color: Color(0xFF008236)),
          ),
          onPressed: () => _shareDiagnosis(
            context,
            diseaseName: diseaseForNavigation,
            descriptionText: descriptionForNavigation,
            imageUrl: imageUrlForNavigation,
          ),
        ),
      ],
    );
  }

  Future<void> _shareDiagnosis(
    BuildContext context, {
    required String diseaseName,
    required String descriptionText,
    required String? imageUrl,
  }) async {
    final cleanDisease = diseaseName.trim().isEmpty
        ? 'غير محدد'
        : diseaseName.trim();
    final cleanDescription = descriptionText.trim().isEmpty
        ? 'لا يوجد وصف متاح'
        : descriptionText.trim();

    final shareText = StringBuffer()
      ..writeln('اسم المرض: $cleanDisease')
      ..writeln()
      ..writeln('الوصف:')
      ..write(cleanDescription);

    try {
      final imagePath = await _resolveShareImagePath(imageUrl);
      if (imagePath != null && imagePath.isNotEmpty) {
        await Share.shareXFiles([XFile(imagePath)], text: shareText.toString());
        return;
      }

      await Share.share(shareText.toString());
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تعذر إرفاق الصورة، سيتم الاكتفاء بمشاركة النص.',
            textDirection: TextDirection.rtl,
          ),
        ),
      );

      try {
        await Share.share(shareText.toString());
      } catch (_) {}
    }
  }

  Future<String?> _resolveShareImagePath(String? imageUrl) async {
    final value = imageUrl?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }

    if (value.startsWith('http://') || value.startsWith('https://')) {
      final response = await http.get(Uri.parse(value));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        return null;
      }

      final extension = _imageExtensionFromPath(value);
      final file = io.File(
        '${io.Directory.systemTemp.path}\\diagnosis_share_${DateTime.now().millisecondsSinceEpoch}$extension',
      );
      await file.writeAsBytes(response.bodyBytes, flush: true);
      return file.path;
    }

    if (value.startsWith('file://')) {
      try {
        final file = io.File(Uri.parse(value).toFilePath());
        if (await file.exists()) {
          return file.path;
        }
      } catch (_) {
        return null;
      }
    }

    final file = io.File(value);
    if (await file.exists()) {
      return file.path;
    }

    return null;
  }

  String _imageExtensionFromPath(String path) {
    final uri = Uri.tryParse(path);
    final source = uri?.path.isNotEmpty == true ? uri!.path : path;
    final dotIndex = source.lastIndexOf('.');
    if (dotIndex == -1) {
      return '.jpg';
    }

    final extension = source.substring(dotIndex);
    return extension.length <= 5 ? extension : '.jpg';
  }
}
