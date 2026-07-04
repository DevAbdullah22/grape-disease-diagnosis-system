import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/entities/diagnosis_result.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/get_reference_images.dart';
import 'package:flutter_application_55555/features/diagnosis/presentation/cubit/diagnosis_result_screen_cubit.dart';
import 'package:flutter_application_55555/features/diagnosis/presentation/screens/diagnosis_result_screen.dart';

Widget buildDiagnosisResultScreen({
  Key? key,
  required DiagnosisResult result,
  String? imagePath,
}) {
  return BlocProvider<DiagnosisResultScreenCubit>(
    create: (context) {
      final cubit = DiagnosisResultScreenCubit(
        getReferenceImages: context.read<GetReferenceImages>(),
        result: result,
        imagePath: imagePath,
      );
      cubit.loadReferenceImages();
      return cubit;
    },
    child: DiagnosisResultScreen(
      key: key,
      result: result,
      imagePath: imagePath,
    ),
  );
}
