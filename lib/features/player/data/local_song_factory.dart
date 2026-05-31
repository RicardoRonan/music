import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../data/io_platform.dart';
import '../models/enriched_track_metadata.dart';
import '../models/song.dart';

const _kDevicePlaylistId = 'pl_local_device';

/// Groups imports by parent folder name as album; titles from filename.
class LocalSongFactory {
  LocalSongFactory._();

  static const String devicePlaylistId = _kDevicePlaylistId;

  static Song fromResolvedUri({
    required String sourceUri,
    required String displayPathOrName,
    Duration duration = Duration.zero,
    String artistName = 'Unknown Artist',
    String genreTag = 'Local',
  }) {
    final base = p.basename(displayPathOrName);
    final title = p.basenameWithoutExtension(base);
    final folder = p.basename(p.dirname(displayPathOrName));
    final albumTitle = folder.isEmpty || folder == '.' || folder == '/'
        ? 'Unknown Album'
        : folder;

    final albumKey = Object.hash(albumTitle, artistName);
    final albumId = 'loc_alb_$albumKey';
    final artistId = 'loc_art_${artistName.hashCode.abs()}';
    final id = 'local_${sourceUri.hashCode.abs()}';
    final parentPath = _parentPathFromDisplay(displayPathOrName);

    return Song(
      id: id,
      title: title.isEmpty ? 'Unknown Title' : title,
      artistId: artistId,
      artistName: artistName,
      albumId: albumId,
      albumTitle: albumTitle,
      duration: duration,
      localAudioUri: sourceUri,
      localParentPath: parentPath,
      genreTag: genreTag,
    );
  }

  static Future<Song> fromResolvedUriWithProbedDuration({
    required String sourceUri,
    required String displayPathOrName,
    Duration duration = Duration.zero,
    String artistName = 'Unknown Artist',
    String genreTag = 'Local',
  }) async {
    var song = fromResolvedUri(
      sourceUri: sourceUri,
      displayPathOrName: displayPathOrName,
      duration: duration,
      artistName: artistName,
      genreTag: genreTag,
    );
    if (song.duration <= Duration.zero && !kIsWeb) {
      final uri = song.localAudioUri?.trim();
      if (uri != null && uri.isNotEmpty) {
        final probed = await probeAudioDuration(uri);
        if (probed != null && probed > Duration.zero) {
          song = song.withDuration(probed);
        }
      }
    }
    return song;
  }

  static EnrichedTrackMetadata filenameFallbackMetadata({
    required String sourceUri,
    required String displayPathOrName,
  }) {
    final song = fromResolvedUri(
      sourceUri: sourceUri,
      displayPathOrName: displayPathOrName,
    );
    return EnrichedTrackMetadata(
      title: song.title,
      artistName: song.artistName,
      albumTitle: song.albumTitle,
      confidence: 0.35,
    );
  }

  static String? _parentPathFromDisplay(String displayPathOrName) {
    final t = displayPathOrName.trim();
    if (t.isEmpty) return null;
    final hasSep = t.contains(p.separator) ||
        t.contains('/') ||
        t.contains(r'\');
    if (!hasSep) return null;
    final parent = p.dirname(t);
    if (parent == '.' || parent.isEmpty || parent == '/' || parent == r'\') {
      return null;
    }
    return p.normalize(parent);
  }
}
