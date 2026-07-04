import 'dart:io';

import 'package:flutter_application_55555/core/utils/either.dart';
import 'package:flutter_application_55555/core/error/failures.dart';
import 'package:flutter_application_55555/core/models/recommendation.dart';
import '../entities/diagnosis_result.dart';
import '../entities/diagnosis_details.dart';
import '../entities/diagnosis_history_item.dart';

abstract class DiagnosisRepository {
  Future<Either<Failure, DiagnosisResult>> analyze(
    File image, {
    String? userId,
  });

  /// retrieve list of reference image URLs for a disease identifier
  Future<List<String>> getReferenceImages(String diseaseId);

  /// fetch the treatment plan JSON body for a diagnosis id
  Future<Map<String, dynamic>> getTreatmentPlan(String diagnosisId);

  /// fetches treatment recommendation entity for a diagnosis id.
  Future<Recommendation> getTreatmentRecommendation(String diagnosisId);

  /// retrieve detailed information about a given diagnosis
  /// may use an initial imageUrl to normalize the returned entity
  Future<Either<Failure, DiagnosisDetails>> getDiagnosisDetails(
    String diagnosisId, {
    String? imageUrl,
  });

  /// execute a treatment step for a diagnosis; stepOrder null means "next".
  Future<void> executeTreatmentStep({
    required String diagnosisId,
    int? stepOrder,
  });

  /// execute a treatment step and return backend payload.
  Future<Map<String, dynamic>> executeTreatmentStepWithResult({
    required String diagnosisId,
    int? stepOrder,
  });

  /// fetches raw diagnosis plan details used by treatment-plan UI.
  Future<Map<String, dynamic>> getDiagnosisPlanDetails(String diagnosisId);

  /// logs a scheduled treatment reminder notification in backend.
  Future<void> logTreatmentReminderNotification({
    required String diagnosisId,
    String? userId,
    required String body,
    required DateTime scheduledAt,
  });

  /// fetches diagnosis history list for the current backend user.
  Future<List<DiagnosisHistoryItem>> getDiagnosisHistory({String? userId});

  /// fetches the latest diagnosis summary item for the current backend user.
  Future<DiagnosisHistoryItem?> getLastDiagnosis({String? userId});

  /// syncs current Firebase user with backend and persists backend id.
  Future<void> syncBackendUser();
}
