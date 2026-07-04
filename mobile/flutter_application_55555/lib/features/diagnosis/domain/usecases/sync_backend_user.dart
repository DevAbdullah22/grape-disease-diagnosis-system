import '../repositories/diagnosis_repository.dart';

class SyncBackendUser {
  final DiagnosisRepository repository;

  SyncBackendUser(this.repository);

  Future<void> call() {
    return repository.syncBackendUser();
  }
}
