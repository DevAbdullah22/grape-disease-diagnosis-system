part of 'diagnosis_screen_cubit.dart';

class DiagnosisScreenState {
  static const Object _unset = Object();

  final XFile? pickedFile;
  final bool isUploading;
  final String? resultMessage;
  final String? errorMessage;

  const DiagnosisScreenState({
    required this.pickedFile,
    required this.isUploading,
    required this.resultMessage,
    required this.errorMessage,
  });

  factory DiagnosisScreenState.initial() {
    return const DiagnosisScreenState(
      pickedFile: null,
      isUploading: false,
      resultMessage: null,
      errorMessage: null,
    );
  }

  DiagnosisScreenState copyWith({
    Object? pickedFile = _unset,
    bool? isUploading,
    Object? resultMessage = _unset,
    Object? errorMessage = _unset,
  }) {
    return DiagnosisScreenState(
      pickedFile: identical(pickedFile, _unset)
          ? this.pickedFile
          : pickedFile as XFile?,
      isUploading: isUploading ?? this.isUploading,
      resultMessage: identical(resultMessage, _unset)
          ? this.resultMessage
          : resultMessage as String?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
