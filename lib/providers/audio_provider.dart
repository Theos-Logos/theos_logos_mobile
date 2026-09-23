import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/audio_track.dart';
import 'book_filter_provider.dart';
import 'manifest_provider.dart';

class AudioPlayerNotifier extends Notifier<AudioPlayerState> {
  AudioPlayer? _player;
  AudioTrack? _currentTrack;
  int? _currentIndex;
  List<AudioTrack> _queue = [];
  bool _sessionReady = false;
  bool _loadingSource = false;
  bool _ignoreNextIndex = false;
  String? _lastListenedId;
  DateTime? _trackStartTime;

  @override
  AudioPlayerState build() {
    // Pixel 10 reports that it can offload MP3 and then plays silence.
    _player = AudioPlayer(
      androidAudioOffloadPreferences: const AndroidAudioOffloadPreferences(
        audioOffloadMode: AndroidAudioOffloadMode.disabled,
      ),
    );

    _setupStreamListeners();

    ref.onDispose(() {
      _player?.dispose();
    });

    return AudioPlayerState(
      isPlaying: false,
      currentTrack: null,
      position: Duration.zero,
      duration: Duration.zero,
      currentIndex: null,
      error: null,
    );
  }

  void _setupStreamListeners() {
    _player!.playingStream.listen((playing) {
      state = state.copyWith(isPlaying: playing);
    });

    _player!.positionStream.listen((position) {
      state = state.copyWith(position: position);
      if (_currentTrack != null && !_loadingSource) {
        _savePosition(_currentTrack!.id, position);
      }
    });

    _player!.durationStream.listen((duration) {
      if (duration != null) {
        state = state.copyWith(duration: duration);
      }
    });

    _player!.errorStream.listen((error) {
      state = state.copyWith(error: 'Nie udało się odtworzyć nagrania.');
      print('Audio error: $error');
    });

    // The player advances the playlist itself. This only updates the row
    // that is highlighted and marks the previous recording as heard.
    _player!.currentIndexStream.listen((index) {
      if (index == null || index < 0 || index >= _queue.length) return;
      final track = _queue[index];
      final previousId = _currentTrack?.id;
      final userChoseThis = _ignoreNextIndex;
      _ignoreNextIndex = false;
      _showTrack(track);
      if (!userChoseThis &&
          previousId != null &&
          previousId != track.id &&
          _lastListenedId != previousId) {
        _lastListenedId = previousId;
        ref.read(manifestNotifierProvider.notifier).markAsListened(previousId);
      }
    });

    _player!.playerStateStream.listen((playerState) {
      if (playerState.processingState != ProcessingState.completed) return;
      if (_loadingSource) return;
      final started = _trackStartTime;
      if (started != null &&
          DateTime.now().difference(started) < const Duration(seconds: 3)) {
        return;
      }
      final id = _currentTrack?.id;
      if (id != null && _lastListenedId != id) {
        _lastListenedId = id;
        ref.read(manifestNotifierProvider.notifier).markAsListened(id);
      }
      // End of the queue. playing stays true in just_audio, which looks like
      // a stuck pause button and yields no sound.
      if (_player!.playing) {
        _player!.pause();
      }
    });
  }

  Future<void> _ensureSession() async {
    if (_sessionReady) return;
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    _sessionReady = true;
  }

  AudioSource _sourceFor(AudioTrack track) {
    if (track.isDownloaded && track.localPath != null) {
      return AudioSource.file(track.localPath!, tag: track.id);
    }
    return AudioSource.uri(Uri.parse(track.url), tag: track.id);
  }

  void _showTrack(AudioTrack track) {
    final full = ref.read(manifestNotifierProvider).value ?? const <AudioTrack>[];
    final fullIndex = full.indexWhere((item) => item.id == track.id);
    _currentTrack = track;
    _currentIndex = fullIndex >= 0 ? fullIndex : _currentIndex;
    state = state.copyWith(
      currentTrack: track,
      currentIndex: _currentIndex,
      position: Duration.zero,
      clearError: true,
    );
  }

  Future<void> playTrack(AudioTrack track, int index,
      {Duration? startPosition}) async {
    try {
      await _ensureSession();
      _loadingSource = true;

      var queue = List<AudioTrack>.from(ref.read(filteredTracksProvider));
      if (!queue.any((item) => item.id == track.id)) {
        final full = ref.read(manifestNotifierProvider).value;
        queue = List<AudioTrack>.from(full ?? const <AudioTrack>[]);
      }
      var queueIndex = queue.indexWhere((item) => item.id == track.id);
      if (queueIndex < 0) {
        queue = [track];
        queueIndex = 0;
      }
      // From the tapped recording through the end of the list on screen.
      _queue = queue.sublist(queueIndex);
      _ignoreNextIndex = true;
      _currentTrack = track;
      _currentIndex = index;
      _trackStartTime = DateTime.now();
      state = state.copyWith(
        currentTrack: track,
        currentIndex: index,
        position: startPosition ?? Duration.zero,
        duration: Duration.zero,
        clearError: true,
      );

      if (_player!.playing) {
        await _player!.pause();
      }

      await _player!.setAudioSources(
        _queue.map(_sourceFor).toList(),
        initialIndex: 0,
        initialPosition: startPosition ?? Duration.zero,
      );

      _loadingSource = false;
      unawaited(_player!.play().then<void>((_) {}, onError: (Object error, StackTrace _) {
        state = state.copyWith(error: 'Nie udało się odtworzyć nagrania.');
        print('Error playing track: $error');
      }));
    } catch (error) {
      _loadingSource = false;
      _ignoreNextIndex = false;
      print('Error playing track: $error');
      state = state.copyWith(
        isPlaying: false,
        error: 'Nie udało się odtworzyć nagrania.',
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
    if (_player!.processingState == ProcessingState.completed) {
      await _player!.seek(Duration.zero);
    }
    unawaited(_player!.play());
  }

  Future<void> seek(Duration position) async {
    var clampedPosition = position;
    if (state.duration.inSeconds > 0) {
      final maxPosition = state.duration - const Duration(seconds: 1);
      clampedPosition = Duration(
        milliseconds:
            position.inMilliseconds.clamp(0, maxPosition.inMilliseconds),
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
  final String? error;

  AudioPlayerState({
    required this.isPlaying,
    required this.currentTrack,
    required this.position,
    required this.duration,
    required this.currentIndex,
    required this.error,
  });

  AudioPlayerState copyWith({
    bool? isPlaying,
    AudioTrack? currentTrack,
    Duration? position,
    Duration? duration,
    int? currentIndex,
    String? error,
    bool clearError = false,
  }) {
    return AudioPlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      currentTrack: currentTrack ?? this.currentTrack,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      currentIndex: currentIndex ?? this.currentIndex,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final audioPlayerNotifierProvider =
    NotifierProvider<AudioPlayerNotifier, AudioPlayerState>(() {
  return AudioPlayerNotifier();
});
