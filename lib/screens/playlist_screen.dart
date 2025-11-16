import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    final newTracks =
        await ref.read(manifestNotifierProvider.notifier).getNewTracks();

    if (newTracks.isNotEmpty && mounted) {
      _showWhatsNewDialog(newTracks);
    }
  }

  void _showWhatsNewDialog(List<AudioTrack> newTracks) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Co nowego?'),
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
                    ? Text('Dodano: ${_formatDate(track.dateAdded!)}')
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
            child: const Text('OK'),
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
      body: SafeArea(
        child: tracksAsync.when(
          data: (tracks) {
            if (tracks.isEmpty) {
              return const Center(
                child: Text('Brak dostępnych nagrań'),
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
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Row(
                            children: [
                              Image.network(
                                'https://theos-logos.pl/logoTXT.png',
                                height: 40,
                                errorBuilder: (context, error, stackTrace) {
                                  return const SizedBox(height: 40, width: 40);
                                },
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Theos - Logos',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.refresh,
                                    color: Colors.white70),
                                tooltip: 'Wyczyść odsłuchane',
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Wyczyść odsłuchane'),
                                      content: const Text(
                                          'Czy na pewno chcesz wyczyścić status wszystkich odsłuchanych nagrań?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: const Text('Anuluj'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            ref
                                                .read(manifestNotifierProvider
                                                    .notifier)
                                                .clearAllListened();
                                            Navigator.of(context).pop();
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Wyczyszczono status odsłuchanych nagrań'),
                                                duration: Duration(seconds: 2),
                                              ),
                                            );
                                          },
                                          child: const Text('Wyczyść'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.volunteer_activism,
                                    color: Color(0xFFFFB300)),
                                tooltip: 'Wspomóż',
                                onPressed: () {
                                  context.push('/support');
                                },
                              ),
                            ],
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
                        child: Semantics(
                          label:
                              'Odtwórz ${track.title}${track.isListened ? ', odsłuchane' : ''}',
                          button: true,
                          child: InkWell(
                            onTap: () {
                              ref
                                  .read(audioPlayerNotifierProvider.notifier)
                                  .playTrack(track, trackIndex,
                                      startPosition: Duration.zero);
                            },
                            borderRadius: BorderRadius.circular(8),
                            splashColor:
                                const Color(0xFFFFB300).withValues(alpha: 0.2),
                            highlightColor:
                                const Color(0xFFFFB300).withValues(alpha: 0.1),
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
                                            color: isPlaying
                                                ? const Color(0xFFFFB300)
                                                : const Color(0xFFB0B0B0),
                                            fontSize: 14,
                                            fontWeight: isPlaying
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  isPlaying && audioState.isPlaying
                                      ? Icons.pause_circle
                                      : Icons.play_circle,
                                  color: isPlaying
                                      ? const Color(0xFFFFB300)
                                      : Colors.grey[700],
                                  size: 28,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        track.title,
                                        style: TextStyle(
                                          color: Colors.grey[300],
                                          fontSize: 14,
                                          fontWeight: isPlaying
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (track.isDownloaded) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.download_done,
                                              size: 14,
                                              color: Colors.green,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Pobrane',
                                              style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (!track.isDownloaded)
                                  Semantics(
                                    label: 'Pobierz nagranie ${track.title}',
                                    button: true,
                                    child: IconButton(
                                      icon: const Icon(Icons.download,
                                          color: Colors.white, size: 24),
                                      onPressed: () {
                                        ref
                                            .read(manifestNotifierProvider
                                                .notifier)
                                            .downloadTrack(track.id);
                                      },
                                      padding: const EdgeInsets.all(12),
                                      constraints: const BoxConstraints(
                                          minWidth: 48, minHeight: 48),
                                      tooltip: 'Pobierz',
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
                  child: const Text('Spróbuj ponownie'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
