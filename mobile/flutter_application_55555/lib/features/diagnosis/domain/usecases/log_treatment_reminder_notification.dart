import '../repositories/diagnosis_repository.dart';

class LogTreatmentReminderNotification {
  final DiagnosisRepository repository;

  LogTreatmentReminderNotification(this.repository);

  Future<void> call({
    required String diagnosisId,
    String? userId,
    required String body,
    required DateTime scheduledAt,
  }) {
    return repository.logTreatmentReminderNotification(
      diagnosisId: diagnosisId,
      userId: userId,
      body: body,
      scheduledAt: scheduledAt,
    );
  }
}
