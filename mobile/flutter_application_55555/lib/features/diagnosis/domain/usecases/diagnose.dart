import 'dart:async';
import 'dart:io';

import 'package:flutter_application_55555/core/utils/either.dart';
import 'package:flutter_application_55555/core/error/failures.dart';

import '../entities/diagnosis_result.dart';
import '../repositories/diagnosis_repository.dart';

class Diagnose {
  final DiagnosisRepository repository;

  Diagnose(this.repository);

  Future<Either<Failure, DiagnosisResult>> call(File image, {String? userId}) async {
    try {
      // Enforce same timeout as before (30s)
      final resFuture = repository.analyze(image, userId: userId);
      final result = await resFuture.timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('انتهى وقت الانتظار'),
      );
      return result;
    } on TimeoutException catch (e) {
      return Left<Failure, DiagnosisResult>(TimeoutFailure(e.message ?? 'Timeout'));
    } catch (e) {
      return Left<Failure, DiagnosisResult>(UnknownFailure(e.toString()));
    }
  }
}
