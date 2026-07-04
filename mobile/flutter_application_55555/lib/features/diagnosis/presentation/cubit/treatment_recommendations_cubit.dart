import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_55555/core/error/failures.dart';
import 'package:flutter_application_55555/core/models/recommendation.dart';
import 'package:flutter_application_55555/core/services/config.dart';
import 'package:flutter_application_55555/features/diagnosis/data/exceptions.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/execute_treatment_step.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/get_treatment_recommendation.dart';

import '../logic/treatment_execution_context.dart';

part 'treatment_recommendations_state.dart';

class TreatmentRecommendationsCubit
    extends Cubit<TreatmentRecommendationsState> {
  static const Object _keep = Object();

  final GetTreatmentRecommendation _getTreatmentRecommendation;
  final ExecuteTreatmentStep _executeTreatmentStep;

  String? _diagnosisId;
  Recommendation? _recommendationModel;
  final Set<int> _executingSteps = <int>{};
  bool _executingNext = false;
  int _currentStepIndex = 0;
  String? _openAccordionKey;

  Timer? _clockTimer;
  Timer? _successTimer;

  TreatmentRecommendationsCubit({
    required GetTreatmentRecommendation getTreatmentRecommendation,
    required ExecuteTreatmentStep executeTreatmentStep,
  })  : _getTreatmentRecommendation = getTreatmentRecommendation,
        _executeTreatmentStep = executeTreatmentStep,
        super(TreatmentRecommendationsState.initial());

  Future<void> initialize({
    required String diagnosisId,
    Recommendation? initialRecommendation,
  }) async {
    _diagnosisId = diagnosisId;
    _startClockTimer();

    if (initialRecommendation != null) {
      _recommendationModel = initialRecommendation;
      _currentStepIndex =
          TreatmentExecutionContext.nextStepIndex(initialRecommendation);
      _emitDerivedState(isLoading: false, errorMessage: null);
      await refresh(showLoading: false);
      return;
    }

    await refresh();
  }

  Future<void> refresh({bool showLoading = true}) async {
    final diagnosisId = _diagnosisId;
    if (diagnosisId == null || diagnosisId.trim().isEmpty) {
      _emitDerivedState(
        isLoading: false,
        errorMessage: 'رقم التشخيص غير صالح.',
      );
      return;
    }

    final hasCachedModel = _recommendationModel != null;

    if (showLoading || !hasCachedModel) {
      _emitDerivedState(
        isLoading: true,
        errorMessage: null,
      );
    } else {
      _emitDerivedState(errorMessage: null);
    }

    try {
      final model = await _getTreatmentRecommendation.call(diagnosisId);
      _recommendationModel = model;
      _currentStepIndex = TreatmentExecutionContext.nextStepIndex(model);

      _emitDerivedState(
        isLoading: false,
        errorMessage: null,
      );
    } catch (error, stackTrace) {
      final failure = _mapExceptionToFailure(error);
      final message = _mapFetchFailureToMessage(failure);

      debugPrint('TreatmentRecommendationsCubit.refresh error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!showLoading && hasCachedModel) {
        _emitDerivedState(isLoading: false);
        _pushTransientMessage(message);
        return;
      }

      _emitDerivedState(
        isLoading: false,
        errorMessage: message,
      );
    }
  }

  void selectStep(int stepIndex) {
    _currentStepIndex = stepIndex;
    _emitDerivedState();
  }

  void toggleAccordion(String key) {
    final currentStepIdentity = _currentStepIdentity();
    final effectiveOpenKey = _effectiveOpenAccordionKey(currentStepIdentity);

    _openAccordionKey = effectiveOpenKey == key ? null : key;
    _emitDerivedState();
  }

  String executionConfirmationMessage() {
    final contextData = _buildExecutionContext();
    if (contextData == null) {
      return 'هل تريد بدء تنفيذ العلاج الآن؟';
    }

    if (!contextData.hasSteps) {
      return 'هل تريد بدء تنفيذ العلاج الآن؟';
    }

    final order = contextData.currentOrder ?? (contextData.safeIndex + 1);

    return 'هل تريد تنفيذ الجرعة رقم $order الآن؟';
  }

  Future<void> executeConfirmed() async {
    final diagnosisId = _diagnosisId;
    final contextData = _buildExecutionContext();

    if (diagnosisId == null || diagnosisId.isEmpty || contextData == null) {
      _pushTransientMessage('تعذّر بدء التنفيذ الآن.');
      return;
    }

    int? stepOrder;
    if (contextData.hasSteps) {
      if (!contextData.canExecute) {
        return;
      }

      if (contextData.currentOrder == null) {
        _pushTransientMessage('تعذّر تحديد رقم الجرعة الحالية.');
        return;
      }

      stepOrder = contextData.currentOrder;
      if (stepOrder != null) {
        _executingSteps.add(stepOrder);
      }
    } else {
      if (_executingNext) {
        return;
      }

      stepOrder = null;
      _executingNext = true;
    }

    _emitDerivedState();

    try {
      await _executeTreatmentStep.call(
        diagnosisId: diagnosisId,
        stepOrder: stepOrder,
      );

      await refresh();
      final nextDoseAt = _buildExecutionContext()?.currentNextDose;
      _showSuccessFeedback(nextDoseAt);
    } catch (error, stackTrace) {
      final failure = _mapExceptionToFailure(error);
      final message = _mapExecutionFailureToMessage(failure);

      debugPrint('TreatmentRecommendationsCubit.executeConfirmed error: $error');
      debugPrintStack(stackTrace: stackTrace);

      _pushTransientMessage(message);
    } finally {
      if (stepOrder == null) {
        _executingNext = false;
      } else {
        _executingSteps.remove(stepOrder);
      }
      _emitDerivedState();
    }
  }

  void _startClockTimer() {
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (_recommendationModel == null) {
        return;
      }
      _emitDerivedState();
    });
  }

  void _showSuccessFeedback(DateTime? nextDoseAt) {
    _successTimer?.cancel();

    _emitDerivedState(
      successFlag: true,
      successTitle: 'تم تنفيذ الجرعة بنجاح',
      successSubtitle: _nextDoseHuman(nextDoseAt),
    );

    _successTimer = Timer(const Duration(seconds: 6), () {
      _emitDerivedState(
        successFlag: false,
        successTitle: '',
        successSubtitle: '',
      );
    });
  }

  void _pushTransientMessage(String message) {
    _emitDerivedState(transientMessage: message);
  }

  void _emitDerivedState({
    bool? isLoading,
    Object? errorMessage = _keep,
    bool? successFlag,
    String? successTitle,
    String? successSubtitle,
    Object? transientMessage = _keep,
  }) {
    final previous = state;
    final hasNewTransientMessage = !identical(transientMessage, _keep);

    emit(
      previous.copyWith(
        isLoading: isLoading,
        errorMessage: errorMessage,
        dataModel: _recommendationModel,
        isExecuting: _executingNext || _executingSteps.isNotEmpty,
        successFlag: successFlag,
        successTitle: successTitle,
        successSubtitle: successSubtitle,
        transientMessage: transientMessage,
        transientMessageVersion: hasNewTransientMessage
            ? previous.transientMessageVersion + 1
            : previous.transientMessageVersion,
        viewData: _buildViewData(),
      ),
    );
  }

  TreatmentExecutionContext? _buildExecutionContext() {
    final model = _recommendationModel;
    if (model == null) {
      return null;
    }

    return TreatmentExecutionContext.fromModel(
      model,
      currentStepIndex: _currentStepIndex,
      executingSteps: _executingSteps,
      executingNext: _executingNext,
    );
  }

  TreatmentRecommendationsViewData? _buildViewData() {
    final model = _recommendationModel;
    final contextData = _buildExecutionContext();
    if (model == null || contextData == null) {
      return null;
    }

    final step = contextData.currentStep;
    final pesticideName =
        (step?.pesticideName ?? model.pesticideName ?? '').trim();
    final pesticideImageUrl = _resolveImageUrl(
      (step?.pesticideImageUrl ?? model.pesticideImageUrl ?? '').trim(),
    );

    final currentStepIdentity = contextData.currentOrder ?? (contextData.safeIndex + 1);
    final doseTitle =
        contextData.hasSteps ? 'الجرعة رقم $currentStepIdentity' : 'تنفيذ العلاج';

    final remainingText = _buildRemainingText(contextData);
    final actionLabel = _buildActionLabel(contextData);
    final canLongPress = contextData.canExecute && !contextData.isActionLoading;

    final progressSteps = _buildProgressSteps(contextData);

    final mixText =
        (step?.mixQuantityAndType ?? model.mixQuantityAndType ?? '').trim();
    final sprayText =
        (step?.dosageInstructions ?? model.dosageInstructions ?? '').trim();
    final safetyText = (step?.safetyInfo ?? model.safetyInfo ?? '').trim();
    final notesText =
        (step?.importantNotes ?? model.importantNotes ?? '').trim();

    final openKey = _effectiveOpenAccordionKey(currentStepIdentity);
    final mixKey = _sectionKey(currentStepIdentity, 'mix');
    final sprayKey = _sectionKey(currentStepIdentity, 'spray');
    final safetyKey = _sectionKey(currentStepIdentity, 'safety');
    final notesKey = _sectionKey(currentStepIdentity, 'notes');

    final instructionSections = <TreatmentInstructionSectionViewData>[
      TreatmentInstructionSectionViewData(
        id: 'mix',
        key: mixKey,
        title: 'الكمية والخلط',
        content: mixText,
        emptyText: 'لا توجد بيانات للكمية والخلط.',
        points: _splitToPoints(mixText),
        isOpen: openKey == mixKey,
      ),
      TreatmentInstructionSectionViewData(
        id: 'spray',
        key: sprayKey,
        title: 'طريقة الرش',
        content: sprayText,
        emptyText: 'لا توجد تعليمات للرش.',
        points: _splitToPoints(sprayText),
        isOpen: openKey == sprayKey,
      ),
      TreatmentInstructionSectionViewData(
        id: 'safety',
        key: safetyKey,
        title: 'تحذيرات السلامة',
        content: safetyText,
        emptyText: 'لا توجد تحذيرات سلامة إضافية.',
        points: _splitToPoints(safetyText),
        isOpen: openKey == safetyKey,
      ),
      TreatmentInstructionSectionViewData(
        id: 'notes',
        key: notesKey,
        title: 'ملاحظات إضافية',
        content: notesText,
        emptyText: 'لا توجد ملاحظات إضافية.',
        points: _splitToPoints(notesText),
        isOpen: openKey == notesKey,
      ),
    ];

    final additionalDetails = <TreatmentDetailViewData>[];
    final chemicalGroup = (step?.chemicalGroup ?? '').trim();
    final intervalDays = model.doseIntervalDays;

    if (chemicalGroup.isNotEmpty) {
      additionalDetails.add(
        const TreatmentDetailViewData(
          title: 'المجموعة الكيميائية',
          value: '',
        ).copyWith(value: chemicalGroup),
      );
    }

    if (intervalDays != null) {
      additionalDetails.add(
        TreatmentDetailViewData(
          title: 'الفاصل بين الجرعات',
          value: 'كل $intervalDays يوم',
        ),
      );
    }

    if (contextData.currentNextDose != null) {
      additionalDetails.add(
        TreatmentDetailViewData(
          title: 'الموعد القادم',
          value: _formatDateTime(contextData.currentNextDose!),
        ),
      );
    }

    if (contextData.currentExecutedAt != null) {
      additionalDetails.add(
        TreatmentDetailViewData(
          title: 'آخر تنفيذ',
          value: _formatDateTime(contextData.currentExecutedAt!),
        ),
      );
    }

    return TreatmentRecommendationsViewData(
      contextData: contextData,
      planName: model.planName?.trim(),
      doseTitle: doseTitle,
      pesticideName:
          pesticideName.isNotEmpty ? pesticideName : 'اسم المبيد غير متوفر',
      pesticideImageUrl: pesticideImageUrl,
      remainingText: remainingText,
      actionButtonText: canLongPress ? 'تأكيد تنفيذ الجرعة' : actionLabel,
      canLongPress: canLongPress,
      isActionLoading: contextData.isActionLoading,
      lastExecutedText: contextData.currentExecutedAt == null
          ? null
          : _formatDateTime(contextData.currentExecutedAt!),
      progressSteps: progressSteps,
      progressSummary:
          '${contextData.completedSteps} من ${contextData.totalSteps} جرعات',
      instructionSections: instructionSections,
      additionalDetails: additionalDetails,
      hasAdditionalDetails: additionalDetails.isNotEmpty,
    );
  }

  List<TreatmentProgressStepViewData> _buildProgressSteps(
    TreatmentExecutionContext contextData,
  ) {
    final items = <TreatmentProgressStepViewData>[];

    for (var i = 0; i < contextData.totalSteps; i++) {
      final step = contextData.steps[i];
      final order = step.stepOrder ?? (i + 1);
      final done =
          step.stepOrder != null && contextData.executedSet.contains(step.stepOrder);
      final current = i == contextData.safeIndex && !done;

      items.add(
        TreatmentProgressStepViewData(
          stepIndex: i,
          order: order,
          isDone: done,
          isCurrent: current,
        ),
      );
    }

    return items;
  }

  String _resolveImageUrl(String value) {
    if (value.isEmpty) {
      return value;
    }

    if (value.startsWith('/')) {
      return '${Config.apiBaseUrl}$value';
    }

    return value;
  }

  String _buildRemainingText(TreatmentExecutionContext contextData) {
    if (contextData.alreadyExecuted) {
      return 'تم تنفيذ الجرعة الحالية';
    }

    if (contextData.currentNextDose == null || contextData.nextDue) {
      return 'متاحة للتنفيذ الآن';
    }

    return 'متبقي: ${_timeRemainingString(contextData.currentNextDose!)}';
  }

  String _buildActionLabel(TreatmentExecutionContext contextData) {
    if (!contextData.hasSteps) {
      return 'بدء تنفيذ العلاج';
    }

    if (contextData.allCompleted) {
      return 'اكتملت الخطة';
    }

    if (contextData.currentOrder == null) {
      return 'تعذّر تحديد الجرعة';
    }

    if (contextData.alreadyExecuted) {
      return 'منفّذة';
    }

    if (!contextData.isCurrentStep) {
      return 'ليست الجرعة الحالية';
    }

    if (!contextData.nextDue) {
      return 'موعد الجرعة لم يحن بعد';
    }

    return 'تنفيذ الجرعة الآن';
  }

  String _formatDateTime(DateTime dt) {
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} $hour:$minute';
  }

  String _timeRemainingString(DateTime target) {
    final diff = target.difference(DateTime.now());
    if (diff.inSeconds <= 0) {
      return 'الآن';
    }

    final hours = diff.inHours;
    final minutes = diff.inMinutes.abs() % 60;

    if (hours > 0) {
      if (minutes > 0) {
        return 'بعد $hours س $minutes د';
      }
      return 'بعد $hours س';
    }

    return 'بعد ${diff.inMinutes} د';
  }

  String _nextDoseHuman(DateTime? nextDoseAt) {
    if (nextDoseAt == null) {
      return 'يمكنك مراجعة توقيت الجرعة القادمة من قسم التقدم.';
    }

    final diff = nextDoseAt.difference(DateTime.now());
    if (diff.inMinutes <= 0) {
      return 'الجرعة القادمة متاحة الآن.';
    }

    final days = diff.inDays;
    if (days >= 1) {
      return days == 1
          ? 'الجرعة القادمة بعد يوم واحد.'
          : 'الجرعة القادمة بعد $days أيام.';
    }

    final hours = diff.inHours;
    if (hours >= 1) {
      return hours == 1
          ? 'الجرعة القادمة بعد ساعة واحدة.'
          : 'الجرعة القادمة بعد $hours ساعات.';
    }

    return 'الجرعة القادمة بعد ${diff.inMinutes} دقيقة.';
  }

  List<String> _splitToPoints(String text) {
    final normalized = text.replaceAll('\r', '\n').trim();
    if (normalized.isEmpty) {
      return const <String>[];
    }

    var parts = normalized
        .split(RegExp(r'[\n•]+'))
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList();

    if (parts.length <= 1) {
      parts = normalized
          .split(RegExp(r'[،؛;.!?]+'))
          .map((segment) => segment.trim())
          .where((segment) => segment.isNotEmpty)
          .toList();
    }

    final unique = <String>{};
    final result = <String>[];
    for (final raw in parts) {
      final cleaned = raw.replaceAll(RegExp(r'^[\-\*\s]+'), '').trim();
      if (cleaned.length < 2) {
        continue;
      }
      if (unique.add(cleaned)) {
        result.add(cleaned);
      }
    }

    if (result.isEmpty) {
      return <String>[normalized];
    }

    return result;
  }

  int _currentStepIdentity() {
    final contextData = _buildExecutionContext();
    if (contextData == null) {
      return -1;
    }

    return contextData.currentOrder ?? (contextData.safeIndex + 1);
  }

  String _sectionKey(int stepIdentity, String sectionId) {
    return '$stepIdentity:$sectionId';
  }

  String _effectiveOpenAccordionKey(int stepIdentity) {
    final prefix = '$stepIdentity:';
    final key = _openAccordionKey;

    if (key == null || !key.startsWith(prefix)) {
      return '${prefix}mix';
    }

    return key;
  }

  Failure _mapExceptionToFailure(Object exception) {
    if (exception is TimeoutException || exception is RemoteTimeoutException) {
      return TimeoutFailure(exception.toString());
    }

    if (exception is SocketException || exception is NetworkException) {
      return NetworkFailure(exception.toString());
    }

    if (exception is HttpException) {
      final statusCode = int.tryParse(exception.message);
      if (statusCode != null) {
        return UnknownFailure('http:$statusCode');
      }
      return UnknownFailure(exception.message);
    }

    if (exception is UnknownRemoteException) {
      final statusCode = _extractStatusCode(exception.message);
      if (statusCode != null) {
        return UnknownFailure('http:$statusCode');
      }
      return UnknownFailure(exception.message);
    }

    return UnknownFailure(exception.toString());
  }

  String _mapFetchFailureToMessage(Failure failure) {
    if (failure is TimeoutFailure) {
      return 'انتهت مهلة الاتصال بالخادم. تحقق من الشبكة وحاول مرة أخرى.';
    }

    if (failure is NetworkFailure) {
      return 'تعذر الوصول للخادم. تأكد من الاتصال بالإنترنت.';
    }

    final statusCode = _statusCodeFromFailure(failure);
    if (statusCode == 404) {
      return 'لا توجد خطة علاجية لهذا التشخيص.';
    }

    return 'تعذر تحميل التوصيات الآن. حاول مرة أخرى.';
  }

  String _mapExecutionFailureToMessage(Failure failure) {
    if (failure is TimeoutFailure) {
      return 'انتهت مهلة التنفيذ. حاول مرة أخرى.';
    }

    if (failure is NetworkFailure) {
      return 'تعذّر الاتصال بالخادم. تحقق من الشبكة.';
    }

    final statusCode = _statusCodeFromFailure(failure);
    if (statusCode == 404) {
      return 'لا توجد خطة علاجية لهذا التشخيص.';
    }

    if (statusCode == 400) {
      return 'تعذّر تنفيذ الجرعة الحالية. راجع بيانات الخطة.';
    }

    if (statusCode != null && statusCode >= 500) {
      return 'حدث خطأ من الخادم أثناء التنفيذ. حاول لاحقًا.';
    }

    if (statusCode != null) {
      return 'فشل تنفيذ الجرعة. رمز الاستجابة: $statusCode.';
    }

    return 'تعذّر تنفيذ العملية الآن. حاول لاحقًا.';
  }

  int? _statusCodeFromFailure(Failure failure) {
    final message = failure.message.trim();
    if (message.startsWith('http:')) {
      return int.tryParse(message.substring(5));
    }
    return _extractStatusCode(message);
  }

  int? _extractStatusCode(String text) {
    final match = RegExp(r'(\d{3})').firstMatch(text);
    if (match == null) {
      return null;
    }
    return int.tryParse(match.group(1)!);
  }

  @override
  Future<void> close() {
    _clockTimer?.cancel();
    _successTimer?.cancel();
    return super.close();
  }
}
