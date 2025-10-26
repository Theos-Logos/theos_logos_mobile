import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_provider.dart';

class AudioPlayerWidget extends ConsumerWidget {
  const AudioPlayerWidget({super.key});

  String _formatDuration(Duration duration) {
    return '${duration.inSeconds}s';
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
                    style: TextStyle(color: Colors.grey, fontSize: 12),
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      onTapDown: (details) {
                        if (audioState.duration.inSeconds > 0) {
                          final localPosition = details.localPosition.dx;
                          final width = constraints.maxWidth;
                          final percentage = (localPosition / width).clamp(0.0, 1.0);
                          final newPosition = audioState.duration * percentage;
                          ref.read(audioPlayerNotifierProvider.notifier).seek(newPosition);
                        }
                      },
                      child: Stack(
                        children: [
                          Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          FractionallySizedBox(
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
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  '${_formatDuration(audioState.position)} / ${_formatDuration(audioState.duration)}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
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
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.read(audioPlayerNotifierProvider.notifier).seek(Duration.zero);
            },
          ),
        ],
      ),
    );
  }
}
