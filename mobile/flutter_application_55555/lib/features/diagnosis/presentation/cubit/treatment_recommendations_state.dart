part of 'treatment_recommendations_cubit.dart';

class TreatmentRecommendationsState {
  static const Object _unset = Object();

  final bool isLoading;
  final String? errorMessage;
  final Recommendation? dataModel;
  final bool isExecuting;
  final bool successFlag;
  final String successTitle;
  final String successSubtitle;
  final String? transientMessage;
  final int transientMessageVersion;
  final TreatmentRecommendationsViewData? viewData;

  const TreatmentRecommendationsState({
    required this.isLoading,
    required this.errorMessage,
    required this.dataModel,
    required this.isExecuting,
    required this.successFlag,
    required this.successTitle,
    required this.successSubtitle,
    required this.transientMessage,
    required this.transientMessageVersion,
    required this.viewData,
  });

  factory TreatmentRecommendationsState.initial() {
    return const TreatmentRecommendationsState(
      isLoading: true,
      errorMessage: null,
      dataModel: null,
      isExecuting: false,
      successFlag: false,
      successTitle: '',
      successSubtitle: '',
      transientMessage: null,
      transientMessageVersion: 0,
      viewData: null,
    );
  }

  bool get hasContent => !isLoading && errorMessage == null && viewData != null;

  TreatmentRecommendationsState copyWith({
    bool? isLoading,
    Object? errorMessage = _unset,
    Object? dataModel = _unset,
    bool? isExecuting,
    bool? successFlag,
    String? successTitle,
    String? successSubtitle,
    Object? transientMessage = _unset,
    int? transientMessageVersion,
    Object? viewData = _unset,
  }) {
    return TreatmentRecommendationsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      dataModel: identical(dataModel, _unset)
          ? this.dataModel
          : dataModel as Recommendation?,
      isExecuting: isExecuting ?? this.isExecuting,
      successFlag: successFlag ?? this.successFlag,
      successTitle: successTitle ?? this.successTitle,
      successSubtitle: successSubtitle ?? this.successSubtitle,
      transientMessage: identical(transientMessage, _unset)
          ? this.transientMessage
          : transientMessage as String?,
      transientMessageVersion:
          transientMessageVersion ?? this.transientMessageVersion,
      viewData: identical(viewData, _unset)
          ? this.viewData
          : viewData as TreatmentRecommendationsViewData?,
    );
  }
}

class TreatmentRecommendationsViewData {
  final TreatmentExecutionContext contextData;
  final String? planName;
  final String doseTitle;
  final String pesticideName;
  final String pesticideImageUrl;
  final String remainingText;
  final String actionButtonText;
  final bool canLongPress;
  final bool isActionLoading;
  final String? lastExecutedText;
  final List<TreatmentProgressStepViewData> progressSteps;
  final String progressSummary;
  final List<TreatmentInstructionSectionViewData> instructionSections;
  final List<TreatmentDetailViewData> additionalDetails;
  final bool hasAdditionalDetails;

  const TreatmentRecommendationsViewData({
    required this.contextData,
    required this.planName,
    required this.doseTitle,
    required this.pesticideName,
    required this.pesticideImageUrl,
    required this.remainingText,
    required this.actionButtonText,
    required this.canLongPress,
    required this.isActionLoading,
    required this.lastExecutedText,
    required this.progressSteps,
    required this.progressSummary,
    required this.instructionSections,
    required this.additionalDetails,
    required this.hasAdditionalDetails,
  });
}

class TreatmentProgressStepViewData {
  final int stepIndex;
  final int order;
  final bool isDone;
  final bool isCurrent;

  const TreatmentProgressStepViewData({
    required this.stepIndex,
    required this.order,
    required this.isDone,
    required this.isCurrent,
  });
}

class TreatmentInstructionSectionViewData {
  final String id;
  final String key;
  final String title;
  final String content;
  final String emptyText;
  final List<String> points;
  final bool isOpen;

  const TreatmentInstructionSectionViewData({
    required this.id,
    required this.key,
    required this.title,
    required this.content,
    required this.emptyText,
    required this.points,
    required this.isOpen,
  });
}

class TreatmentDetailViewData {
  final String title;
  final String value;

  const TreatmentDetailViewData({
    required this.title,
    required this.value,
  });

  TreatmentDetailViewData copyWith({
    String? title,
    String? value,
  }) {
    return TreatmentDetailViewData(
      title: title ?? this.title,
      value: value ?? this.value,
    );
  }
}
