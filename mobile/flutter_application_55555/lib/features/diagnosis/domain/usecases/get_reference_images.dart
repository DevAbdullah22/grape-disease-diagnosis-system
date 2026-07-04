import '../repositories/diagnosis_repository.dart';

class GetReferenceImages {
  final DiagnosisRepository repository;

  GetReferenceImages(this.repository);

  Future<List<String>> call(String diseaseId) =>
      repository.getReferenceImages(diseaseId);
}