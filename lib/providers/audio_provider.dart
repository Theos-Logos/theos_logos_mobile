import 'package:just_audio/just_audio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/audio_track.dart';
import 'manifest_provider.dart';

class AudioPlayerNotifier extends Notifier<AudioPlayerState> {
  AudioPlayer? _player;
  AudioTrack? _currentTrack;
  int? _currentIndex;
  String? _lastCompletedTrackId;
  bool _isTransitioning = false;
  DateTime? _trackStartTime;

  @override
  AudioPlayerState build() {
    // Initialize player
    _player = AudioPlayer();

    // Set up stream listeners once
    _setupStreamListeners();

    // Dispose the audio player when the provider is disposed
    ref.onDispose(() {
      _player?.dispose();
    });

    _loadLastPlayedPosition();
    return AudioPlayerState(
      isPlaying: false,
      currentTrack: null,
      position: Duration.zero,
      duration: Duration.zero,
      currentIndex: null,
    );
  }

  void _setupStreamListeners() {
    // Listen to player state
    _player!.playingStream.listen((playing) {
      state = state.copyWith(isPlaying: playing);
    });

    _player!.positionStream.listen((position) {
      state = state.copyWith(position: position);
      if (_currentTrack != null) {
        _savePosition(_currentTrack!.id, position);
      }
    });

    _player!.durationStream.listen((duration) {
      if (duration != null) {
        state = state.copyWith(duration: duration);
      }
    });

    // Listen to player completion
    _player!.playerStateStream.listen((playerState) {
      if (playerState.processingState == ProcessingState.completed) {
        // Ignore completion events during track transitions
        if (_isTransitioning) return;

        // Only handle completion if we have a track and haven't already handled it
        if (_currentTrack != null &&
            _lastCompletedTrackId != _currentTrack!.id &&
            state.duration.inSeconds > 0) {

          // Check that the track has been playing for at least 3 seconds
          // This prevents false completions on track start
          if (_trackStartTime != null) {
            final playDuration = DateTime.now().difference(_trackStartTime!);
            if (playDuration.inSeconds < 3) {
              return; // Track just started, ignore completion
            }
          }

          final position = state.position.inSeconds;
          final duration = state.duration.inSeconds;
          // Check if we're within 3 seconds of the end AND position is not 0
          // (natural completion means we're near the end, not at the beginning)
          if (position > 0 && duration - position < 3) {
            _onTrackCompleted();
          }
        }
      }
    });
  }

  Future<void> _loadLastPlayedPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastTrackId = prefs.getString('last_track_id');
      final lastPosition = prefs.getInt('last_position') ?? 0;

