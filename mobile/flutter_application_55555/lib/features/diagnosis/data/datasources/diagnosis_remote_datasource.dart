import 'dart:convert';
import 'dart:io';

import 'package:flutter_application_55555/core/contracts/app_runtime_contract.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../exceptions.dart';

import 'package:flutter_application_55555/core/api_client.dart';
import 'package:flutter_application_55555/core/services/config.dart';
import '../models/diagnosis_result_model.dart';
import '../models/diagnosis_history_item_model.dart';

class DiagnosisRemoteDataSource {
  final ApiClient apiClient;

  DiagnosisRemoteDataSource(this.apiClient);

  Future<DiagnosisResultModel> analyze(File image, {String? userId}) async {
    final uri = Uri.parse('${apiClient.baseUrl}/api/Diagnosis/analyze');
    final request = http.MultipartRequest('POST', uri);

    final multipartFile = await http.MultipartFile.fromPath(
      'Image',
      image.path,
      filename: p.basename(image.path),
    );
    request.files.add(multipartFile);

    // Attach backend user id only if it's a GUID; otherwise try stored backend id
    final guidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    if (userId != null && guidRegex.hasMatch(userId)) {
      request.fields['UserId'] = userId;
    } else {
      try {
        final prefs = await SharedPreferences.getInstance();
        final stored = prefs.getString(AppRuntimeContract.backendUserIdKey);
        if (stored != null && guidRegex.hasMatch(stored)) {
          request.fields['UserId'] = stored;
        }
      } catch (e) {
        // ignore
      }
    }

    // Attach Firebase idToken if user is signed in; some backends expect it
    String? idTokenForHeader;
    try {
      final current = FirebaseAuth.instance.currentUser;
      if (current != null) {
        final idToken = await current.getIdToken();
        if (idToken != null && idToken.isNotEmpty) {
          request.fields['IdToken'] = idToken;
          idTokenForHeader = idToken;
        }
      }
    } catch (e) {
      // ignore token attach failures; continue without token
      // ignore: avoid_print
      print('Warning: failed to attach idToken to diagnosis request: $e');
    }

    // Also set Authorization header if we have an idToken - many backends expect this
    if (idTokenForHeader != null && idTokenForHeader.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $idTokenForHeader';
    }

    final streamed = await apiClient.sendMultipart(request);
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode == 200) {
      try {
        final json = jsonDecode(resp.body);
        if (json is Map<String, dynamic>) {
          return DiagnosisResultModel.fromJson(json);
        }
        return DiagnosisResultModel(raw: {'result': resp.body});
      } catch (e) {
        return DiagnosisResultModel(raw: {'result': resp.body});
      }
    } else {
      // Attempt to parse known error payloads (e.g., { message, imageUrl })
      try {
        final parsed = jsonDecode(resp.body);
        if (parsed is Map<String, dynamic> && parsed.containsKey('message')) {
          final msg = parsed['message']?.toString() ?? '';
          // throw a marked exception so upper layers can map to a Failure
          throw InvalidImageException(msg);
        }
      } catch (_) {
        // fallthrough to generic exception below
      }
      // Include response body to help debugging 4xx/5xx responses
      throw UnknownRemoteException(
        'RemoteDataSource error: ${resp.statusCode} ${resp.reasonPhrase} - body: ${resp.body}',
      );
    }
  }

  /// Executes a treatment step on the backend. StepOrder may be null.
  Future<void> executeTreatmentStep({
    required String diagnosisId,
    int? stepOrder,
  }) async {
    await executeTreatmentStepWithResult(
      diagnosisId: diagnosisId,
      stepOrder: stepOrder,
    );
  }

  /// Executes a treatment step and returns backend response payload.
  Future<Map<String, dynamic>> executeTreatmentStepWithResult({
    required String diagnosisId,
    int? stepOrder,
  }) async {
    final endpoint = stepOrder == null
        ? '${Config.apiBaseUrl}/api/treatment/execute-step/$diagnosisId'
        : '${Config.apiBaseUrl}/api/treatment/execute-step/$diagnosisId?stepOrder=$stepOrder';
    final response = await http
        .post(Uri.parse(endpoint))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode == 200) {
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {}
      return {'message': response.body};
    } else {
      throw HttpException(response.statusCode.toString());
    }
  }

  /// Fetches diagnosis plan details and builds doses timeline data.
  Future<Map<String, dynamic>> fetchDiagnosisPlanDetails(
    String diagnosisId,
  ) async {
    final uri = Uri.parse(
      '${Config.apiBaseUrl}/api/agriculturallog/diagnosis/$diagnosisId',
    );
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw HttpException(response.statusCode.toString());
    }

    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected treatment plan payload shape');
    }

    final executions = (decoded['executions'] as List?) ?? const [];
    final rule = (decoded['treatmentRule'] as Map?) ?? const {};
    final totalDoses = (rule['totalDoses'] as num?)?.toInt() ?? 0;
    final pesticideName = rule['pesticideName']?.toString() ?? '';
    final doseIntervalDays = (rule['doseIntervalDays'] as num?)?.toInt() ?? 0;
    final diagnosisDate = decoded['diagnosisDate']?.toString() ?? '';

    final doses = <Map<String, dynamic>>[];
    DateTime? lastDate;
    for (var i = 0; i < totalDoses; i++) {
      final exec = executions.length > i ? executions[i] : null;
      String status;
      if (exec != null) {
        status = 'تم التنفيذ بنجاح';
      } else if (executions.length == i) {
        status = 'تأكيد تنفيذ الجرعة';
      } else {
        status = 'بانتظار التنفيذ';
      }

      String doseDate;
      if (exec != null && exec['executedAt'] != null) {
        doseDate = exec['executedAt'].toString();
        lastDate = DateTime.tryParse(exec['executedAt'].toString());
      } else if (i == 0) {
        doseDate = diagnosisDate;
        lastDate = DateTime.tryParse(diagnosisDate);
      } else if (lastDate != null) {
        lastDate = lastDate.add(Duration(days: doseIntervalDays));
        doseDate = lastDate.toIso8601String();
      } else {
        doseDate = '';
      }

      doses.add({
        'title': 'الجرعة ${_arabicDoseNumber(i + 1)}',
        'date': doseDate,
        'pesticide': pesticideName,
        'status': status,
        'isCurrent': executions.length == i,
        'doseNumber': i + 1,
      });
    }

    decoded['doses'] = doses;
    decoded['executedDoses'] = executions.length;
    decoded['totalDoses'] = totalDoses;
    return decoded;
  }

  Future<List<DiagnosisHistoryItemModel>> fetchDiagnosisHistory(
    String backendUserId,
  ) async {
    final encodedId = Uri.encodeComponent(backendUserId);
    final uri = Uri.parse(
      '${apiClient.baseUrl}/api/AgriculturalLog/$encodedId/history',
    );
    final resp = await http.get(uri).timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) {
      throw HttpException('History request failed: ${resp.statusCode}');
    }

    final decoded = json.decode(resp.body);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((e) => _parseDiagnosisHistoryItem(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<DiagnosisHistoryItemModel?> fetchLastDiagnosis(
    String backendUserId,
  ) async {
    final encodedId = Uri.encodeQueryComponent(backendUserId);
    final uri = Uri.parse(
      '${apiClient.baseUrl}/api/Diagnosis/last?userId=$encodedId',
    );
    final resp = await http.get(uri).timeout(const Duration(seconds: 10));
    if (resp.statusCode == 404) {
      return null;
    }
    if (resp.statusCode != 200) {
      throw HttpException('Last diagnosis request failed: ${resp.statusCode}');
    }

    final decoded = json.decode(resp.body);
    if (decoded is! Map) return null;
    return _parseDiagnosisHistoryItem(Map<String, dynamic>.from(decoded));
  }

  Future<void> logTreatmentReminderNotification({
    required String diagnosisId,
    String? userId,
    required String body,
    required DateTime scheduledAt,
  }) async {
    final logUrl = Uri.parse('${Config.apiBaseUrl}/api/notifications/log');
    await http.post(
      logUrl,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userId': userId ?? '',
        'title': 'تذكير جرعة العلاج',
        'body': body,
        'type': 'TreatmentReminder',
        'relatedId': diagnosisId,
        'scheduledAt': scheduledAt.toIso8601String(),
      }),
    );
  }

  /// Fetch reference image URLs for the given disease id.
  /// Returns empty list on any failure.
  Future<List<String>> fetchReferenceImages(String diseaseId) async {
    // similar baseUrl workaround as used in the screen previously
    String baseUrl = apiClient.baseUrl;
    try {
      if (baseUrl.contains('localhost') && Platform.isAndroid) {
        baseUrl = baseUrl.replaceFirst('localhost', '10.0.2.2');
      }
    } catch (_) {}

    if (diseaseId.isEmpty) return [];

    final uri = Uri.parse('$baseUrl/api/disease/$diseaseId/reference-images');
    http.Response resp;
    try {
      resp = await http.get(uri).timeout(const Duration(seconds: 8));
    } catch (e) {
      // network failure
      throw NetworkException(e.toString());
    }

    if (resp.statusCode != 200) return [];

    try {
      final List data = json.decode(resp.body) as List;
      return data
          .map<String>((e) {
            final raw = (e['imageUrl'] ?? '').toString();
            if (raw.isEmpty) return '';
            if (raw.startsWith('/')) return baseUrl + raw;
            return raw;
          })
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> fetchTreatmentPlan(String diagnosisId) async {
    String baseUrl = apiClient.baseUrl;
    try {
      if (baseUrl.contains('localhost') && Platform.isAndroid) {
        baseUrl = baseUrl.replaceFirst('localhost', '10.0.2.2');
      }
    } catch (_) {}

    final uri = Uri.parse('$baseUrl/api/treatment/plan/$diagnosisId');
    http.Response response;
    try {
      response = await http.get(uri).timeout(const Duration(seconds: 15));
    } catch (e) {
      throw NetworkException(e.toString());
    }

    if (response.statusCode != 200) {
      throw UnknownRemoteException('status:${response.statusCode}');
    }

    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected payload shape');
    }
    final body = Map<String, dynamic>.from(decoded);

    if (body.containsKey('steps') &&
        body['steps'] is List &&
        (body['steps'] as List).isNotEmpty) {
      final steps = body['steps'] as List;
      final first = steps.first as Map<String, dynamic>;

      body['pesticideName'] ??=
          first['pesticideName'] ?? first['PesticideName'];
      body['PesticideName'] ??= body['pesticideName'];
      body['dosageInstructions'] ??=
          first['dosageInstructions'] ?? first['DosageInstructions'];
      body['DosageInstructions'] ??= body['dosageInstructions'];
      body['safetyInfo'] ??= first['safetyInfo'] ?? first['SafetyInfo'];
      body['SafetyInfo'] ??= body['safetyInfo'];
      body['importantNotes'] ??=
          first['importantNotes'] ?? first['ImportantNotes'];
      body['ImportantNotes'] ??= body['importantNotes'];
      body['mixQuantityAndType'] ??=
          first['mixQuantityAndType'] ?? first['MixQuantityAndType'];
      body['MixQuantityAndType'] ??= body['mixQuantityAndType'];
      body['TotalDoses'] ??= steps.length;
      body['DoseIntervalDays'] ??=
          first['intervalDays'] ?? first['IntervalDays'];
    }

    return body;
  }

  /// Fetches diagnosis details payload and performs normalization.
  /// If reference images are missing but a diseaseId exists we attempt an
  /// additional request to retrieve them.
  Future<Map<String, dynamic>> fetchDiagnosisDetails(String diagnosisId) async {
    String baseUrl = apiClient.baseUrl;
    try {
      if (baseUrl.contains('localhost') && Platform.isAndroid) {
        baseUrl = baseUrl.replaceFirst('localhost', '10.0.2.2');
      }
    } catch (_) {}

    final uri = Uri.parse(
      '$baseUrl/api/AgriculturalLog/diagnosis/$diagnosisId',
    );
    http.Response resp;
    try {
      resp = await http.get(uri).timeout(const Duration(seconds: 10));
    } catch (e) {
      throw NetworkException(e.toString());
    }

    if (resp.statusCode != 200) {
      throw UnknownRemoteException('status:${resp.statusCode}');
    }

    final Map<String, dynamic> data = json.decode(resp.body);

    dynamic refRaw = _findValue(data, [
      'referenceImages',
      'referenceImageUrls',
      'referenceimages',
      'exampleImages',
      'referencePhotos',
      'images',
      'Images',
      'example_images',
    ]);

    String? diseaseIdFromData = _findValue(data, [
      'diseaseId',
      'DiseaseId',
      'diseaseID',
      'DiseaseID',
      'disease_id',
      'Disease_Id',
    ])?.toString();

    if ((refRaw == null || (refRaw is List && refRaw.isEmpty)) &&
        diseaseIdFromData != null &&
        diseaseIdFromData.isNotEmpty) {
      try {
        final extra = await fetchReferenceImages(diseaseIdFromData);
        if (extra.isNotEmpty) {
          data['referenceImages'] = extra;
        }
      } catch (_) {}
    }

    return data;
  }

  dynamic _findValue(Map<String, dynamic> node, List<String> candidateKeys) {
    final lowerKeys = candidateKeys.map((e) => e.toLowerCase()).toSet();

    dynamic walk(dynamic current) {
      if (current is Map) {
        for (final entry in current.entries) {
          final key = entry.key.toString().toLowerCase();
          if (lowerKeys.contains(key) && entry.value != null) {
            return entry.value;
          }
        }
        for (final entry in current.entries) {
          final nested = walk(entry.value);
          if (nested != null) return nested;
        }
      } else if (current is List) {
        for (final item in current) {
          final nested = walk(item);
          if (nested != null) return nested;
        }
      }
      return null;
    }

    return walk(node);
  }

  String _arabicDoseNumber(int n) {
    const nums = [
      'الأولى',
      'الثانية',
      'الثالثة',
      'الرابعة',
      'الخامسة',
      'السادسة',
      'السابعة',
      'الثامنة',
      'التاسعة',
      'العاشرة',
    ];
    return n <= nums.length ? nums[n - 1] : n.toString();
  }

  DiagnosisHistoryItemModel _parseDiagnosisHistoryItem(
    Map<String, dynamic> raw,
  ) {
    // Support both camelCase and PascalCase payload shapes.
    return DiagnosisHistoryItemModel.fromJson({
      'diagnosisId': raw['diagnosisId'] ?? raw['DiagnosisId'],
      'diseaseName': raw['diseaseName'] ?? raw['DiseaseName'],
      'imageUrl': raw['imageUrl'] ?? raw['ImageUrl'],
      'status': raw['status'] ?? raw['Status'],
      'diagnosisDate': raw['diagnosisDate'] ?? raw['DiagnosisDate'],
      'date': raw['date'] ?? raw['Date'],
    });
  }
}
