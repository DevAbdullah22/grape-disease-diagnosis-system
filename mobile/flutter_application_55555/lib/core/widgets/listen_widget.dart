import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';

import '../audio/tts_audio_file_service.dart';
import 'app_markdown_body.dart';
import 'tts_audio_control_bar.dart';

typedef ListenWidgetBuilder =
    Widget Function(BuildContext context, ListenRenderScope scope);

class ListenRenderScope {
  final bool isSpeaking;
  final bool playerVisible;
  final bool playerExpanded;
  final double extraBottomPadding;
  final Widget listenButton;
  final Widget bottomPlayer;
  final Widget markdownBody;
  final bool hasShortDescription;
  final Widget Function(TextStyle style, {TextAlign textAlign})
  buildHighlightedTitle;
  final Widget Function(TextStyle style, {TextAlign textAlign})
  buildHighlightedShortDescription;

  /// Allows the host screen to invoke the play/pause toggle logic without
  /// rendering the default button. This keeps all speaking behaviour
  /// encapsulated inside [ListenWidget].
  final VoidCallback toggleSpeak;

  ListenRenderScope({
    required this.isSpeaking,
    required this.playerVisible,
    required this.playerExpanded,
    required this.extraBottomPadding,
    required this.listenButton,
    required this.bottomPlayer,
    required this.markdownBody,
    required this.hasShortDescription,
    required this.buildHighlightedTitle,
    required this.buildHighlightedShortDescription,
    required this.toggleSpeak,
  });
}

class ListenWidget extends StatefulWidget {
  final String contentId;
  final String title;
  final String? shortDescription;
  final String markdownContent;
  final String playerTitle;
  final ListenWidgetBuilder builder;

  const ListenWidget({
    super.key,
    required this.contentId,
    required this.title,
    required this.shortDescription,
    required this.markdownContent,
    required this.playerTitle,
    required this.builder,
  });

  @override
  State<ListenWidget> createState() => _ListenWidgetState();
}

class _ListenWidgetState extends State<ListenWidget> {
  FlutterTts? _tts;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TtsAudioFileService _ttsAudioFileService = TtsAudioFileService();

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _bufferedPositionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  bool _ttsAvailable = true;
  bool _isSpeaking = false;
  bool _isPreparingAudio = false;
  bool _playerVisible = false;

  Duration _currentPosition = Duration.zero;
  Duration _bufferedPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  String _ttsText = '';
  String _plainTitle = '';
  String _plainShort = '';
  String _plainContent = '';
  List<int> _contentPlainToRaw = const <int>[];

  int _resumeOffset = 0;
  int _highlightStart = -1;
  int _highlightEnd = -1;

  int _titleStart = -1;
  int _shortStart = -1;
  int _contentStart = -1;

  double _speedX = 1.0;
  static const List<double> _speedSteps = [0.8, 1.0, 1.2, 1.4];
  String? _activeContentId;
  String? _audioCacheKey;
  String? _preparedAudioKey;
  String? _audioFilePath;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  @override
  void didUpdateWidget(covariant ListenWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contentId != widget.contentId) {
      _stopSpeaking(hidePlayer: true, resetProgress: true);
      _activeContentId = null;
      _ttsText = '';
      _plainTitle = '';
      _plainShort = '';
      _plainContent = '';
      _contentPlainToRaw = const <int>[];
      _audioCacheKey = null;
      _preparedAudioKey = null;
      _audioFilePath = null;
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _bufferedPositionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    unawaited(_audioPlayer.dispose());
    _tts?.stop();
    _tts = null;
    unawaited(_ttsAudioFileService.deleteGeneratedFile(_audioFilePath));
    super.dispose();
  }

  Future<void> _initTts() async {
    try {
      _tts = FlutterTts();

      try {
        final voices = await _tts?.getVoices;
        if (voices != null) {
          Map? ar;
          for (final v in voices) {
            if (v is Map) {
              final locale = (v['locale'] ?? v['name'] ?? '').toString();
              if (locale.startsWith('ar')) {
                ar = v;
                break;
              }
            }
          }
          if (ar != null) {
            final voiceMap = <String, String>{};
            ar.forEach((k, v) => voiceMap[k.toString()] = v.toString());
            await _tts?.setVoice(voiceMap);
          }
        }
      } catch (_) {}

      try {
        await _tts?.setLanguage('ar');
      } catch (_) {
        try {
          await _tts?.setLanguage('ar-SA');
        } catch (_) {}
      }

      if (Platform.isIOS) {
        try {
          await _tts?.setSharedInstance(true);
          await _tts?.setIosAudioCategory(
            IosTextToSpeechAudioCategory.playback,
            const [
              IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
              IosTextToSpeechAudioCategoryOptions.allowBluetooth,
              IosTextToSpeechAudioCategoryOptions.allowAirPlay,
            ],
          );
          await _tts?.autoStopSharedSession(false);
        } catch (_) {}
      }

      await _applyTtsVoiceSettings();
      _listenToAudioPlayer();
      if (mounted) setState(() => _ttsAvailable = true);
    } catch (_) {
      if (mounted) setState(() => _ttsAvailable = false);
    }
  }

