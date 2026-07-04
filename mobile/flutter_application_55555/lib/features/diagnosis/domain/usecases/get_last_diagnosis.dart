import 'package:flutter_application_55555/features/diagnosis/domain/entities/diagnosis_history_item.dart';

import '../repositories/diagnosis_repository.dart';

class GetLastDiagnosis {
  final DiagnosisRepository repository;

  GetLastDiagnosis(this.repository);

  Future<DiagnosisHistoryItem?> call({String? userId}) {
    return repository.getLastDiagnosis(userId: userId);
  }
}
