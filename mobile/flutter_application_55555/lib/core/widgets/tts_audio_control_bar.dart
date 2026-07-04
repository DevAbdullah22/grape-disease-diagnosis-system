import 'dart:math' as math;

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';

class TtsAudioControlBar extends StatelessWidget {
  final bool visible;
  final bool isPlaying;
  final bool isPreparing;
  final Duration position;
  final Duration buffered;
  final Duration total;
  final double speed;
  final VoidCallback onPlayPause;
  final VoidCallback onForward;
  final VoidCallback onBackward;
  final VoidCallback onCycleSpeed;
  final VoidCallback onClose;
  final ValueChanged<Duration> onSeek;

  const TtsAudioControlBar({
    super.key,
    required this.visible,
    required this.isPlaying,
    required this.isPreparing,
    required this.position,
    required this.buffered,
    required this.total,
    required this.speed,
    required this.onPlayPause,
    required this.onForward,
    required this.onBackward,
    required this.onCycleSpeed,
    required this.onClose,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    final safeTotal = total > Duration.zero
        ? total
        : const Duration(milliseconds: 1);
    final safePosition = _clampDuration(position, safeTotal);
    final safeBuffered = _clampDuration(buffered, safeTotal);

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 360;
            final horizontalPadding = isCompact ? 6.0 : 8.0;
            final verticalPadding = isCompact ? 4.0 : 6.0;
            final sideIconSize = isCompact ? 26.0 : 28.0;
            final speedFontSize = isCompact ? 17.0 : 19.0;
            final playRadius = isCompact ? 22.0 : 24.0;
            final playIconSize = isCompact ? 28.0 : 30.0;
            final cardWidth = math.min(constraints.maxWidth - 20, 360.0);

            return Container(
              width: cardWidth,
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                verticalPadding,
                horizontalPadding,
                verticalPadding,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F4),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(
                    height: 8,
                    thickness: 1,
                    color: Color(0xFFE3E7EA),
                  ),
                  ProgressBar(
                    progress: safePosition,
                    buffered: safeBuffered,
                    total: safeTotal,
                    onSeek: total > Duration.zero ? onSeek : null,
                    timeLabelPadding: 4,
                    baseBarColor: const Color(0xFFC8D0D8),
                    bufferedBarColor: const Color(0xFF8AA8D8),
                    progressBarColor: const Color(0xFF1565D8),
                    thumbColor: const Color(0xFF1565D8),
                    thumbRadius: 7,
                    barHeight: 3,
                    timeLabelTextStyle: TextStyle(
                      fontSize: isCompact ? 13 : 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: IconButton(
                            onPressed: onBackward,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                              width: 32,
                              height: 32,
                            ),
                            splashRadius: 18,
                            icon: Icon(Icons.replay_10, size: sideIconSize),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: GestureDetector(
                            onTap: isPreparing ? null : onPlayPause,
                            child: CircleAvatar(
                              radius: playRadius,
                              backgroundColor: const Color(0xFF1565D8),
                              child: isPreparing
                                  ? SizedBox(
                                      width: playIconSize - 4,
                                      height: playIconSize - 4,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Icon(
                                      isPlaying
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                      size: playIconSize,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: IconButton(
                            onPressed: onForward,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints.tightFor(
                              width: 32,
                              height: 32,
                            ),
                            splashRadius: 21,
                            icon: Icon(Icons.forward_10, size: sideIconSize),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: TextButton(
                            onPressed: onCycleSpeed,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${speed.toStringAsFixed(1)}x',
                                style: TextStyle(
                                  fontSize: speedFontSize,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Center(
                        child: IconButton(
                          onPressed: onClose,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(
                            width: 36,
                            height: 36,
                          ),
                          splashRadius: 18,
                          icon: const Icon(Icons.close, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Duration _clampDuration(Duration value, Duration max) {
    if (max <= Duration.zero) return Duration.zero;
    final clamped = math.max(
      0,
      math.min(value.inMilliseconds, max.inMilliseconds),
    );
    return Duration(milliseconds: clamped);
  }
}
