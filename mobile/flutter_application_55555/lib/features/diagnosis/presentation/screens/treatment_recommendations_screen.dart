import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_application_55555/core/models/recommendation.dart';
import 'package:flutter_application_55555/core/widgets/listen_widget.dart';
import 'package:flutter_application_55555/features/diagnosis/presentation/cubit/treatment_recommendations_cubit.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/get_treatment_recommendation.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/execute_treatment_step.dart';

class TreatmentRecommendationsScreen extends StatelessWidget {
  final String diseaseName;
  final String diagnosisId;
  final double? confidence;
  final String? description;
  final String? diseaseImageUrl;
  final String? diagnosisImagePath;
  final Recommendation? initialRecommendation;

  const TreatmentRecommendationsScreen({
    super.key,
    required this.diseaseName,
    required this.diagnosisId,
    required this.confidence,
    required this.description,
    required this.diseaseImageUrl,
    required this.diagnosisImagePath,
    this.initialRecommendation,
  });

  /// Convenience helper that wraps the screen with a properly initialized
  /// [TreatmentRecommendationsCubit]. This saves callers from having to copy
  /// the boilerplate every time we push the screen.
  static Widget withProvider({
    required String diseaseName,
    required String diagnosisId,
    required double? confidence,
    required String? description,
    required String? diseaseImageUrl,
    required String? diagnosisImagePath,
    Recommendation? initialRecommendation,
  }) {
    return BlocProvider(
      create: (ctx) {
        final cubit = TreatmentRecommendationsCubit(
          getTreatmentRecommendation: ctx.read<GetTreatmentRecommendation>(),
          executeTreatmentStep: ctx.read<ExecuteTreatmentStep>(),
        );
        // initialize cubit after creation
        cubit.initialize(
          diagnosisId: diagnosisId,
          initialRecommendation: initialRecommendation,
        );
        return cubit;
      },
      child: TreatmentRecommendationsScreen(
        diseaseName: diseaseName,
        diagnosisId: diagnosisId,
        confidence: confidence,
        description: description,
        diseaseImageUrl: diseaseImageUrl,
        diagnosisImagePath: diagnosisImagePath,
        initialRecommendation: initialRecommendation,
      ),
    );
  }

  static const Color _primaryGreen = Color(0xFF016630);
  static const Color _pageBg = Color(0xFFEFFCF4);
  static const Color _softBorder = Color(0xFFD9F0E4);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _pageBg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          centerTitle: true,
          title: const Text(
            'التوصيات العلاجية',
            style: TextStyle(
              color: _primaryGreen,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: BlocConsumer<
            TreatmentRecommendationsCubit,
            TreatmentRecommendationsState
          >(
            listenWhen: (previous, current) =>
                previous.transientMessageVersion !=
                current.transientMessageVersion,
            listener: (context, state) {
              final message = state.transientMessage;
              if (message == null || message.trim().isEmpty) {
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    message,
                    textDirection: TextDirection.rtl,
                  ),
                ),
              );
            },
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.errorMessage != null) {
                return _errorView(context, state.errorMessage!);
              }

              final viewData = state.viewData;
              if (viewData == null) {
                return _buildEmptyState(context);
              }

