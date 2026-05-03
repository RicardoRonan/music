import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/album_art_overlay_store.dart';
import '../data/musicbrainz_repository.dart';
import '../models/song.dart';
import '../models/track_enrichment_key.dart';
import 'album_art_overlay_providers.dart';
import 'local_library_notifier.dart';
import 'music_brainz_providers.dart';

final albumArtworkProvider =
    NotifierProvider<AlbumArtworkNotifier, Map<String, String>>(
  AlbumArtworkNotifier.new,
);

/// Loads persisted Cover Art URLs and resolves missing entries per album
/// against MusicBrainz (with track-name matching via [MusicBrainzRepository]).
class AlbumArtworkNotifier extends Notifier<Map<String, String>> {
  final Set<String> _missedAlbumIds = {};
  var _scheduled = false;
  var _inFlight = false;
  var _rerunWhenIdle = false;

  AlbumArtOverlayStore get _overlayStore => ref.read(albumArtOverlayStoreProvider);

  MusicBrainzRepository get _repo => ref.read(musicBrainzRepositoryProvider);

  /// Saves a Cover Art URL for [albumId] if missing (shared by all songs in
  /// that album). Called after per-track enrichment / AcoustID resolution.
  Future<void> rememberArtworkUrl(String albumId, String url) async {
    if (kIsWeb) return;
    final aid = albumId.trim();
    final u = url.trim();
    if (aid.isEmpty || u.isEmpty) return;
    if (state.containsKey(aid)) return;
    final next = Map<String, String>.from(state);
    next[aid] = u;
    state = next;
    _missedAlbumIds.remove(aid);
    await _overlayStore.save(state);
  }

  @override
  Map<String, String> build() {
    if (kIsWeb) {
      return {};
    }

    final initial = _overlayStore.load();
    _scheduleResolve();
    ref.listen<List<Song>>(localLibraryProvider, (_, __) {
      _missedAlbumIds.clear();
      if (_inFlight) {
        _rerunWhenIdle = true;
      } else {
        _scheduleResolve();
      }
    });
    return Map<String, String>.from(initial);
  }

  void _scheduleResolve() {
    if (_scheduled) return;
    _scheduled = true;
    Future<void>.delayed(Duration.zero, () async {
      _scheduled = false;
      await _resolveMissing();
    });
  }

  Future<void> _resolveMissing() async {
    if (kIsWeb || _inFlight) return;
    _inFlight = true;
    try {
      final local = ref.read(localLibraryProvider);
      if (local.isEmpty) return;

      final byAlbum = <String, List<Song>>{};
      for (final s in local) {
        byAlbum.putIfAbsent(s.albumId, () => []).add(s);
      }

      for (final entry in byAlbum.entries) {
        final albumId = entry.key;
        final tracks = entry.value;
        if (tracks.isEmpty) continue;
        if (state.containsKey(albumId) || _missedAlbumIds.contains(albumId)) {
          continue;
        }

        final albumTitle = tracks.first.albumTitle;
        if (MusicBrainzRepository.isGenericAlbumTitle(albumTitle)) {
          _missedAlbumIds.add(albumId);
          continue;
        }

        final artist =
            tracks.map((t) => t.artistName.trim()).firstWhere((a) => a.isNotEmpty,
                orElse: () => '');
        tracks.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );

        try {
          var url = await _repo.lookupAlbumCoverArtUrl(
            albumTitle: albumTitle,
            primaryArtistName: artist,
            songTitles: tracks.map((t) => t.title).toList(),
          );
          if (url == null || url.isEmpty) {
            final n = math.min(5, tracks.length);
            for (var i = 0; i < n; i++) {
              final t = tracks[i];
              if (!t.isLocalFile) continue;
              final hint = TrackEnrichmentKey.fromSong(t);
              final meta = await _repo.lookupFromLocalHints(
                title: hint.title,
                artistName: hint.artistName,
                albumTitle: hint.albumTitle,
              );
              final u = meta?.artworkUrl?.trim();
              if (u != null && u.isNotEmpty) {
                url = u;
                break;
              }
            }
          }
          if (url != null && url.isNotEmpty) {
            final next = Map<String, String>.from(state);
            next[albumId] = url;
            state = next;
            _missedAlbumIds.remove(albumId);
            await _overlayStore.save(state);
          } else {
            _missedAlbumIds.add(albumId);
          }
        } catch (_) {
          _missedAlbumIds.add(albumId);
        }
      }
    } finally {
      _inFlight = false;
      if (_rerunWhenIdle) {
        _rerunWhenIdle = false;
        _scheduleResolve();
      }
    }
  }
}
