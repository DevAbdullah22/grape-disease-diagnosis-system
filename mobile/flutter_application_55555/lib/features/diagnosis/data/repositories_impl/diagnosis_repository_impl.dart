import 'dart:async';
import 'dart:io';

import 'package:flutter_application_55555/core/utils/either.dart';
import 'package:flutter_application_55555/core/error/failures.dart';
import 'package:flutter_application_55555/core/models/recommendation.dart';
import '../../domain/entities/diagnosis_result.dart';
import '../../domain/entities/diagnosis_details.dart';
import '../../domain/entities/diagnosis_history_item.dart';
import '../models/diagnosis_details_model.dart';
import '../../domain/repositories/diagnosis_repository.dart';
import '../datasources/diagnosis_remote_datasource.dart';
import '../datasources/diagnosis_local_data_source.dart';
import '../exceptions.dart';

class DiagnosisRepositoryImpl implements DiagnosisRepository {
  final DiagnosisRemoteDataSource remote;
  final DiagnosisLocalDataSource local;

  DiagnosisRepositoryImpl(this.remote, this.local);

  @override
  Future<Either<Failure, DiagnosisResult>> analyze(
    File image, {
    String? userId,
  }) async {
    try {
      final model = await remote.analyze(image, userId: userId);
      // cache last diagnosis
      try {
        await local.cacheLastDiagnosis(model);
      } catch (_) {}
      return Right<Failure, DiagnosisResult>(model);
    } on InvalidImageException catch (e) {
      return Left<Failure, DiagnosisResult>(InvalidImageFailure(e.message));
    } on NetworkException catch (e) {
      return Left<Failure, DiagnosisResult>(NetworkFailure(e.message));
    } on RemoteTimeoutException catch (e) {
      return Left<Failure, DiagnosisResult>(TimeoutFailure(e.message));
    } catch (e) {
      return Left<Failure, DiagnosisResult>(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<List<String>> getReferenceImages(String diseaseId) async {
    return await remote.fetchReferenceImages(diseaseId);
  }

  @override
  Future<Map<String, dynamic>> getTreatmentPlan(String diagnosisId) async {
    return await remote.fetchTreatmentPlan(diagnosisId);
  }

  @override
  Future<Recommendation> getTreatmentRecommendation(String diagnosisId) async {
    final payload = await remote.fetchTreatmentPlan(diagnosisId);
    return Recommendation.fromJson(payload);
  }

  @override
  Future<Either<Failure, DiagnosisDetails>> getDiagnosisDetails(
    String diagnosisId, {
    String? imageUrl,
  }) async {
    try {
      final raw = await remote.fetchDiagnosisDetails(diagnosisId);
      final model = DiagnosisDetailsModel.fromJson(
        raw,
        imageUrl: imageUrl,
        baseUrl: remote.apiClient.baseUrl,
      );
      return Right<Failure, DiagnosisDetails>(model);
    } on TimeoutException catch (e) {
      return Left<Failure, DiagnosisDetails>(TimeoutFailure(e.toString()));
    } on NetworkException catch (e) {
      return Left<Failure, DiagnosisDetails>(NetworkFailure(e.message));
    } catch (e) {
      return Left<Failure, DiagnosisDetails>(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<void> executeTreatmentStep({
    required String diagnosisId,
    int? stepOrder,
  }) {
    return remote.executeTreatmentStep(
      diagnosisId: diagnosisId,
      stepOrder: stepOrder,
    );
  }

  @override
  Future<Map<String, dynamic>> executeTreatmentStepWithResult({
    required String diagnosisId,
    int? stepOrder,
  }) {
    return remote.executeTreatmentStepWithResult(
      diagnosisId: diagnosisId,
      stepOrder: stepOrder,
    );
  }

  @override
  Future<Map<String, dynamic>> getDiagnosisPlanDetails(String diagnosisId) {
    return remote.fetchDiagnosisPlanDetails(diagnosisId);
  }

  @override
  Future<void> logTreatmentReminderNotification({
    required String diagnosisId,
    String? userId,
    required String body,
    required DateTime scheduledAt,
  }) {
    return remote.logTreatmentReminderNotification(
      diagnosisId: diagnosisId,
      userId: userId,
      body: body,
      scheduledAt: scheduledAt,
    );
  }

  @override
  Future<List<DiagnosisHistoryItem>> getDiagnosisHistory({
    String? userId,
  }) async {
    final backendId = await _resolveBackendUserId(userId: userId);
    if (backendId == null || backendId.isEmpty) {
      throw Exception(
        'Ù„Ù… ÙŠØªÙ… Ø§Ù„Ø¹Ø«ÙˆØ± Ø¹Ù„Ù‰ Ù…Ø¹Ø±Ù‘Ù Ù…Ø³ØªØ®Ø¯Ù… Ø§Ù„Ø®Ø§Ø¯Ù…. Ø§Ù„Ø±Ø¬Ø§Ø¡ ØªØ³Ø¬ÙŠÙ„ Ø§Ù„Ø¯Ø®ÙˆÙ„ ÙˆØ¥Ø¹Ø§Ø¯Ø© Ø§Ù„Ù…Ø­Ø§ÙˆÙ„Ø©.',
      );
    }
    return remote.fetchDiagnosisHistory(backendId);
  }

  @override
  Future<DiagnosisHistoryItem?> getLastDiagnosis({String? userId}) async {
    final backendId = await _resolveBackendUserId(userId: userId);
    if (backendId == null || backendId.isEmpty) {
      throw Exception(
        'Unable to resolve backend user id. Please sign in and try again.',
      );
    }
    return remote.fetchLastDiagnosis(backendId);
  }

  @override
  Future<void> syncBackendUser() async {
    await local.syncBackendUser(force: true);
  }

  Future<String?> _resolveBackendUserId({String? userId}) async {
    final candidate = userId?.trim();
    var resolved = (candidate == null || candidate.isEmpty) ? null : candidate;

    resolved ??= await local.getCurrentFirebaseUid();
    if (resolved == null || resolved.isEmpty) {
      return null;
    }

    final stored = await local.getStoredBackendUserId();
    if (stored != null && stored.isNotEmpty) {
      return stored;
    }

    try {
      await local.syncBackendUser();
      final synced = await local.getStoredBackendUserId();
      if (synced != null && synced.isNotEmpty) {
        return synced;
      }
    } catch (_) {}

    final looksLikeBackendId = RegExp(
      r'^[0-9a-fA-F\-]{8,}$',
    ).hasMatch(resolved);
    if (looksLikeBackendId) {
      return resolved;
    }
    return null;
  }
}
