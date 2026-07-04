import 'package:flutter_application_55555/core/models/recommendation.dart';

import '../repositories/diagnosis_repository.dart';

class GetTreatmentRecommendation {
  final DiagnosisRepository repository;

  GetTreatmentRecommendation(this.repository);

  Future<Recommendation> call(String diagnosisId) {
    return repository.getTreatmentRecommendation(diagnosisId);
  }
}
