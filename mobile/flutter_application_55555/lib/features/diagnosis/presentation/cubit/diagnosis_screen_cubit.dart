import 'dart:io' as io;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_application_55555/core/error/failures.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/entities/diagnosis_result.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/diagnose.dart';

part 'diagnosis_screen_state.dart';

class DiagnosisScreenCubit extends Cubit<DiagnosisScreenState> {
  final Diagnose _diagnose;
  final ImagePicker _picker;

  DiagnosisScreenCubit(this._diagnose, {ImagePicker? picker})
    : _picker = picker ?? ImagePicker(),
      super(DiagnosisScreenState.initial());

  Future<void> pickImage(
    ImageSource source, {
    required void Function(String message) onError,
  }) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) {
        emit(state.copyWith(pickedFile: picked, resultMessage: null));
      }
    } catch (e) {
      onError('فشل في اختيار الصورة: $e');
    }
  }

  void clearPickedImage() {
    emit(
      state.copyWith(pickedFile: null, resultMessage: null, errorMessage: null),
    );
  }

  Future<void> uploadImage({
    required void Function(String message) onError,
    required void Function(DiagnosisResult result, String imagePath) onSuccess,
  }) async {
    if (state.pickedFile == null) return;

    HapticFeedback.mediumImpact();

    emit(
      state.copyWith(
        isUploading: true,
        resultMessage: null,
        errorMessage: null,
      ),
    );

    try {
      final file = io.File(state.pickedFile!.path);

      final either = await _diagnose.call(file);

      either.fold(
        (failure) {
          if (failure is InvalidImageFailure) {
            onError('لم يتم التعرف على ورقة عنب\nالرجاء رفع صورة واضحة للورقة');
          } else if (failure is NetworkFailure) {
            onError('تحقق من اتصال الإنترنت');
          } else if (failure is TimeoutFailure) {
            onError('انتهى وقت الانتظار. تحقق من الاتصال بالإنترنت');
          } else {
            onError('خطأ أثناء الرفع: ${failure.message}');
          }
        },
        (result) {
          onSuccess(result, file.path);
        },
      );
    } finally {
      emit(state.copyWith(isUploading: false));
    }
  }
}
