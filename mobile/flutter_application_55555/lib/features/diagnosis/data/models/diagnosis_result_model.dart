import '../../domain/entities/diagnosis_result.dart';

class DiagnosisResultModel extends DiagnosisResult {
  final Map<String, dynamic> raw;

    DiagnosisResultModel({required this.raw})
      : super(
        diseaseId: raw['diseaseId']?.toString() ?? '',
        diagnosisId: raw['diagnosisId']?.toString() ?? '',
        diseaseName: raw['diseaseName']?.toString() ?? '',
        confidence: (raw['confidence'] != null)
          ? (raw['confidence'] as num).toDouble()
          : 0.0,
        imageUrl: raw['imageUrl']?.toString() ?? '',
        // Prefer 'diseaseDescription' if available, fallback to 'description'
        description: raw['diseaseDescription']?.toString() ?? raw['description']?.toString() ?? '',
      );

  factory DiagnosisResultModel.fromJson(Map<String, dynamic> json) {
    // normalize keys coming from API (C# uses PascalCase)
    final map = <String, dynamic>{};
    json.forEach((k, v) {
      final key = k.isNotEmpty ? (k[0].toLowerCase() + k.substring(1)) : k;
      map[key] = v;
    });
    return DiagnosisResultModel(raw: map);
  }

  Map<String, dynamic> toJson() => raw;
}
