import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/entities/diagnosis_result.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/get_reference_images.dart';
import 'package:flutter_application_55555/features/diagnosis/presentation/cubit/diagnosis_result_screen_state.dart';

class DiagnosisResultScreenCubit extends Cubit<DiagnosisResultScreenState> {
  final GetReferenceImages _getReferenceImages;

  DiagnosisResultScreenCubit({
    required GetReferenceImages getReferenceImages,
    required DiagnosisResult result,
    String? imagePath,
  }) : _getReferenceImages = getReferenceImages,
       super(
         DiagnosisResultScreenState.initial(
           result: result,
           imagePath: imagePath,
         ),
       );

  Future<void> loadReferenceImages() async {
    emit(
      state.copyWith(
        isReferenceImagesLoading: true,
        referenceImagesError: null,
        errorMessage: null,
      ),
    );

    try {
      final images = await _getReferenceImages.call(
        state.result.diseaseId.toString(),
      );
      emit(
        state.copyWith(
          isReferenceImagesLoading: false,
          referenceImages: images,
          referenceImagesError: null,
          errorMessage: null,
        ),
      );
    } catch (_) {
      const message = 'الاتصال ضعيف — حاول لاحقًا';
      emit(
        state.copyWith(
          isReferenceImagesLoading: false,
          referenceImages: const <String>[],
          referenceImagesError: message,
          errorVersion: state.errorVersion + 1,
          errorMessage: message,
        ),
      );
    }
  }

  void toggleDescription() {
    emit(state.copyWith(showFullDescription: !state.showFullDescription));
  }

  void requestOpenTreatmentRecommendations() {
    emit(
      state.copyWith(
        openTreatmentPlanVersion: state.openTreatmentPlanVersion + 1,
      ),
    );
  }

  void requestShare() {
    final r = state.result;
    final buffer = StringBuffer();
    buffer.writeln('نتيجة تشخيص مرض العنب');
    buffer.writeln(
      'المرض: ${r.diseaseName.isNotEmpty ? r.diseaseName : "غير معروف"}',
    );
    buffer.writeln('درجة الثقة: ${(r.confidence * 100).toStringAsFixed(0)}%');
    if (r.description.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('وصف قصير:');
      buffer.writeln(
        r.description.length > 120
            ? '${r.description.substring(0, 120)}...'
            : r.description,
      );
    }
    emit(
      state.copyWith(
        shareText: buffer.toString(),
        shareVersion: state.shareVersion + 1,
      ),
    );
  }
}
