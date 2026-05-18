import 'dart:math' as math;

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';

import '../data/io_platform.dart';
import '../just_audio_import.dart';
import '../models/song.dart';

/// Wraps [AudioPlayer] — UI never touches this directly.
/// TODO: [Crossfade] / gapless — extend with transition policy + second player.
/// TODO: [Lyrics] sync — attach timed metadata stream alongside audio.
class AudioPlayerService {
  AudioPlayerService() : _player = AudioPlayer();

  final AudioPlayer _player;
  ConcatenatingAudioSource? _playlist;

  AudioPlayer get player => _player;

  Future<AudioSource?> _audioSourceForSong(Song s) async {
    final tag = _mediaTag(s);
    if (s.localAudioUri != null && s.localAudioUri!.trim().isNotEmpty) {
      final resolved = await resolvePlaybackUri(s.localAudioUri!.trim());
      return AudioSource.uri(
        Uri.parse(resolved),
        tag: tag,
      );
    }
    if (s.assetPath != null && s.assetPath!.isNotEmpty) {
      return AudioSource.asset(s.assetPath!, tag: tag);
    }
    if (s.streamingUrl != null && s.streamingUrl!.trim().isNotEmpty) {
      return AudioSource.uri(
        Uri.parse(s.streamingUrl!.trim()),
        tag: tag,
      );
    }
    return null;
  }

  Future<Duration?> loadQueue(
    List<Song> queue, {
    required int initialIndex,
  }) async {
    if (queue.isEmpty) return Duration.zero;
    final sources = <AudioSource>[];
    for (final s in queue) {
      final src = await _audioSourceForSong(s);
      if (src != null) {
        sources.add(src);
      }
    }
    if (sources.isEmpty) {
      throw StateError('No playable audio sources in queue');
    }
    final clampedIndex = initialIndex.clamp(0, sources.length - 1);
    _playlist = ConcatenatingAudioSource(children: sources);
    await _player.setAudioSource(
      _playlist!,
      initialIndex: clampedIndex,
    );
    return _player.duration;
  }

  /// Inserts [song] after the current item in the playlist (concat order).
  ///
  /// Returns `false` if [song] is not playable or there is no active playlist.
  Future<bool> addSongAfterCurrent(Song song) async {
    final source = await _audioSourceForSong(song);
    final playlist = _playlist;
    if (source == null || playlist == null) {
      return false;
    }
    final ci = _player.currentIndex ?? 0;
    final insertAt = math.min(ci + 1, playlist.children.length)
        .clamp(0, playlist.children.length);
    await playlist.insert(insertAt, source);
    return true;
  }

  Future<bool> addSongToEnd(Song song) async {
    final source = await _audioSourceForSong(song);
    final playlist = _playlist;
    if (source == null || playlist == null) {
      return false;
    }
    await playlist.add(source);
    return true;
  }

  Future<void> moveQueueItem(int currentIndex, int newIndex) async {
    final playlist = _playlist;
    if (playlist == null) return;
    final last = playlist.children.length - 1;
    if (currentIndex < 0 || currentIndex > last) return;
    final target = newIndex.clamp(0, last);
    if (target == currentIndex) return;
    await playlist.move(currentIndex, target);
  }

  Future<void> removeQueueItemAt(int index) async {
    final playlist = _playlist;
    if (playlist == null) return;
    if (index < 0 || index >= playlist.children.length) return;
    await playlist.removeAt(index);
  }

  Future<void> clearQueue() async {
    final playlist = _playlist;
    if (playlist == null) return;
    await playlist.clear();
    await _player.stop();
  }

  Future<void> play() => _player.play();

  Future<void> pause() => _player.pause();

  Future<void> seek(Duration position) => _player.seek(position);

  double get volume => _player.volume;

  Future<void> setVolume(double volume) =>
      _player.setVolume(volume.clamp(0.0, 1.0));

  Future<void> seekToNext() async {
    if (_player.hasNext) await _player.seekToNext();
  }

  Future<void> seekToPrevious() async {
    if (_player.hasPrevious) await _player.seekToPrevious();
  }

  Future<void> setShuffle(bool enabled) =>
      _player.setShuffleModeEnabled(enabled);

  Future<void> setLoopMode(LoopMode mode) => _player.setLoopMode(mode);

  Future<void> jumpToQueueIndex(int index) =>
      _player.seek(Duration.zero, index: index);

  Future<void> dispose() async {
    _playlist = null;
    await _player.dispose();
  }

  Object? _mediaTag(Song song) {
    if (kIsWeb) return null;
    Uri? artUri;
    final raw = song.artworkUrl?.trim();
    if (raw != null && raw.isNotEmpty) {
      final parsed = Uri.tryParse(raw);
      if (parsed != null && parsed.hasScheme) artUri = parsed;
    }
    // Use song's artwork URL only - no fallback to external services.
    // If artUri is null, the notification will show the app icon.
    return MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artistName.isNotEmpty ? song.artistName : null,
      album: song.albumTitle.isNotEmpty ? song.albumTitle : null,
      artUri: artUri,
      duration: song.duration,
    );
  }
}
