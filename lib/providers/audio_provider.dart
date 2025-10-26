import 'package:just_audio/just_audio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/audio_track.dart';

class AudioPlayerNotifier extends Notifier<AudioPlayerState> {
  final AudioPlayer _player = AudioPlayer();
  AudioTrack? _currentTrack;
  int? _currentIndex;

  @override
  AudioPlayerState build() {
    // Dispose the audio player when the provider is disposed
    ref.onDispose(() {
      _player.dispose();
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
      _currentTrack = track;
      _currentIndex = index;

      // Use local path if downloaded, otherwise stream from URL
      final audioSource = track.isDownloaded && track.localPath != null
          ? AudioSource.file(track.localPath!)
          : AudioSource.uri(Uri.parse(track.url));

      await _player.setAudioSource(audioSource);

      // Restore position if provided or load saved position
      if (startPosition != null) {
        await _player.seek(startPosition);
      } else {
        final prefs = await SharedPreferences.getInstance();
        final savedPosition = prefs.getInt('last_position_${track.id}');
        if (savedPosition != null && savedPosition > 0) {
          await _player.seek(Duration(milliseconds: savedPosition));
        }
      }

      await _player.play();

      // Listen to player state
      _player.playingStream.listen((playing) {
        state = state.copyWith(isPlaying: playing);
      });

      _player.positionStream.listen((position) {
        state = state.copyWith(position: position);
        _savePosition(track.id, position);
      });

      _player.durationStream.listen((duration) {
        if (duration != null) {
          state = state.copyWith(duration: duration);
        }
      });

      state = state.copyWith(
        currentTrack: track,
        isPlaying: true,
        currentIndex: index,
      );
    } catch (e) {
      print('Error playing track: $e');
    }
  }

  Future<void> pause() async {
    await _player.pause();
    if (_currentTrack != null) {
      await _savePosition(_currentTrack!.id, _player.position);
    }
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
    if (_currentTrack != null) {
      await _savePosition(_currentTrack!.id, position);
    }
  }

  Future<void> stop() async {
    await _player.stop();
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
