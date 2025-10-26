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
      appBar: AppBar(
        title: const Text('Theos Logos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(manifestNotifierProvider.notifier).syncManifest();
            },
          ),
        ],
      ),
      body: tracksAsync.when(
        data: (tracks) {
          if (tracks.isEmpty) {
            return const Center(
              child: Text('No tracks available'),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: tracks.length,
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    final isPlaying = audioState.currentIndex == index;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isPlaying ? Colors.blue : Colors.grey,
                        child: isPlaying
                            ? const Icon(Icons.play_arrow, color: Colors.white)
                            : Text('${index + 1}'),
                      ),
                      title: Text(
                        track.title,
                        style: TextStyle(
                          fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          if (track.isDownloaded)
                            const Icon(Icons.download_done, size: 16, color: Colors.green)
                          else
                            const Icon(Icons.cloud_download, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(track.isDownloaded ? 'Downloaded' : 'Streaming'),
                        ],
                      ),
                      trailing: track.isDownloaded
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.download),
                              onPressed: () {
                                ref
                                    .read(manifestNotifierProvider.notifier)
                                    .downloadTrack(track.id);
                              },
                            ),
                      onTap: () {
                        ref
                            .read(audioPlayerNotifierProvider.notifier)
                            .playTrack(track, index);
                      },
                    );
                  },
                ),
              ),
              if (audioState.currentTrack != null)
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
