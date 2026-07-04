import 'dart:io';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class TtsAudioFileService {
  Future<String> synthesizeText({
    required FlutterTts tts,
    required String text,
    required String cacheKey,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      throw UnsupportedError(
        'TTS file synthesis is only supported on Android and iOS.',
      );
    }

    final target = await _resolveTarget(cacheKey);
    final file = File(target.filePath);

    if (await file.exists()) {
      await file.delete();
    }

    await tts.awaitSynthCompletion(true);
    final result = await tts.synthesizeToFile(text, target.synthesisArgument);
    if (result != 1) {
      throw StateError('Failed to synthesize speech.');
    }

    await _waitForFile(file);
    return target.filePath;
  }

  Future<void> deleteGeneratedFile(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return;
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<_TtsSynthesisTarget> _resolveTarget(String cacheKey) async {
    final safeKey = cacheKey.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final extension = Platform.isIOS ? 'caf' : 'wav';
    final directory = Platform.isIOS
        ? await getApplicationDocumentsDirectory()
        : await getTemporaryDirectory();
    final fileName = 'tts_$safeKey.$extension';
    final filePath = p.join(directory.path, fileName);

    return _TtsSynthesisTarget(
      filePath: filePath,
      synthesisArgument: Platform.isIOS ? fileName : filePath,
    );
  }

  Future<void> _waitForFile(File file) async {
    for (var i = 0; i < 20; i++) {
      if (await file.exists() && await file.length() > 0) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }

    throw StateError('Synthesized audio file was not created.');
  }
}

class _TtsSynthesisTarget {
  final String filePath;
  final String synthesisArgument;

  const _TtsSynthesisTarget({
    required this.filePath,
    required this.synthesisArgument,
  });
}
