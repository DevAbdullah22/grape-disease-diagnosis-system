import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_55555/core/contracts/app_runtime_contract.dart';
import 'package:flutter_application_55555/core/services/backend_service.dart';

import '../../domain/entities/diagnosis_result.dart';

abstract class DiagnosisLocalDataSource {
  Future<void> cacheLastDiagnosis(DiagnosisResult result);
  Future<String?> getStoredBackendUserId();
  Future<String?> getCurrentFirebaseUid();
  Future<void> syncBackendUser({bool force});
}

class DiagnosisLocalDataSourceImpl implements DiagnosisLocalDataSource {
  final BackendService backendService;

  DiagnosisLocalDataSourceImpl({required this.backendService});

  @override
  Future<void> cacheLastDiagnosis(DiagnosisResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final prefix = AppRuntimeContract.lastDiagnosisPrefix(uid);

    await prefs.setString('${prefix}disease', result.diseaseName);
    await prefs.setDouble('${prefix}confidence', result.confidence);
    await prefs.setString('${prefix}id', result.diagnosisId);
    await prefs.setString('${prefix}image', result.imageUrl);
    await prefs.setString('${prefix}date', DateTime.now().toIso8601String());
  }

  @override
  Future<String?> getStoredBackendUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(AppRuntimeContract.backendUserIdKey);
    return (value == null || value.isEmpty) ? null : value;
  }

  @override
  Future<String?> getCurrentFirebaseUid() async {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Future<void> syncBackendUser({bool force = false}) async {
    await backendService.sendUserToBackend(force: force);
  }
}
