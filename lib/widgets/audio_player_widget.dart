import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_provider.dart';

class AudioPlayerWidget extends ConsumerWidget {
  const AudioPlayerWidget({super.key});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioPlayerNotifierProvider);
    final track = audioState.currentTrack;

    if (track == null) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              trackHeight: 2,
            ),
            child: Slider(
              value: audioState.position.inSeconds.toDouble(),
              max: audioState.duration.inSeconds.toDouble().clamp(1.0, double.infinity),
              onChanged: (value) {
                ref
                    .read(audioPlayerNotifierProvider.notifier)
                    .seek(Duration(seconds: value.toInt()));
              },
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(audioState.position),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  _formatDuration(audioState.duration),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          
          // Player controls
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  track.title,
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10),
                      iconSize: 32,
                      onPressed: () {
                        final newPosition = audioState.position - const Duration(seconds: 10);
                        ref
                            .read(audioPlayerNotifierProvider.notifier)
                            .seek(newPosition < Duration.zero ? Duration.zero : newPosition);
                      },
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(
                        audioState.isPlaying ? Icons.pause_circle : Icons.play_circle,
                        size: 64,
                      ),
                      onPressed: () {
                        if (audioState.isPlaying) {
                          ref.read(audioPlayerNotifierProvider.notifier).pause();
                        } else {
                          ref.read(audioPlayerNotifierProvider.notifier).resume();
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.forward_10),
                      iconSize: 32,
                      onPressed: () {
                        final newPosition = audioState.position + const Duration(seconds: 10);
                        ref
                            .read(audioPlayerNotifierProvider.notifier)
                            .seek(newPosition > audioState.duration 
                                ? audioState.duration 
                                : newPosition);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