              return _buildBody(context, state, viewData);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    TreatmentRecommendationsState state,
    TreatmentRecommendationsViewData viewData,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 320),
            child: state.successFlag
                ? _buildSuccessBanner(state.successTitle, state.successSubtitle)
                : const SizedBox.shrink(),
          ),
          if (state.successFlag) const SizedBox(height: 14),
          if ((viewData.planName ?? '').trim().isNotEmpty) ...[
            _buildPlanNameCard(viewData.planName!.trim()),
            const SizedBox(height: 14),
          ],
          _buildCurrentDoseCard(context, viewData),
          const SizedBox(height: 14),
          _buildProgressCard(context, viewData),
          const SizedBox(height: 14),
          _buildInstructionsCard(context, viewData),
          if (viewData.hasAdditionalDetails) ...[
            const SizedBox(height: 14),
            _buildAdditionalDetailsCard(viewData),
          ],
          if (viewData.contextData.allCompleted) ...[
            const SizedBox(height: 14),
            _buildCompletionCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, color: Colors.grey, size: 32),
            const SizedBox(height: 8),
            const Text(
              'لا توجد توصيات علاجية متاحة حاليًا.',
              style: TextStyle(color: Colors.black87, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () =>
                  context.read<TreatmentRecommendationsCubit>().refresh(),
              style: ElevatedButton.styleFrom(backgroundColor: _primaryGreen),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorView(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: _box(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, color: Colors.redAccent, size: 30),
              const SizedBox(height: 10),
              Text(
                message,
                style: const TextStyle(color: Colors.redAccent, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () =>
                    context.read<TreatmentRecommendationsCubit>().refresh(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryGreen,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(
    BuildContext context,
    TreatmentRecommendationsViewData viewData,
  ) {
    if (viewData.progressSteps.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: _box(),
        child: const Text(
          'لا توجد خطوات جرعات مفصلة في الخطة الحالية.',
          style: TextStyle(color: Colors.black87, height: 1.5, fontSize: 15),
        ),
      );
    }

    final rows = <Widget>[];
    for (var i = 0; i < viewData.progressSteps.length; i++) {
      final step = viewData.progressSteps[i];

      IconData statusIcon;
      Color statusColor;
      if (step.isDone) {
        statusIcon = Icons.check_circle;
        statusColor = _primaryGreen;
      } else if (step.isCurrent) {
        statusIcon = Icons.radio_button_checked;
        statusColor = _primaryGreen;
      } else {
        statusIcon = Icons.radio_button_unchecked;
        statusColor = Colors.grey.shade500;
      }

      rows.add(
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () =>
              context.read<TreatmentRecommendationsCubit>().selectStep(step.stepIndex),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'جرعة ${step.order}',
                    style: TextStyle(
                      fontSize: 16,
                      color: step.isCurrent ? Colors.black : Colors.black87,
                      fontWeight:
                          step.isCurrent ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
                if (step.isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF8F0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'الحالية',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _primaryGreen,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );

      if (i < viewData.progressSteps.length - 1) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(right: 9),
            child: Container(
              width: 2,
              height: 14,
              color: const Color(0xFFE0E7E2),
            ),
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'تقدم الخطة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              _pill(
                viewData.progressSummary,
                const Color(0xFFEAF8F0),
                _primaryGreen,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows),
        ],
      ),
    );
  }

  Widget _buildCurrentDoseCard(
    BuildContext context,
    TreatmentRecommendationsViewData viewData,
  ) {
    final isExecuted = viewData.remainingText.contains('تم تنفيذ الجرعة');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFE8D0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: _primaryGreen),
              const SizedBox(width: 8),
              Text(
                viewData.doseTitle,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: _primaryGreen,
                ),
              ),
              const Spacer(),
              _pill(
                viewData.contextData.allCompleted ? 'مكتملة' : 'تنفيذ سريع',
                Colors.white,
                _primaryGreen,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              width: 122,
              height: 122,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBFE8D0)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: viewData.pesticideImageUrl.isNotEmpty
                    ? Image.network(
                        viewData.pesticideImageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.broken_image, color: Colors.grey),
                      )
                    : const Icon(Icons.image_outlined, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              viewData.pesticideName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFE8D0)),
            ),
            child: Row(
              children: [
                Icon(
                  isExecuted ? Icons.check_circle_outline_rounded : Icons.timer_outlined,
                  color: _primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    viewData.remainingText,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: viewData.canLongPress
                  ? () => _confirmAndExecute(context)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                disabledBackgroundColor: Colors.grey.shade400,
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: viewData.isActionLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      viewData.actionButtonText,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
          if (viewData.lastExecutedText != null) ...[
            const SizedBox(height: 10),
            Text(
              'تم آخر تنفيذ: ${viewData.lastExecutedText}',
              style: const TextStyle(
                color: _primaryGreen,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlanNameCard(String planName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FFFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCFECDC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.assignment_rounded,
              color: _primaryGreen,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'اسم الخطة العلاجية',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  planName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: _primaryGreen,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndExecute(BuildContext context) async {
    final cubit = context.read<TreatmentRecommendationsCubit>();
    final confirmText = cubit.executionConfirmationMessage();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تأكيد التنفيذ'),
        content: Text(
          confirmText,
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(dialogContext, false),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('إلغاء'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
            label: const Text('تأكيد'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await cubit.executeConfirmed();
    }
  }

  Widget _buildInstructionsCard(
    BuildContext context,
    TreatmentRecommendationsViewData viewData,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'تعليمات الجرعة',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...viewData.instructionSections
              .map((section) => _buildInstructionSection(context, section))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildInstructionSection(
    BuildContext context,
    TreatmentInstructionSectionViewData section,
  ) {
    final style = _styleForSection(section.id);
    final text = section.content.trim();
    final listenContent = _buildSectionListenContent(section);

    return ListenWidget(
      key: ValueKey(section.key),
      contentId: '${section.key}_${section.content.hashCode}',
      title: section.title,
      shortDescription: null,
      markdownContent: listenContent,
      playerTitle: section.title,
      builder: (ctx, scope) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8E3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => context
                    .read<TreatmentRecommendationsCubit>()
                    .toggleAccordion(section.key),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(style.icon, color: style.accent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          section.title,
                          style: TextStyle(
                            color: style.accent,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      if (text.isNotEmpty) ...[
                        _buildSectionListenIcon(scope, style.accent),
                        const SizedBox(width: 4),
                      ],
                      Icon(
                        section.isOpen
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.chevron_left_rounded,
                        color: style.accent,
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: style.accent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: text.isEmpty
                      ? Text(
                          section.emptyText,
                          style: const TextStyle(
                            color: Colors.black54,
                            height: 1.5,
                            fontSize: 15,
                          ),
                        )
                      : Column(
                          children: section.points
                              .where((line) => line.trim().isNotEmpty)
                              .map(_buildBulletLine)
                              .toList(),
                        ),
                ),
                crossFadeState: section.isOpen
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 220),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionListenIcon(ListenRenderScope scope, Color color) {
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
        color: color,
        size: 22,
      ),
    );
  }

  String _buildSectionListenContent(TreatmentInstructionSectionViewData section) {
    if (section.points.isEmpty) {
      return section.content;
    }

    return section.points.join('\n');
  }

  Widget _buildAdditionalDetailsCard(TreatmentRecommendationsViewData viewData) {
    if (!viewData.hasAdditionalDetails) {
      return const SizedBox.shrink();
    }

    final listenContent = _buildAdditionalDetailsListenContent(
      viewData.additionalDetails,
    );

    return ListenWidget(
      key: ValueKey('additional_details_${viewData.doseTitle}'),
      contentId:
          'additional_details_${viewData.doseTitle}_${listenContent.hashCode}',
      title: 'تفاصيل إضافية',
      shortDescription: null,
      markdownContent: listenContent,
      playerTitle: 'تفاصيل إضافية',
      builder: (context, scope) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: _box(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'تفاصيل إضافية',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (listenContent.trim().isNotEmpty)
                    _buildSectionListenIcon(scope, _primaryGreen),
                ],
              ),
              const SizedBox(height: 10),
              ...viewData.additionalDetails
                  .map((detail) => _detailRow(detail.title, detail.value))
                  .toList(),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  String _buildAdditionalDetailsListenContent(List<TreatmentDetailViewData> details) {
    final lines = details
        .where((detail) => detail.value.trim().isNotEmpty)
        .map((detail) => '${detail.title}: ${detail.value.trim()}')
        .toList();

    return lines.join('\n');
  }

  Widget _buildSuccessBanner(String title, String subtitle) {
    return Container(
      key: const ValueKey('execution_success'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFE8D0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle, color: _primaryGreen, size: 24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _primaryGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletLine(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.black87,
                height: 1.55,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title: ',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F0),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _softBorder),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle, color: _primaryGreen),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'اكتملت جميع الجرعات بنجاح.',
              style: TextStyle(
                color: _primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: background.withValues(alpha: 0.8)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: foreground,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  BoxDecoration _box() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: const Border.fromBorderSide(BorderSide(color: _softBorder)),
    );
  }

  _InstructionSectionStyle _styleForSection(String id) {
    switch (id) {
      case 'mix':
        return const _InstructionSectionStyle(
          icon: Icons.science_outlined,
          accent: Color(0xFF1565C0),
        );
      case 'safety':
        return const _InstructionSectionStyle(
          icon: Icons.warning_amber_rounded,
          accent: Color(0xFFF57C00),
        );
      case 'notes':
        return const _InstructionSectionStyle(
          icon: Icons.notes_outlined,
          accent: Color(0xFF6D4C41),
        );
      case 'spray':
      default:
        return const _InstructionSectionStyle(
          icon: Icons.grass_outlined,
          accent: _primaryGreen,
        );
    }
  }
}

class _InstructionSectionStyle {
  final IconData icon;
  final Color accent;

  const _InstructionSectionStyle({
    required this.icon,
    required this.accent,
  });
}
