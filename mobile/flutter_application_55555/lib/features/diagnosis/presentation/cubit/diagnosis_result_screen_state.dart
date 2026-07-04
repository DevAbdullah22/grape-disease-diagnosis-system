import 'package:flutter_application_55555/features/diagnosis/domain/entities/diagnosis_result.dart';

class DiagnosisResultScreenState {
  static const Object _unset = Object();

  final DiagnosisResult result;
  final String? imagePath;
  final int currentPage;
  final bool showFullDescription;
  final bool isReferenceImagesLoading;
  final List<String> referenceImages;
  final String? referenceImagesError;
  final int openTreatmentPlanVersion;
  final int shareVersion;
  final String? shareText;
  final int errorVersion;
  final String? errorMessage;

  const DiagnosisResultScreenState({
    required this.result,
    required this.imagePath,
    required this.currentPage,
    required this.showFullDescription,
    required this.isReferenceImagesLoading,
    required this.referenceImages,
    required this.referenceImagesError,
    required this.openTreatmentPlanVersion,
    required this.shareVersion,
    required this.shareText,
    required this.errorVersion,
    required this.errorMessage,
  });

  factory DiagnosisResultScreenState.initial({
    required DiagnosisResult result,
    String? imagePath,
  }) {
    return DiagnosisResultScreenState(
      result: result,
      imagePath: imagePath,
      currentPage: 0,
      showFullDescription: false,
      isReferenceImagesLoading: true,
      referenceImages: const <String>[],
      referenceImagesError: null,
      openTreatmentPlanVersion: 0,
      shareVersion: 0,
      shareText: null,
      errorVersion: 0,
      errorMessage: null,
    );
  }

  DiagnosisResultScreenState copyWith({
    DiagnosisResult? result,
    Object? imagePath = _unset,
    int? currentPage,
    bool? showFullDescription,
    bool? isReferenceImagesLoading,
    Object? referenceImages = _unset,
    Object? referenceImagesError = _unset,
    int? openTreatmentPlanVersion,
    int? shareVersion,
    Object? shareText = _unset,
    int? errorVersion,
    Object? errorMessage = _unset,
  }) {
    return DiagnosisResultScreenState(
      result: result ?? this.result,
      imagePath: identical(imagePath, _unset)
          ? this.imagePath
          : imagePath as String?,
      currentPage: currentPage ?? this.currentPage,
      showFullDescription: showFullDescription ?? this.showFullDescription,
      isReferenceImagesLoading:
          isReferenceImagesLoading ?? this.isReferenceImagesLoading,
      referenceImages: identical(referenceImages, _unset)
          ? this.referenceImages
          : referenceImages as List<String>,
      referenceImagesError: identical(referenceImagesError, _unset)
          ? this.referenceImagesError
          : referenceImagesError as String?,
      openTreatmentPlanVersion:
          openTreatmentPlanVersion ?? this.openTreatmentPlanVersion,
      shareVersion: shareVersion ?? this.shareVersion,
      shareText: identical(shareText, _unset)
          ? this.shareText
          : shareText as String?,
      errorVersion: errorVersion ?? this.errorVersion,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