      if (lastTrackId != null) {
        // We'll restore this when the track is loaded
        print(
            'Last played: $lastTrackId at ${Duration(milliseconds: lastPosition)}');
      }
    } catch (e) {
      print('Error loading last played position: $e');
    }
  }

  Future<void> playTrack(AudioTrack track, int index,
      {Duration? startPosition}) async {
    try {
      // Mark that we're transitioning to prevent completion events
      _isTransitioning = true;

      _currentTrack = track;
      _currentIndex = index;

      // Stop and reset player if needed
      if (_player!.playing) {
        await _player!.stop();
      }

      // Update state immediately to show the track in UI
      state = state.copyWith(
        currentTrack: track,
        currentIndex: index,
        position: Duration.zero,
        duration: Duration.zero,
      );

      // Use local path if downloaded, otherwise stream from URL
      final audioSource = track.isDownloaded && track.localPath != null
          ? AudioSource.file(track.localPath!)
          : AudioSource.uri(Uri.parse(track.url));

      await _player!.setAudioSource(audioSource);

      // Restore position if provided or load saved position
      if (startPosition != null) {
        await _player!.seek(startPosition);
      } else {
        final prefs = await SharedPreferences.getInstance();
        final savedPosition = prefs.getInt('last_position_${track.id}');
        if (savedPosition != null && savedPosition > 0) {
          await _player!.seek(Duration(milliseconds: savedPosition));
        }
      }

      await _player!.play();

      // Mark when the track started playing
      _trackStartTime = DateTime.now();

      // Reset completion tracking AFTER the track has started playing
      // This prevents completion events during track transition from affecting the new track
      _lastCompletedTrackId = null;

      // End transition state after a short delay to ensure everything is settled
      Future.delayed(const Duration(milliseconds: 500), () {
        _isTransitioning = false;
      });

      // The isPlaying state will be updated by the stream listener
    } catch (e) {
      print('Error playing track: $e');
      // Reset transition state on error
      _isTransitioning = false;
      // Reset state on error
      state = state.copyWith(
        isPlaying: false,
      );
    }
  }

  Future<void> pause() async {
    await _player!.pause();
    if (_currentTrack != null) {
      await _savePosition(_currentTrack!.id, _player!.position);
    }
  }

  Future<void> resume() async {
    await _player!.play();
  }

  Future<void> seek(Duration position) async {
    // Clamp position to valid range (0 to duration - 1 second)
    var clampedPosition = position;
    if (state.duration.inSeconds > 0) {
      final maxPosition = state.duration - const Duration(seconds: 1);
      clampedPosition = Duration(
        milliseconds: position.inMilliseconds.clamp(0, maxPosition.inMilliseconds),
      );
    }

    await _player!.seek(clampedPosition);
    if (_currentTrack != null) {
      await _savePosition(_currentTrack!.id, clampedPosition);
    }
  }

  Future<void> stop() async {
    await _player!.stop();
    state = state.copyWith(
      isPlaying: false,
      position: Duration.zero,
    );
  }

  Future<void> _savePosition(String trackId, Duration position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_track_id', trackId);
      await prefs.setInt('last_position', position.inMilliseconds);
      await prefs.setInt('last_position_$trackId', position.inMilliseconds);
    } catch (e) {
      print('Error saving position: $e');
    }
  }

  Future<void> _onTrackCompleted() async {
    if (_currentTrack == null || _currentIndex == null) return;

    // Already transitioning? Don't trigger completion again
    if (_isTransitioning) return;

    // Store the track ID that just completed BEFORE doing anything else
    final completedTrackId = _currentTrack!.id;

    // Prevent marking the same track multiple times
    if (_lastCompletedTrackId == completedTrackId) return;
    _lastCompletedTrackId = completedTrackId;

    // Get all tracks to find the next one
    final tracks = ref.read(manifestNotifierProvider).value;
    if (tracks == null || tracks.isEmpty) return;

    // Mark the completed track as listened (do this AFTER getting next track but BEFORE playing)
    await ref.read(manifestNotifierProvider.notifier).markAsListened(completedTrackId);

    // Play next track if available
    final nextIndex = _currentIndex! + 1;
    if (nextIndex < tracks.length) {
      final nextTrack = tracks[nextIndex];
      // playTrack will set _isTransitioning = true
      await playTrack(nextTrack, nextIndex, startPosition: Duration.zero);
    } else {
      // No more tracks, stop playing
      state = state.copyWith(isPlaying: false);
    }
  }

  Future<Map<String, dynamic>?> getLastPlayedInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastTrackId = prefs.getString('last_track_id');
      final lastPosition = prefs.getInt('last_position');

      if (lastTrackId != null && lastPosition != null) {
        return {
          'trackId': lastTrackId,
          'position': Duration(milliseconds: lastPosition),
        };
      }
    } catch (e) {
      print('Error getting last played info: $e');
    }
    return null;
  }
}

class AudioPlayerState {
  final bool isPlaying;
  final AudioTrack? currentTrack;
  final Duration position;
  final Duration duration;
  final int? currentIndex;

  AudioPlayerState({
    required this.isPlaying,
    required this.currentTrack,
    required this.position,
    required this.duration,
    required this.currentIndex,
  });

  AudioPlayerState copyWith({
    bool? isPlaying,
    AudioTrack? currentTrack,
    Duration? position,
    Duration? duration,
    int? currentIndex,
  }) {
    return AudioPlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      currentTrack: currentTrack ?? this.currentTrack,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

// Provider declaration
final audioPlayerNotifierProvider =
    NotifierProvider<AudioPlayerNotifier, AudioPlayerState>(() {
  return AudioPlayerNotifier();
});
