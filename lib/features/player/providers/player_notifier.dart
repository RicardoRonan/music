// Central playback orchestration. Riverpod keeps this testable (override
// [audioPlayerServiceProvider]) and composable without InheritedWidget noise.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../just_audio_import.dart' hide PlayerState;

import '../models/playback_state.dart';
import '../models/song.dart';
import '../services/audio_player_service.dart';
import 'album_artwork_notifier.dart';
import 'app_providers.dart';
import 'player_state.dart';
import 'preferences_notifier.dart';
import '../../playlists/providers/user_playlists_notifier.dart';

final playerNotifierProvider =
    NotifierProvider<PlayerNotifier, PlayerState>(PlayerNotifier.new);

class PlayerNotifier extends Notifier<PlayerState> {
  AudioPlayerService get _audio => ref.read(audioPlayerServiceProvider);
  final List<StreamSubscription<dynamic>> _subs = [];
  bool _streamsAttached = false;
  bool _hadActivePlayback = false;

  @override
  PlayerState build() {
    // Avoid updating [state] synchronously during [build] when streams replay.
    Future.microtask(_attachStreams);
    ref.listen<Map<String, String>>(albumArtworkProvider, (_, art) {
      _patchQueueAlbumArtwork(art);
    });
    ref.onDispose(_detachStreams);
    return PlayerState.empty;
  }

  void _patchQueueAlbumArtwork(Map<String, String> artByAlbumId) {
    if (state.queue.isEmpty || artByAlbumId.isEmpty) return;
    final next = <Song>[];
    var changed = false;
    for (final s in state.queue) {
      final u = artByAlbumId[s.albumId];
      if (u != null &&
          u.isNotEmpty &&
          (s.artworkUrl == null || s.artworkUrl != u)) {
        next.add(s.withArtworkUrl(u));
        changed = true;
      } else {
        next.add(s);
      }
    }
    if (!changed) return;
    state = state.copyWith(queue: next);
  }

  void _attachStreams() {
    if (_streamsAttached) return;
    _streamsAttached = true;
    final p = _audio.player;
    _subs
      ..add(
        p.playerStateStream.listen((ps) {
          final proc = mapProcessingState(ps.processingState);
          if (state.queue.isNotEmpty) {
            _hadActivePlayback = true;
          }
          state = state.copyWith(
            isPlaying: ps.playing,
            processingState: proc,
            clearError: proc == AppProcessingState.ready ||
                proc == AppProcessingState.buffering ||
                proc == AppProcessingState.completed,
          );
          if (!kIsWeb &&
              ps.processingState == ProcessingState.idle &&
              state.queue.isEmpty &&
              _hadActivePlayback) {
            _hadActivePlayback = false;
            SystemChannels.platform.invokeMethod('SystemNavigator.pop');
          }
        }),
      )
      ..add(
        p.positionStream.listen((pos) {
          state = state.copyWith(position: pos);
        }),
      )
      ..add(
        p.durationStream.listen((d) {
          state = state.copyWith(duration: d ?? Duration.zero);
          if (d == null || d <= const Duration(seconds: 2)) return;
          final cur = state.currentSong;
          if (cur == null ||
              cur.localAudioUri == null ||
              cur.localAudioUri!.trim().isEmpty) {
            return;
          }
          unawaited(_mergeResolvedLibraryDuration(cur.id, d));
        }),
      )
      ..add(
        p.currentIndexStream.listen((i) {
          if (i == null) return;
          state = state.copyWith(currentIndex: i);
        }),
      )
      ..add(
        p.shuffleModeEnabledStream.listen((v) {
          state = state.copyWith(shuffleEnabled: v);
        }),
      )
      ..add(
        p.loopModeStream.listen((m) {
          state = state.copyWith(loopMode: m);
        }),
      )
      ..add(
        p.volumeStream.listen((v) {
          state = state.copyWith(volume: v);
        }),
      );
    state = state.copyWith(volume: p.volume);
  }

  Future<void> _mergeResolvedLibraryDuration(String songId, Duration d) async {
    final patched = await ref
        .read(localLibraryProvider.notifier)
        .applyPlaybackResolvedDuration(songId, d);
    if (patched == null) return;
    state = state.copyWith(
      queue: [
        for (final s in state.queue) s.id == patched.id ? patched : s,
      ],
    );
  }

  void _detachStreams() {
    _streamsAttached = false;
    for (final s in _subs) {
      unawaited(s.cancel());
    }
    _subs.clear();
  }

