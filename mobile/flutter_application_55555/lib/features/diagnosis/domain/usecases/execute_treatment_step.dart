import '../repositories/diagnosis_repository.dart';

class ExecuteTreatmentStep {
  final DiagnosisRepository repository;
  ExecuteTreatmentStep(this.repository);
  Future<void> call({
    required String diagnosisId,
    int? stepOrder,
  }) {
    return repository.executeTreatmentStep(
      diagnosisId: diagnosisId,
      stepOrder: stepOrder,
    );
  }
}
