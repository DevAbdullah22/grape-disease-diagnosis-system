import 'dart:io' as io;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_55555/core/widgets/listen_widget.dart';
import 'package:flutter_application_55555/features/diagnosis/presentation/cubit/diagnosis_result_screen_cubit.dart';
import 'package:flutter_application_55555/features/diagnosis/presentation/cubit/diagnosis_result_screen_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/diagnosis_result.dart';
import 'treatment_recommendations_screen.dart';

/// شاشة نتيجة التشخيص - تصميم متجاوب ودعم العربية وحالات التحميل والأخطاء
class DiagnosisResultScreen extends StatefulWidget {
  final DiagnosisResult result;
  final String? imagePath;

  const DiagnosisResultScreen({
    super.key,
    required this.result,
    this.imagePath,
  });

  @override
  State<DiagnosisResultScreen> createState() => _DiagnosisResultScreenState();
}

class _DiagnosisResultScreenState extends State<DiagnosisResultScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    // Slightly larger viewportFraction makes page swipes easier to trigger
    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diseaseTitle = widget.result.diseaseName.trim().isNotEmpty
        ? widget.result.diseaseName.trim()
        : 'غير معروف';
    final descriptionText = widget.result.description.trim();
    final listenContentId =
        'diagnosis-${widget.result.diagnosisId}-${widget.result.diseaseId}';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6FFF9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            'تشخيص أمراض العنب',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          top: false,
          child: MultiBlocListener(
            listeners: [
            BlocListener<
              DiagnosisResultScreenCubit,
              DiagnosisResultScreenState
            >(
              listenWhen: (previous, current) =>
                  previous.openTreatmentPlanVersion !=
                  current.openTreatmentPlanVersion,
              listener: (context, state) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TreatmentRecommendationsScreen.withProvider(
                      diseaseName: widget.result.diseaseName,
                      diagnosisId: widget.result.diagnosisId,
                      confidence: widget.result.confidence,
                      description: widget.result.description,
                      diseaseImageUrl: widget.result.imageUrl,
                      diagnosisImagePath: widget.imagePath,
                    ),
                  ),
                );
              },
            ),
            BlocListener<
              DiagnosisResultScreenCubit,
              DiagnosisResultScreenState
            >(
              listenWhen: (previous, current) =>
                  previous.shareVersion != current.shareVersion,
              listener: (context, state) {
                final text = state.shareText;
                if (text == null || text.trim().isEmpty) {
                  return;
                }
                Share.share(text);
              },
            ),
            BlocListener<
              DiagnosisResultScreenCubit,
              DiagnosisResultScreenState
            >(
              listenWhen: (previous, current) =>
                  previous.errorVersion != current.errorVersion,
              listener: (context, state) {
                if (state.errorMessage == null) {
                  return;
                }
              },
            ),
            ],
            child:
                BlocBuilder<
                  DiagnosisResultScreenCubit,
                  DiagnosisResultScreenState
                >(
                  builder: (context, state) {
                    return ListenWidget(
                      contentId: listenContentId,
                      title: diseaseTitle,
                      shortDescription: descriptionText.isNotEmpty
                          ? descriptionText
                          : null,
                      markdownContent: '',
                      playerTitle: diseaseTitle,
                      builder: (context, scope) {
                        return Stack(
                          children: [
                            SingleChildScrollView(
                              padding: EdgeInsets.fromLTRB(
                                16,
                                16,
                                16,
                                16 + scope.extraBottomPadding,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSuccessCard(),
                                  const SizedBox(height: 24),
                                  _buildDiseaseCard(
                                    scope: scope,
                                    descriptionText: descriptionText,
                                    state: state,
                                  ),
                                  const SizedBox(height: 24),
                                  _buildReferenceImagesCard(state),
                                ],
                              ),
                            ),
                            scope.bottomPlayer,
                          ],
                        );
                      },
                    );
                  },
                ),
          ),
        ),
      ),
    );
  }

  /// كارد نجاح التشخيص
  Widget _buildSuccessCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 28),
          const SizedBox(width: 8),
          const Text(
            'تم التشخيص بنجاح',
            style: TextStyle(color: Colors.green, fontSize: 18),
          ),
        ],
      ),
    );
  }

  /// كارد تفاصيل المرض
  Widget _buildDiseaseCard({
    required ListenRenderScope scope,
    required String descriptionText,
    required DiagnosisResultScreenState state,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: widget.imagePath != null
                    ? Image.file(
                        io.File(widget.imagePath!),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      )
                    : (widget.result.imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: widget.result.imageUrl,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[200],
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image,
                                color: Colors.grey,
                              ),
                            )),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: scope.buildHighlightedTitle(
                            const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 5.0),
                          child: scope.listenButton,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text(
                          'درجة الثقة: ',
                          style: TextStyle(fontSize: 14),
                        ),
                        Text(
                          '${(widget.result.confidence * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const SizedBox(height: 6),
          Builder(
            builder: (context) {
              final desc = descriptionText;
              if (desc.isEmpty) return const SizedBox.shrink();
              const int cutoff = 120;
              final bool long = desc.length > cutoff;
              final displayText = (state.showFullDescription || !long)
                  ? desc
                  : '${desc.substring(0, cutoff)}...';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  state.showFullDescription || !long
                      ? scope.buildHighlightedShortDescription(
                          const TextStyle(fontSize: 13, color: Colors.black87),
                        )
                      : Text(
                          displayText,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                  if (long)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          context
                              .read<DiagnosisResultScreenCubit>()
                              .toggleDescription();
                        },
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          state.showFullDescription ? 'عرض أقل' : 'عرض المزيد',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.medical_services,
                    color: Colors.white,
                    size: 20,
                  ),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      'عرض خطة العلاج الآن',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size.fromHeight(52),
                  ),
                  onPressed: () {
                    context
                        .read<DiagnosisResultScreenCubit>()
                        .requestOpenTreatmentRecommendations();
                  },
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.green),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 10,
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  context.read<DiagnosisResultScreenCubit>().requestShare();
                },
                icon: const Icon(Icons.share, color: Colors.green),
                label: const Text(
                  'مشاركة',
                  style: TextStyle(color: Colors.green, fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// كارد صور مرجعية للمرض
  Widget _buildReferenceImagesCard(DiagnosisResultScreenState state) {
    if (state.isReferenceImagesLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.referenceImagesError != null) {
      return const Text('الاتصال ضعيف — حاول لاحقًا');
    }
    final images = state.referenceImages;
    if (images.isEmpty) {
      return const Text('لا توجد صور مرجعية متاحة لهذا المرض');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'صور مرجعية للمرض: ${widget.result.diseaseName}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemCount: images.length,
              itemBuilder: (context, idx) {
                final imageUrl = images[idx];
                return SizedBox(
                  width: 220,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(14),
                    clipBehavior: Clip.hardEdge,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: 220,
                            fit: BoxFit.cover,
                            placeholder: (c, url) =>
                                Container(color: Colors.grey[200]),
                            errorWidget: (c, url, error) => Container(
                              color: Colors.grey[200],
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black26.withOpacity(0.6),
                                ],
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${idx + 1} / ${images.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (dialogContext) => Dialog(
                                        insetPadding: EdgeInsets.zero,
                                        backgroundColor: Colors.black,
                                        child: GestureDetector(
                                          onTap: () =>
                                              Navigator.of(dialogContext).pop(),
                                          child: InteractiveViewer(
                                            child: Center(
                                              child: Image.network(
                                                imageUrl,
                                                fit: BoxFit.contain,
                                                errorBuilder: (c, e, s) =>
                                                    Container(
                                                      color: Colors.grey[900],
                                                      child: const Icon(
                                                        Icons.broken_image,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: Icon(
                                      Icons.open_in_full,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
