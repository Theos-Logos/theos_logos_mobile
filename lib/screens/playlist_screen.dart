import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/audio_track.dart';
import '../providers/manifest_provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/audio_player_widget.dart';

class PlaylistScreen extends ConsumerStatefulWidget {
  const PlaylistScreen({super.key});

  @override
  ConsumerState<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends ConsumerState<PlaylistScreen> {
  @override
  void initState() {
    super.initState();
    // Sync manifest on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(manifestNotifierProvider.notifier).syncManifest();
      _checkForNewTracks();
    });
  }

  Future<void> _checkForNewTracks() async {
    final newTracks = await ref.read(manifestNotifierProvider.notifier).getNewTracks();
    
    if (newTracks.isNotEmpty && mounted) {
      _showWhatsNewDialog(newTracks);
    }
  }

  void _showWhatsNewDialog(List<AudioTrack> newTracks) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('What\'s New'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: newTracks.length,
            itemBuilder: (context, index) {
              final track = newTracks[index];
              return ListTile(
                leading: const Icon(Icons.new_releases, color: Colors.orange),
                title: Text(track.title),
                subtitle: track.dateAdded != null
                    ? Text('Added: ${_formatDate(track.dateAdded!)}')
                    : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(manifestNotifierProvider.notifier).clearNewTracks();
              Navigator.of(context).pop();
            },
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final tracksAsync = ref.watch(manifestNotifierProvider);
    final audioState = ref.watch(audioPlayerNotifierProvider);

    return Scaffold(
      body: tracksAsync.when(
        data: (tracks) {
          if (tracks.isEmpty) {
            return const Center(
              child: Text('No tracks available'),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: tracks.length + 1, // +1 for the header
                  itemBuilder: (context, index) {
                    // First item is the header
                    if (index == 0) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Text(
                          'Theos Logos',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }

                    final trackIndex = index - 1;
                    final track = tracks[trackIndex];
                    final isPlaying = audioState.currentIndex == trackIndex;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2a2a2a),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InkWell(
                        onTap: () {
                          ref
                              .read(audioPlayerNotifierProvider.notifier)
                              .playTrack(track, trackIndex, startPosition: Duration.zero);
                        },
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              child: track.isListened
                                  ? const Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: Colors.green,
                                    )
                                  : Text(
                                      '${trackIndex + 1}',
                                      style: TextStyle(
                                        color: isPlaying ? const Color(0xFFFFB300) : Colors.grey,
                                        fontSize: 14,
                                        fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    track.title,
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14,
                                      fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        track.isDownloaded ? Icons.download_done : Icons.cloud_download,
                                        size: 14,
                                        color: track.isDownloaded ? Colors.green : Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        track.isDownloaded ? 'Downloaded' : 'Streaming',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (!track.isDownloaded)
                              IconButton(
                                icon: const Icon(Icons.download, color: Colors.white, size: 20),
                                onPressed: () {
                                  ref
                                      .read(manifestNotifierProvider.notifier)
                                      .downloadTrack(track.id);
                                },
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const AudioPlayerWidget(),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(manifestNotifierProvider.notifier).syncManifest();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