  Future<void> playQueue(List<Song> songs, {required int startIndex}) async {
    if (songs.isEmpty) return;

    final playable = <Song>[];
    var mappedStart = 0;
    var pickedStart = false;
    final want = startIndex.clamp(0, songs.length - 1);
    for (var i = 0; i < songs.length; i++) {
      final s = songs[i];
      if (!s.hasPlayableSource) continue;
      if (!pickedStart && i >= want) {
        mappedStart = playable.length;
        pickedStart = true;
      }
      playable.add(s);
    }
    if (!pickedStart && playable.isNotEmpty) {
      mappedStart = 0;
    }

    if (playable.isEmpty) {
      state = state.copyWith(
        processingState: AppProcessingState.error,
        errorMessage: 'No playable audio for the selected tracks.',
      );
      return;
    }

    mappedStart = mappedStart.clamp(0, playable.length - 1);
    state = state.copyWith(
      processingState: AppProcessingState.loading,
      clearError: true,
      queue: playable,
      currentIndex: mappedStart,
    );
    try {
      await _audio.loadQueue(playable, initialIndex: mappedStart);
      final song = state.currentSong;
      final resolved = _audio.player.duration;
      if (song != null &&
          resolved != null &&
          resolved > const Duration(seconds: 2)) {
        await _mergeResolvedLibraryDuration(song.id, resolved);
      }
      if (song != null) {
        await ref
            .read(preferencesNotifierProvider.notifier)
            .addRecentForSong(song.id);
        unawaited(
          ref
              .read(reviewPromptServiceProvider)
              .onMeaningfulActionAndMaybePrompt(),
        );
      }
      await _audio.play();
    } catch (e, st) {
      debugPrint('playQueue error: $e\n$st');
      state = state.copyWith(
        processingState: AppProcessingState.error,
        errorMessage: 'Could not start playback.',
      );
    }
  }

  /// Plays [collection] from the tapped index. When shuffle is on, the tapped
  /// track plays first and the rest are in random order (list order is the
  /// source of truth; just_audio shuffle stays off to match the UI queue).
  Future<void> playFromCollection(
      List<Song> collection, int tappedIndex) async {
    if (collection.isEmpty) return;
    final i = tappedIndex.clamp(0, collection.length - 1);
    final shuffle = state.shuffleEnabled;
    var queue = List<Song>.from(collection);
    var start = i;
    if (shuffle && queue.length > 1) {
      final first = queue[i];
      final rest = <Song>[
        for (var j = 0; j < queue.length; j++)
          if (j != i) queue[j],
      ]..shuffle(math.Random());
      queue = [first, ...rest];
      start = 0;
    }
    await playQueue(queue, startIndex: start);
    if (shuffle && collection.length > 1) {
      await _audio.setShuffle(false);
    }
  }

  Future<void> playSong(Song song) async {
    await playQueue([song], startIndex: 0);
  }

  Future<void> playNext(Song song) async {
    if (!song.hasPlayableSource) {
      return;
    }

    try {
      if (state.queue.isEmpty) {
        state = state.copyWith(
          processingState: AppProcessingState.loading,
          clearError: true,
          queue: [song],
          currentIndex: 0,
        );
        await _audio.loadQueue([song], initialIndex: 0);
        await _audio.pause();
        state = state.copyWith(
          processingState: AppProcessingState.ready,
          isPlaying: false,
        );
        return;
      }

      final idx = _audio.player.currentIndex ?? state.currentIndex;
      final ci = idx.clamp(0, state.queue.length - 1);
      final ok = await _audio.addSongAfterCurrent(song);
      if (!ok) {
        return;
      }

      final insertAt = math.min(ci + 1, state.queue.length);
      final q = [...state.queue];
      q.insert(insertAt, song);
      state = state.copyWith(queue: q);
    } catch (e, st) {
      debugPrint('playNext: $e\n$st');
    }
  }

  Future<void> addSongToQueue(Song song) async {
    if (!song.hasPlayableSource) {
      return;
    }

    try {
      if (state.queue.isEmpty) {
        await playQueue([song], startIndex: 0);
        return;
      }
      final ok = await _audio.addSongToEnd(song);
      if (!ok) return;
      state = state.copyWith(queue: [...state.queue, song]);
    } catch (e, st) {
      debugPrint('addSongToQueue: $e\n$st');
    }
  }

  Future<void> togglePlay() async {
    if (state.currentSong == null) return;
    if (state.isPlaying) {
      await _audio.pause();
    } else {
      await _audio.play();
    }
  }

  Future<void> seekTo(Duration position) => _audio.seek(position);

  Future<void> setVolume(double volume) => _audio.setVolume(volume);

  Future<void> skipNext() async {
    final p = _audio.player;
    if (p.hasNext) {
      await p.seekToNext();
      return;
    }
    final q = state.queue;
    if (!state.shuffleEnabled &&
        state.loopMode == LoopMode.all &&
        q.length > 1) {
      await _audio.jumpToQueueIndex(0);
      await _audio.play();
    }
  }

  Future<void> skipPrevious() async {
    final p = _audio.player;
    if (p.hasPrevious) {
      await p.seekToPrevious();
      return;
    }
    final q = state.queue;
    if (!state.shuffleEnabled &&
        state.loopMode == LoopMode.all &&
        q.length > 1) {
      await _audio.jumpToQueueIndex(q.length - 1);
      await _audio.play();
    }
  }

