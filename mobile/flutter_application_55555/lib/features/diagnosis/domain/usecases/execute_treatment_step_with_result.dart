import '../repositories/diagnosis_repository.dart';

class ExecuteTreatmentStepWithResult {
  final DiagnosisRepository repository;

  ExecuteTreatmentStepWithResult(this.repository);

  Future<Map<String, dynamic>> call({
    required String diagnosisId,
    int? stepOrder,
  }) {
    return repository.executeTreatmentStepWithResult(
      diagnosisId: diagnosisId,
      stepOrder: stepOrder,
    );
  }
}
