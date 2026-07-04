import '../repositories/diagnosis_repository.dart';

class GetTreatmentRecommendations {
  final DiagnosisRepository repository;

  GetTreatmentRecommendations(this.repository);

  Future<Map<String, dynamic>> call(String diagnosisId) {
    return repository.getTreatmentPlan(diagnosisId);
  }
}