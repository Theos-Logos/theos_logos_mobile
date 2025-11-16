import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_provider.dart';

class AudioPlayerWidget extends ConsumerWidget {
  const AudioPlayerWidget({super.key});

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioPlayerNotifierProvider);
    final track = audioState.currentTrack;

    if (track == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2a2a2a),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Nie wybrano nagrania',
                    style: TextStyle(color: Color(0xFFB0B0B0), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.play_arrow, color: Colors.grey),
              onPressed: null,
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.grey),
              onPressed: null,
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2a2a2a),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      void handleSeek(double localX) {
                        if (audioState.duration.inSeconds > 0) {
                          final clampedX = localX.clamp(0.0, constraints.maxWidth);
                          final percentage = (clampedX / constraints.maxWidth).clamp(0.0, 1.0);
                          var newPosition = audioState.duration * percentage;

                          // Ensure we don't seek beyond the duration (leave 1 second buffer)
                          if (newPosition >= audioState.duration) {
                            newPosition = audioState.duration - const Duration(seconds: 1);
                          }

                          ref.read(audioPlayerNotifierProvider.notifier).seek(newPosition);
                        }
                      }

                      return Semantics(
                        label: 'Pasek postępu odtwarzania',
                        value: '${audioState.duration.inSeconds > 0 ? (audioState.position.inSeconds / audioState.duration.inSeconds * 100).round() : 0}%',
                        slider: true,
                        child: GestureDetector(
                          onTapDown: (details) {
                            handleSeek(details.localPosition.dx);
                          },
                          onHorizontalDragStart: (details) {
                            handleSeek(details.localPosition.dx);
                          },
                          onHorizontalDragUpdate: (details) {
                            handleSeek(details.localPosition.dx);
                          },
                          child: SizedBox(
                          height: 48,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.centerLeft,
                            children: [
                              Positioned.fill(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[800],
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: audioState.duration.inSeconds > 0
                                        ? (audioState.position.inSeconds / audioState.duration.inSeconds).clamp(0.0, 1.0)
                                        : 0.0,
                                    child: Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFB300),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: audioState.duration.inSeconds > 0
                                    ? (constraints.maxWidth * (audioState.position.inSeconds / audioState.duration.inSeconds).clamp(0.0, 1.0) - 10)
                                    : -10,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFB300),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_formatDuration(audioState.position)} / ${_formatDuration(audioState.duration)}',
                  style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Semantics(
            label: audioState.isPlaying ? 'Pauza' : 'Odtwórz',
            button: true,
            child: IconButton(
              icon: Icon(
                audioState.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
              ),
              onPressed: () {
                if (audioState.isPlaying) {
                  ref.read(audioPlayerNotifierProvider.notifier).pause();
                } else {
                  ref.read(audioPlayerNotifierProvider.notifier).resume();
                }
              },
            ),
          ),
          Semantics(
            label: 'Przewiń do początku',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                ref.read(audioPlayerNotifierProvider.notifier).seek(Duration.zero);
              },
            ),
          ),
        ],
      ),
    );
  }
}
