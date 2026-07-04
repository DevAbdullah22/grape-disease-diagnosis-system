import 'package:flutter_application_55555/features/diagnosis/domain/entities/diagnosis_history_item.dart';

import '../repositories/diagnosis_repository.dart';

class GetDiagnosisHistory {
  final DiagnosisRepository repository;

  GetDiagnosisHistory(this.repository);

  Future<List<DiagnosisHistoryItem>> call({String? userId}) {
    return repository.getDiagnosisHistory(userId: userId);
  }
}