  Future<void> setShuffle(bool v) => _audio.setShuffle(v);

  Future<void> toggleShuffle() => _audio.setShuffle(!state.shuffleEnabled);

  Future<void> cycleRepeat() async {
    final next = switch (state.loopMode) {
      LoopMode.off => LoopMode.all,
      LoopMode.all => LoopMode.one,
      LoopMode.one => LoopMode.off,
    };
    await _audio.setLoopMode(next);
  }

  Future<void> toggleLikeCurrent() async {
    final id = state.currentSong?.id;
    if (id == null) return;
    await ref.read(preferencesNotifierProvider.notifier).toggleLike(id);
    unawaited(
      ref.read(reviewPromptServiceProvider).onMeaningfulActionAndMaybePrompt(),
    );
  }

  Future<void> toggleLikeSong(String id) async {
    await ref.read(preferencesNotifierProvider.notifier).toggleLike(id);
    unawaited(
      ref.read(reviewPromptServiceProvider).onMeaningfulActionAndMaybePrompt(),
    );
  }

  Future<void> playFromQueueIndex(int index) async {
    if (index < 0 || index >= state.queue.length) return;
    await _audio.jumpToQueueIndex(index);
    await _audio.play();
    final id = state.queue[index].id;
    await ref.read(preferencesNotifierProvider.notifier).addRecentForSong(id);
  }

  Future<void> removeQueueItem(int index) async {
    if (index < 0 || index >= state.queue.length) return;
    await _audio.removeQueueItemAt(index);
    final next = [...state.queue]..removeAt(index);
    if (next.isEmpty) {
      state = PlayerState.empty;
      return;
    }
    final ci = _audio.player.currentIndex ?? state.currentIndex;
    state =
        state.copyWith(queue: next, currentIndex: ci.clamp(0, next.length - 1));
  }

  Future<void> moveQueueItemUp(int index) async {
    if (index <= 0 || index >= state.queue.length) return;
    await _audio.moveQueueItem(index, index - 1);
    final next = [...state.queue];
    final item = next.removeAt(index);
    next.insert(index - 1, item);
    final ci = _audio.player.currentIndex ?? state.currentIndex;
    state =
        state.copyWith(queue: next, currentIndex: ci.clamp(0, next.length - 1));
  }

  Future<void> moveQueueItemDown(int index) async {
    if (index < 0 || index >= state.queue.length - 1) return;
    await _audio.moveQueueItem(index, index + 1);
    final next = [...state.queue];
    final item = next.removeAt(index);
    next.insert(index + 1, item);
    final ci = _audio.player.currentIndex ?? state.currentIndex;
    state =
        state.copyWith(queue: next, currentIndex: ci.clamp(0, next.length - 1));
  }

  /// Moves a row to play immediately after the current track (swipe-to-promote).
  Future<void> moveQueueItemAfterCurrent(int fromIndex) async {
    if (state.queue.length < 2) return;
    if (fromIndex < 0 || fromIndex >= state.queue.length) return;
    final ci = (_audio.player.currentIndex ?? state.currentIndex)
        .clamp(0, state.queue.length - 1);
    if (fromIndex == ci) return;
    if (fromIndex == ci + 1) return;

    var i = fromIndex;
    while (i > ci + 1) {
      await moveQueueItemUp(i);
      i--;
    }
    while (i < ci + 1) {
      await moveQueueItemDown(i);
      i++;
    }
  }

  Future<void> clearQueue() async {
    await _audio.clearQueue();
    state = PlayerState.empty;
  }

  Future<void> stop() async {
    await clearQueue();
  }

  Future<void> saveQueueAsPlaylist(String title) async {
    final queue = state.queue;
    if (queue.isEmpty) return;
    final playlist = await ref
        .read(userPlaylistsProvider.notifier)
        .createPlaylist(title, description: 'Saved from queue');
    if (playlist == null) return;
    for (final song in queue) {
      await ref
          .read(userPlaylistsProvider.notifier)
          .addSong(playlist.id, song.id);
    }
  }

  Future<void> reshuffleQueueSmart() async {
    if (state.queue.length < 3) return;
    final current = state.currentSong;
    final original = [...state.queue];
    final pool = [...original];
    if (current != null) {
      pool.remove(current);
    }

    final rnd = math.Random();
    final shuffled = <Song>[];
    String? lastArtist;
    while (pool.isNotEmpty) {
      final candidates = pool.where((s) => s.artistId != lastArtist).toList();
      final pickFrom = candidates.isEmpty ? pool : candidates;
      final selected = pickFrom[rnd.nextInt(pickFrom.length)];
      shuffled.add(selected);
      lastArtist = selected.artistId;
      pool.remove(selected);
    }
    final nextQueue = current == null ? shuffled : [current, ...shuffled];
    await playQueue(nextQueue, startIndex: 0);
  }
}
