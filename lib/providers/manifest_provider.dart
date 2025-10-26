import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toml/toml.dart';
import '../models/audio_track.dart';

const String manifestUrl = 'https://theos-logos.pl/manifest.toml';
const String lastSyncKey = 'last_sync_timestamp';
const String tracksKey = 'cached_tracks';

class ManifestNotifier extends AsyncNotifier<List<AudioTrack>> {
  @override
  Future<List<AudioTrack>> build() async {
    return await _loadCachedTracks();
  }

  Future<List<AudioTrack>> _loadCachedTracks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(tracksKey);

      if (cachedData != null) {
        final List<dynamic> jsonList = json.decode(cachedData);
        final tracks =
            jsonList.map((json) => AudioTrack.fromJson(json)).toList();
        tracks.sort((a, b) => a.order.compareTo(b.order));
        return tracks;
      }

      return [];
    } catch (e) {
      print('Error loading cached tracks: $e');
      return [];
    }
  }

  Future<void> syncManifest() async {
    state = const AsyncValue.loading();

    try {
      // Fetch manifest
      final response = await http.get(
        Uri.parse(manifestUrl),
        headers: {'Accept-Charset': 'utf-8'},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch manifest: ${response.statusCode}');
      }

      // Parse TOML
      final bodyText = utf8.decode(response.bodyBytes);
      final manifest = TomlDocument.parse(bodyText).toMap();
      final List<dynamic> files = manifest['files'] ?? [];

      // Get current tracks
      final currentTracks = state.value ?? [];
      final currentIds = currentTracks.map((t) => t.id).toSet();

      // Parse new tracks
      final newTracks = <AudioTrack>[];
      final allTracks = <AudioTrack>[];

      for (int i = 0; i < files.length; i++) {
        final file = files[i] as Map<String, dynamic>;
        final track = AudioTrack(
          id: file['id'] as String,
          title: file['title'] as String,
          fileName: file['file_name'] as String,
          url: file['url'] as String,
          order: i,
          dateAdded: file['date_added'] != null
              ? DateTime.parse(file['date_added'] as String)
              : null,
        );

        // Check if this is a new track
        if (!currentIds.contains(track.id)) {
          newTracks.add(track);
        }

        // Check if we have this file downloaded already
        final existingTrack = currentTracks.firstWhere(
          (t) => t.id == track.id,
          orElse: () => track,
        );

        allTracks.add(track.copyWith(
          isDownloaded: existingTrack.isDownloaded,
          localPath: existingTrack.localPath,
          isListened: existingTrack.isListened,
        ));
      }

      // Sort by order
      allTracks.sort((a, b) => a.order.compareTo(b.order));

      // Cache tracks
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        tracksKey,
        json.encode(allTracks.map((t) => t.toJson()).toList()),
      );
      await prefs.setInt(lastSyncKey, DateTime.now().millisecondsSinceEpoch);

      // If there are new tracks, store them separately
      if (newTracks.isNotEmpty) {
        await prefs.setString(
          'new_tracks',
          json.encode(newTracks.map((t) => t.toJson()).toList()),
        );
      }

      state = AsyncValue.data(allTracks);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> downloadTrack(String trackId) async {
    final tracks = state.value;
    if (tracks == null) return;

    final trackIndex = tracks.indexWhere((t) => t.id == trackId);
    if (trackIndex == -1) return;

    final track = tracks[trackIndex];

    try {
      // Download file
      final response = await http.get(Uri.parse(track.url));

      if (response.statusCode != 200) {
        throw Exception('Failed to download file: ${response.statusCode}');
      }

      // Save to local storage
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/${track.fileName}';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      // Update track
      final updatedTrack = track.copyWith(
        isDownloaded: true,
        localPath: filePath,
      );

      final updatedTracks = List<AudioTrack>.from(tracks);
      updatedTracks[trackIndex] = updatedTrack;

      // Cache updated tracks
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        tracksKey,
        json.encode(updatedTracks.map((t) => t.toJson()).toList()),
      );

      state = AsyncValue.data(updatedTracks);
    } catch (e, stack) {
      print('Error downloading track: $e');
      // Don't update state with error, just log it
    }
  }

  Future<List<AudioTrack>> getNewTracks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final newTracksData = prefs.getString('new_tracks');

      if (newTracksData != null) {
        final List<dynamic> jsonList = json.decode(newTracksData);
        return jsonList.map((json) => AudioTrack.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      print('Error getting new tracks: $e');
      return [];
    }
  }

  Future<void> clearNewTracks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('new_tracks');
  }

  Future<void> markAsListened(String trackId) async {
    final tracks = state.value;
    if (tracks == null) return;

    final trackIndex = tracks.indexWhere((t) => t.id == trackId);
    if (trackIndex == -1) return;

    final updatedTrack = tracks[trackIndex].copyWith(isListened: true);
    final updatedTracks = List<AudioTrack>.from(tracks);
    updatedTracks[trackIndex] = updatedTrack;

    // Cache updated tracks
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      tracksKey,
      json.encode(updatedTracks.map((t) => t.toJson()).toList()),
    );

    state = AsyncValue.data(updatedTracks);
  }
}

// Provider declaration
final manifestNotifierProvider =
    AsyncNotifierProvider<ManifestNotifier, List<AudioTrack>>(() {
  return ManifestNotifier();
});
