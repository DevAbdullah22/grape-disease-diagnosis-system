import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_application_55555/features/diagnosis/domain/entities/diagnosis_details.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/get_diagnosis_details.dart';
import 'package:flutter_application_55555/core/error/failures.dart';

part 'diagnosis_details_state.dart';

class DiagnosisDetailsCubit extends Cubit<DiagnosisDetailsState> {
  final GetDiagnosisDetails _getDiagnosisDetails;

  DiagnosisDetailsCubit(this._getDiagnosisDetails)
      : super(DiagnosisDetailsInitial());

  Future<void> fetch(
    String id, {
    String? imageUrl,
    DateTime? date,
    String? disease,
    String? status,
    double? confidence,
    List<String>? referenceImages,
    String? description,
  }) async {
    emit(DiagnosisDetailsLoading());
    final result = await _getDiagnosisDetails(id, imageUrl: imageUrl);
    result.fold(
      (failure) {
        emit(DiagnosisDetailsError(_mapFailureToMessage(failure)));
      },
      (details) {
        emit(DiagnosisDetailsLoaded(
          details: details,
          initialImageUrl: imageUrl,
          initialDate: date,
          initialDisease: disease,
          initialStatus: status,
          initialConfidence: confidence,
          initialReferenceImages: referenceImages,
          initialDescription: description,
        ));
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is NetworkFailure) {
      return 'تعذر الاتصال بالخادم.';
    }
    if (failure is TimeoutFailure) {
      return 'انتهت مهلة الاتصال.';
    }
    return 'حدث خطأ غير متوقع.';
  }
}
