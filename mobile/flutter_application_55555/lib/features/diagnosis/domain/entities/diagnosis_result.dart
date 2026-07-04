class DiagnosisResult {
  final String diseaseId;
  final String diagnosisId;
  final String diseaseName;
  final double confidence;
  final String imageUrl;
  final String description;

  DiagnosisResult({
    required this.diseaseId,
    required this.diagnosisId,
    required this.diseaseName,
    required this.confidence,
    required this.imageUrl,
    required this.description,
  });
}
