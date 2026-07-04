import '../entities/diagnosis_details.dart';
import '../repositories/diagnosis_repository.dart';
import 'package:flutter_application_55555/core/utils/either.dart';
import 'package:flutter_application_55555/core/error/failures.dart';

class GetDiagnosisDetails {
  final DiagnosisRepository repository;

  GetDiagnosisDetails(this.repository);

  Future<Either<Failure, DiagnosisDetails>> call(
    String diagnosisId, {
    String? imageUrl,
  }) {
    return repository.getDiagnosisDetails(diagnosisId, imageUrl: imageUrl);
  }
}
