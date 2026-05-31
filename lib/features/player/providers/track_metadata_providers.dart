import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/acoustid_client_key.dart';
import '../../../core/config/spotify_client_credentials.dart';
import '../data/acoustid_repository.dart';
import '../data/chromaprint_runner.dart';
import '../data/local_song_factory.dart';
import '../data/spotify_repository.dart';
import '../models/enriched_track_metadata.dart';
import '../models/track_enrichment_key.dart';
import 'album_artwork_notifier.dart';
import 'local_library_notifier.dart';
import 'music_brainz_providers.dart';

export '../models/track_enrichment_key.dart';
export 'music_brainz_providers.dart';

final acoustidRepositoryProvider = Provider<AcoustIdRepository>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return AcoustIdRepository(httpClient: client);
});

final spotifyRepositoryProvider = Provider<SpotifyRepository>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return SpotifyRepository(httpClient: client);
});

Future<void> _persistEnrichmentAlbumArt(
  Ref ref,
  TrackEnrichmentKey key,
  EnrichedTrackMetadata? meta,
) async {
  if (kIsWeb) return;
  final url = meta?.artworkUrl?.trim();
  if (url == null || url.isEmpty) return;
  final aid = key.albumId.trim();
  if (aid.isEmpty) return;
  await ref.read(albumArtworkProvider.notifier).rememberArtworkUrl(aid, url);
}

EnrichedTrackMetadata? _filenameFallbackMetadata(TrackEnrichmentKey key) {
  if (!key.isLocalFile) return null;
  final uri = key.localAudioUri?.trim();
  if (uri == null || uri.isEmpty) return null;

  if (kIsWeb) {
    return EnrichedTrackMetadata(
      title: key.title,
      artistName: key.artistName,
      albumTitle: key.albumTitle,
      confidence: 0.35,
    );
  }

  var displayPath = uri;
  final parsed = Uri.tryParse(uri);
  if (parsed != null && parsed.scheme == 'file') {
    displayPath = parsed.path;
  }

  return LocalSongFactory.filenameFallbackMetadata(
    sourceUri: uri,
    displayPathOrName: displayPath,
  );
}

/// Resolves display metadata: **Spotify** (when credentials are set) as the main
/// catalog, **AcoustID** fingerprint first for local files, **MusicBrainz** only
/// if both miss. Persists cover URL once per [TrackEnrichmentKey.albumId].
final trackEnrichmentProvider = FutureProvider.autoDispose
    .family<EnrichedTrackMetadata?, TrackEnrichmentKey>((ref, key) async {
  final repo = ref.read(musicBrainzRepositoryProvider);
  final acoustid = ref.read(acoustidRepositoryProvider);
  final spotify = ref.read(spotifyRepositoryProvider);
  final clientKey = resolveAcoustIdClientKey();
  EnrichedTrackMetadata? meta;

  Future<EnrichedTrackMetadata?> acoustidForLocal() async {
    if (!key.isLocalFile) return null;
    final uri = key.localAudioUri?.trim();
    if (uri == null || uri.isEmpty) return null;
    final fp = await chromaprintFromFileUri(uri);
    if (fp == null) return null;
    return acoustid.lookupEnrichment(
      clientKey: clientKey,
      fingerprint: fp.fingerprint,
      durationSeconds: fp.durationSeconds,
    );
  }

  try {
    // Local: AcoustID fingerprint first (IDs may be merged into Spotify-primary result).
    if (key.isLocalFile) {
      meta = await acoustidForLocal();
    }

    // Spotify as main catalog (title / artist / album / art / link) when configured.
    final spotifyCreds = resolveSpotifyClientCredentials();
    if (!kIsWeb && spotifyCreds != null) {
      final sm = await spotify.searchTrackEnrichment(
        title: key.title,
        artistName: key.artistName,
        albumTitle: key.albumTitle,
      );
      if (sm != null) {
        meta = EnrichedTrackMetadata.preferSpotifyPrimary(meta, sm);
      }
    }

    final albumTrackCount = ref
        .read(localLibraryProvider)
        .where((s) => s.albumId == key.albumId)
        .length;

    // MusicBrainz only when nothing else matched (avoids wrong MB matches when Spotify works).
    meta ??= await repo.lookupFromLocalHints(
      title: key.title,
      artistName: key.artistName,
      albumTitle: key.albumTitle,
      expectedAlbumTrackCount:
          albumTrackCount > 1 ? albumTrackCount : null,
    );

    if (meta == null || meta.confidence < 0.5) {
      final fallback = _filenameFallbackMetadata(key);
      if (fallback != null) {
        meta = meta == null || fallback.confidence > meta.confidence
            ? fallback
            : meta;
      }
    }
  } catch (e, st) {
    debugPrint('trackEnrichmentProvider: $e\n$st');
    return null;
  }

  try {
    if (meta != null && key.isLocalFile) {
      await ref
          .read(localLibraryProvider.notifier)
          .applyEnrichedMetadataIfChanged(key.songId, meta);
      final u = meta.artworkUrl?.trim();
      if (u != null && u.isNotEmpty) {
        final rows =
            ref.read(localLibraryProvider).where((s) => s.id == key.songId);
        if (rows.isNotEmpty) {
          await ref
              .read(albumArtworkProvider.notifier)
              .rememberArtworkUrl(rows.first.albumId, u);
        }
      }
    } else if (meta != null) {
      await _persistEnrichmentAlbumArt(ref, key, meta);
    }
  } catch (e, st) {
    debugPrint('trackEnrichmentProvider persist: $e\n$st');
  }
  return meta;
});