  void _listenToAudioPlayer() {
    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      if (!mounted) return;
      setState(() {
        _syncPositionState(position);
      });
    });

    _bufferedPositionSubscription = _audioPlayer.bufferedPositionStream.listen((
      buffered,
    ) {
      if (!mounted) return;
      setState(() {
        _bufferedPosition = _clampDuration(buffered, _totalDuration);
      });
    });

    _durationSubscription = _audioPlayer.durationStream.listen((duration) {
      if (!mounted) return;
      final safeDuration = duration ?? Duration.zero;
      setState(() {
        _totalDuration = safeDuration;
        _bufferedPosition = _clampDuration(_bufferedPosition, _totalDuration);
        _syncPositionState(_currentPosition);
      });
    });

    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (!mounted) return;
      final completed = state.processingState == ProcessingState.completed;

      setState(() {
        _isSpeaking = state.playing;
        if (completed) {
          _syncPositionState(_totalDuration, clearHighlightAtEnd: true);
        }
      });
    });
  }

  Future<void> _applyTtsVoiceSettings() async {
    try {
      await _tts?.setSpeechRate(_mapSpeedToSpeechRate(1.0));
      await _tts?.setVolume(1.0);
      await _tts?.setPitch(1.0);
    } catch (_) {}
  }

  double _mapSpeedToSpeechRate(double speedX) {
    final value = 0.38 * speedX;
    return value.clamp(0.22, 0.62);
  }

  Duration _durationFromOffset(int offset) {
    if (_ttsText.isEmpty || _totalDuration == Duration.zero) {
      return Duration.zero;
    }
    final safeOffset = math.max(0, math.min(offset, _ttsText.length));
    final ratio = _ttsText.isEmpty ? 0.0 : safeOffset / _ttsText.length;
    return Duration(
      milliseconds: (_totalDuration.inMilliseconds * ratio).round(),
    );
  }

  int _offsetFromDuration(Duration duration) {
    if (_ttsText.isEmpty || _totalDuration == Duration.zero) return 0;
    final safeDuration = _clampDuration(duration, _totalDuration);
    final ratio = safeDuration.inMilliseconds / _totalDuration.inMilliseconds;
    final raw = (ratio * _ttsText.length).round();
    return math.max(0, math.min(raw, _ttsText.length));
  }

  ({int start, int end}) _wordBoundsAtOffset(int offset) {
    if (_ttsText.isEmpty) return (start: 0, end: 0);
    var i = math.max(0, math.min(offset, _ttsText.length - 1));

    if (i < _ttsText.length && _ttsText[i].trim().isEmpty) {
      while (i < _ttsText.length && _ttsText[i].trim().isEmpty) {
        i++;
      }
      if (i >= _ttsText.length) {
        i = math.max(0, _ttsText.length - 1);
      }
    }

    var start = i;
    while (start > 0 && _ttsText[start - 1].trim().isNotEmpty) {
      start--;
    }

    var end = i + 1;
    while (end < _ttsText.length && _ttsText[end].trim().isNotEmpty) {
      end++;
    }

    if (end <= start) {
      end = math.min(_ttsText.length, start + 1);
    }
    return (start: start, end: end);
  }

  Duration _clampDuration(Duration value, Duration max) {
    if (max <= Duration.zero) return Duration.zero;
    final clamped = math.max(
      0,
      math.min(value.inMilliseconds, max.inMilliseconds),
    );
    return Duration(milliseconds: clamped);
  }

  void _syncPositionState(
    Duration position, {
    bool clearHighlightAtEnd = false,
  }) {
    _currentPosition = _clampDuration(position, _totalDuration);
    _resumeOffset = _offsetFromDuration(_currentPosition);

    if (clearHighlightAtEnd &&
        _totalDuration > Duration.zero &&
        _currentPosition >= _totalDuration) {
      _highlightStart = -1;
      _highlightEnd = -1;
      return;
    }

    _updateHighlightFromOffset(_resumeOffset);
  }

  void _updateHighlightFromOffset(int offset) {
    if (_ttsText.isEmpty || offset >= _ttsText.length) {
      _highlightStart = -1;
      _highlightEnd = -1;
      return;
    }

    final bounds = _wordBoundsAtOffset(offset);
    _highlightStart = bounds.start;
    _highlightEnd = bounds.end;
  }

  String _buildAudioCacheKey() {
    return '${widget.contentId}_${_ttsText.hashCode.abs()}';
  }

  void _prepareSpeechPayload() {
    _activeContentId = widget.contentId;
    _plainTitle = widget.title.trim();
    _plainShort = (widget.shortDescription ?? '').trim();
    final extracted = _extractSpeakableFromMarkdown(widget.markdownContent);
    _plainContent = extracted.text;
    _contentPlainToRaw = extracted.plainToRaw;

    final buffer = StringBuffer();
    var cursor = 0;

    void append(String value, void Function(int start) onStart) {
      final text = value.trim();
      if (text.isEmpty) {
        onStart(-1);
        return;
      }
      if (buffer.isNotEmpty) {
        buffer.write('\n\n');
        cursor += 2;
      }
      onStart(cursor);
      buffer.write(text);
      cursor += text.length;
    }

    append(_plainTitle, (s) => _titleStart = s);
    append(_plainShort, (s) => _shortStart = s);
    append(_plainContent, (s) => _contentStart = s);

    _ttsText = buffer.toString().trim();
    _currentPosition = Duration.zero;
    _bufferedPosition = Duration.zero;
    _totalDuration = Duration.zero;
    _resumeOffset = 0;
    _highlightStart = -1;
    _highlightEnd = -1;
    final nextAudioKey = _buildAudioCacheKey();
    if (_preparedAudioKey != null && _preparedAudioKey != nextAudioKey) {
      _preparedAudioKey = null;
      _audioFilePath = null;
    }
    _audioCacheKey = nextAudioKey;
  }

  Future<void> _ensureAudioSourcePrepared() async {
    if (_tts == null || _ttsText.trim().isEmpty || _audioCacheKey == null) {
      return;
    }

    if (_preparedAudioKey == _audioCacheKey &&
        _audioFilePath != null &&
        _totalDuration > Duration.zero) {
      await _audioPlayer.setSpeed(_speedX);
      return;
    }

    if (mounted) {
      setState(() {
        _isPreparingAudio = true;
        _bufferedPosition = Duration.zero;
      });
    }

    try {
      final filePath = await _ttsAudioFileService.synthesizeText(
        tts: _tts!,
        text: _ttsText,
        cacheKey: _audioCacheKey!,
      );
      final duration = await _audioPlayer.setFilePath(filePath);
      await _audioPlayer.setSpeed(_speedX);

      if (!mounted) return;
      setState(() {
        _audioFilePath = filePath;
        _preparedAudioKey = _audioCacheKey;
        _totalDuration = duration ?? Duration.zero;
        _bufferedPosition = _totalDuration;
        _syncPositionState(_currentPosition);
      });
    } finally {
      if (mounted) {
        setState(() => _isPreparingAudio = false);
      }
    }
  }

  Future<void> _startSpeakingFromOffset(int offset) async {
    if (!_ttsAvailable) return;
    if (_tts == null || _ttsText.trim().isEmpty) return;

    final safeOffset = math.max(0, math.min(offset, _ttsText.length));
    setState(() {
      _playerVisible = true;
      _resumeOffset = safeOffset;
      _updateHighlightFromOffset(safeOffset);
    });

    await _ensureAudioSourcePrepared();
    if (_totalDuration == Duration.zero) return;

    final target = safeOffset >= _ttsText.length
        ? Duration.zero
        : _durationFromOffset(safeOffset);

    if (mounted) {
      setState(() {
        _syncPositionState(target);
      });
    }

    await _audioPlayer.seek(target);
    await _audioPlayer.play();
  }

  Future<void> _pauseSpeaking() async {
    if (!_isSpeaking) return;
    await _audioPlayer.pause();
    if (!mounted) return;
    setState(() => _isSpeaking = false);
  }

  Future<void> _stopSpeaking({
    bool hidePlayer = false,
    bool resetProgress = false,
  }) async {
    await _audioPlayer.pause();
    await _audioPlayer.seek(Duration.zero);
    if (!mounted) return;

    setState(() {
      _isSpeaking = false;
      _isPreparingAudio = false;
      if (resetProgress) {
        _currentPosition = Duration.zero;
        _resumeOffset = 0;
        _highlightStart = -1;
        _highlightEnd = -1;
      }
      if (hidePlayer) {
        _playerVisible = false;
      }
    });
  }

  Future<void> _toggleSpeak() async {
    debugPrint(
      '[ListenWidget] _toggleSpeak called for contentId=${widget.contentId}',
    );
    if (!_ttsAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ميزة الاستماع غير متاحة على هذا الجهاز')),
      );
      return;
    }

    if (_isPreparingAudio) return;

    if (_activeContentId != widget.contentId || _ttsText.isEmpty) {
      _prepareSpeechPayload();
    }

    if (_ttsText.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('لا يوجد نص للاستماع.')));
      return;
    }

    if (!_playerVisible) {
      setState(() => _playerVisible = true);
    }

    if (_isSpeaking) {
      await _pauseSpeaking();
      return;
    }

    var startOffset = _resumeOffset;
    if (startOffset >= _ttsText.length) {
      startOffset = 0;
      setState(() {
        _currentPosition = Duration.zero;
        _resumeOffset = 0;
      });
    }

    try {
      await _startSpeakingFromOffset(startOffset);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSpeaking = false;
        _isPreparingAudio = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to prepare audio playback.')),
      );
    }
  }

  Future<void> _seekBySeconds(int seconds) async {
    if (_ttsText.isEmpty || _totalDuration == Duration.zero) return;
    final targetMs = _currentPosition.inMilliseconds + (seconds * 1000);
    final clamped = math.max(
      0,
      math.min(targetMs, _totalDuration.inMilliseconds),
    );
    await _seekTo(Duration(milliseconds: clamped));
  }

  Future<void> _seekTo(Duration target) async {
    if (_ttsText.isEmpty || _totalDuration == Duration.zero) return;
    final safeTarget = _clampDuration(target, _totalDuration);

    setState(() {
      _syncPositionState(safeTarget);
    });

    await _audioPlayer.seek(safeTarget);
  }

  Future<void> _cycleSpeed() async {
    final currentIndex = _speedSteps.indexOf(_speedX);
    final nextIndex = (currentIndex + 1) % _speedSteps.length;
    final next = _speedSteps[nextIndex];

    setState(() {
      _speedX = next;
    });

    try {
      await _audioPlayer.setSpeed(_speedX);
    } catch (_) {}
  }

  _SpeakableMarkdown _extractSpeakableFromMarkdown(String markdown) {
    final output = StringBuffer();
    final plainToRaw = <int>[];
    var i = 0;
    var lastWasSpace = true;

    bool isMarkdownToken(String ch) {
      return '#*_`~[]()!>|'.contains(ch);
    }

    while (i < markdown.length) {
      final ch = markdown[i];

      if (ch == '<') {
        final close = markdown.indexOf('>', i + 1);
        if (close != -1) {
          i = close + 1;
          continue;
        }
      }

      if (isMarkdownToken(ch)) {
        i++;
        continue;
      }

      final isSpace = ch.trim().isEmpty;
      if (isSpace) {
        if (!lastWasSpace && output.isNotEmpty) {
          output.write(' ');
          plainToRaw.add(i);
        }
        lastWasSpace = true;
        i++;
        continue;
      }

      output.write(ch);
      plainToRaw.add(i);
      lastWasSpace = false;
      i++;
    }

    final text = output.toString();
    var start = 0;
    while (start < text.length && text[start] == ' ') {
      start++;
    }

    var end = text.length;
    while (end > start && text[end - 1] == ' ') {
      end--;
    }

    return _SpeakableMarkdown(
      text: text.substring(start, end),
      plainToRaw: plainToRaw.sublist(start, end),
    );
  }

  Widget _buildHighlightedText({
    required String text,
    required int segmentStart,
    required TextStyle style,
    TextAlign textAlign = TextAlign.right,
  }) {
    if (text.isEmpty || segmentStart < 0 || !_playerVisible) {
      return Text(text, style: style, textAlign: textAlign);
    }

    final segmentEnd = segmentStart + text.length;
    final hasHighlight =
        _highlightStart >= 0 &&
        _highlightEnd > _highlightStart &&
        _highlightEnd > segmentStart &&
        _highlightStart < segmentEnd;

    if (!hasHighlight) {
      return Text(text, style: style, textAlign: textAlign);
    }

    final localStart = math.max(0, _highlightStart - segmentStart);
    final localEnd = math.min(text.length, _highlightEnd - segmentStart);

    if (localStart >= localEnd) {
      return Text(text, style: style, textAlign: textAlign);
    }

    return Text.rich(
      TextSpan(
        style: style,
        children: [
          if (localStart > 0) TextSpan(text: text.substring(0, localStart)),
          TextSpan(
            text: text.substring(localStart, localEnd),
            style: style.copyWith(backgroundColor: const Color(0xFFE9D0FF)),
          ),
          if (localEnd < text.length) TextSpan(text: text.substring(localEnd)),
        ],
      ),
      textAlign: textAlign,
    );
  }

  Widget _buildBottomPlayer() {
    return TtsAudioControlBar(
      visible: _playerVisible,
      isPlaying: _isSpeaking,
      isPreparing: _isPreparingAudio,
      position: _currentPosition,
      buffered: _bufferedPosition,
      total: _totalDuration,
      speed: _speedX,
      onPlayPause: _toggleSpeak,
      onForward: () => _seekBySeconds(10),
      onBackward: () => _seekBySeconds(-10),
      onCycleSpeed: _cycleSpeed,
      onClose: () => _stopSpeaking(hidePlayer: true, resetProgress: true),
      onSeek: _seekTo,
    );
  }

  String _buildHighlightedMarkdownContent(String markdown) {
    if (!_playerVisible ||
        _contentStart < 0 ||
        _plainContent.isEmpty ||
        _contentPlainToRaw.isEmpty ||
        _highlightStart < 0 ||
        _highlightEnd <= _highlightStart) {
      return markdown;
    }

    final contentGlobalStart = _contentStart;
    final contentGlobalEnd = _contentStart + _plainContent.length;

    final overlapStart = math.max(contentGlobalStart, _highlightStart);
    final overlapEnd = math.min(contentGlobalEnd, _highlightEnd);
    if (overlapEnd <= overlapStart) return markdown;

    final localStart = overlapStart - contentGlobalStart;
    final localEndExclusive = overlapEnd - contentGlobalStart;

    if (localStart < 0 || localStart >= _contentPlainToRaw.length) {
      return markdown;
    }

    final safeLocalEnd = math.max(
      localStart + 1,
      math.min(localEndExclusive, _contentPlainToRaw.length),
    );

    final rawStart = _contentPlainToRaw[localStart];
    final rawEnd = _contentPlainToRaw[safeLocalEnd - 1] + 1;

    if (rawStart < 0 || rawEnd <= rawStart || rawEnd > markdown.length) {
      return markdown;
    }

    return '${markdown.substring(0, rawStart)}<tts-hl>'
        '${markdown.substring(rawStart, rawEnd)}</tts-hl>'
        '${markdown.substring(rawEnd)}';
  }

  Widget _buildContentBody() {
    final highlightedMarkdown = _buildHighlightedMarkdownContent(
      widget.markdownContent,
    );
    return AppMarkdownBody(
      content: highlightedMarkdown,
      enableTtsHighlight: _playerVisible,
    );
  }

  Widget _buildListenButton() {
    return ElevatedButton(
      onPressed: _toggleSpeak,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
      ),
      child: Row(
        children: [
          Icon(_isSpeaking ? Icons.pause : Icons.volume_up, size: 18),
          const SizedBox(width: 4),
          const Text('الاستماع'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = ListenRenderScope(
      isSpeaking: _isSpeaking,
      playerVisible: _playerVisible,
      playerExpanded: true,
      extraBottomPadding: _playerVisible ? 250.0 : 0,
      listenButton: _buildListenButton(),
      bottomPlayer: _buildBottomPlayer(),
      markdownBody: _buildContentBody(),
      hasShortDescription: (widget.shortDescription ?? '').trim().isNotEmpty,
      buildHighlightedTitle: (style, {textAlign = TextAlign.right}) =>
          _buildHighlightedText(
            text: widget.title,
            segmentStart: _titleStart,
            style: style,
            textAlign: textAlign,
          ),
      buildHighlightedShortDescription:
          (style, {textAlign = TextAlign.right}) => _buildHighlightedText(
            text: widget.shortDescription ?? '',
            segmentStart: _shortStart,
            style: style,
            textAlign: textAlign,
          ),
      toggleSpeak: _toggleSpeak,
    );

    return widget.builder(context, scope);
  }
}

class _SpeakableMarkdown {
  final String text;
  final List<int> plainToRaw;

  const _SpeakableMarkdown({required this.text, required this.plainToRaw});
}
