part of 'diagnosis_details_cubit.dart';

abstract class DiagnosisDetailsState extends Equatable {
  const DiagnosisDetailsState();

  @override
  List<Object?> get props => [];
}

class DiagnosisDetailsInitial extends DiagnosisDetailsState {}

class DiagnosisDetailsLoading extends DiagnosisDetailsState {}

class DiagnosisDetailsLoaded extends DiagnosisDetailsState {
  final DiagnosisDetails details;

  // carry-through of original parameters for UI convenience
  final String? initialImageUrl;
  final DateTime? initialDate;
  final String? initialDisease;
  final String? initialStatus;
  final double? initialConfidence;
  final List<String>? initialReferenceImages;
  final String? initialDescription;

  const DiagnosisDetailsLoaded({
    required this.details,
    this.initialImageUrl,
    this.initialDate,
    this.initialDisease,
    this.initialStatus,
    this.initialConfidence,
    this.initialReferenceImages,
    this.initialDescription,
  });

  @override
  List<Object?> get props => [
        details,
        initialImageUrl,
        initialDate,
        initialDisease,
        initialStatus,
        initialConfidence,
        initialReferenceImages,
        initialDescription,
      ];
}

class DiagnosisDetailsError extends DiagnosisDetailsState {
  final String message;
  const DiagnosisDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}
