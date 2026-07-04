class DiagnosisDetails {
  final String? treatmentName;
  final String? dosageInstructions;
  final String? diseaseName;
  final String? status;
  final String? description;
  final String? diseaseId;
  final List<String>? referenceImages;
  final double? confidence;
  final String? imageUrl;

  DiagnosisDetails({
    this.treatmentName,
    this.dosageInstructions,
    this.diseaseName,
    this.status,
    this.description,
    this.diseaseId,
    this.referenceImages,
    this.confidence,
    this.imageUrl,
  });
}
