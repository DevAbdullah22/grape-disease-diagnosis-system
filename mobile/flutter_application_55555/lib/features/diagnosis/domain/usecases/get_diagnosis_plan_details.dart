import '../repositories/diagnosis_repository.dart';

class GetDiagnosisPlanDetails {
  final DiagnosisRepository repository;

  GetDiagnosisPlanDetails(this.repository);

  Future<Map<String, dynamic>> call(String diagnosisId) {
    return repository.getDiagnosisPlanDetails(diagnosisId);
  }
}
