import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/song.dart';

const _kLocalLibrary = 'music_local_library_json_v1';

/// Persists imported device files as JSON — swap for SQLite when libraries grow.
class LocalMusicStore {
  LocalMusicStore(this._prefs);

  final SharedPreferences _prefs;

  List<Song> loadSongs() {
    final raw = _prefs.getString(_kLocalLibrary);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => _songFromMap(e as Map<String, dynamic>))
          .whereType<Song>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSongs(List<Song> songs) async {
    final encoded = jsonEncode(songs.map(_songToMap).toList());
    await _prefs.setString(_kLocalLibrary, encoded);
  }

  Map<String, dynamic> _songToMap(Song s) => {
        'id': s.id,
        'title': s.title,
        'artistId': s.artistId,
        'artistName': s.artistName,
        'albumId': s.albumId,
        'albumTitle': s.albumTitle,
        'durationMs': s.duration.inMilliseconds,
        'localAudioUri': s.localAudioUri,
        if (s.localParentPath != null && s.localParentPath!.trim().isNotEmpty)
          'localParentPath': s.localParentPath,
        if (s.genreTag != null) 'genreTag': s.genreTag,
        if (s.spotifyUrl != null && s.spotifyUrl!.trim().isNotEmpty)
          'spotifyUrl': s.spotifyUrl,
        if (s.youtubeVideoUrl != null && s.youtubeVideoUrl!.trim().isNotEmpty)
          'youtubeVideoUrl': s.youtubeVideoUrl,
        if (s.youtubeAudioUrl != null && s.youtubeAudioUrl!.trim().isNotEmpty)
          'youtubeAudioUrl': s.youtubeAudioUrl,
      };

  Song? _songFromMap(Map<String, dynamic> m) {
    final uri = m['localAudioUri'] as String?;
    if (uri == null || uri.isEmpty) return null;
    return Song(
      id: m['id'] as String? ?? 'local_${uri.hashCode}',
      title: m['title'] as String? ?? 'Unknown Title',
      artistId: m['artistId'] as String? ?? 'loc_art_unknown',
      artistName: m['artistName'] as String? ?? 'Unknown Artist',
      albumId: m['albumId'] as String? ?? 'loc_alb_unknown',
      albumTitle: m['albumTitle'] as String? ?? 'Unknown Album',
      duration: Duration(milliseconds: (m['durationMs'] as num?)?.toInt() ?? 0),
      localAudioUri: uri,
      localParentPath: m['localParentPath'] as String?,
      genreTag: m['genreTag'] as String?,
      spotifyUrl: m['spotifyUrl'] as String?,
      youtubeVideoUrl: m['youtubeVideoUrl'] as String?,
      youtubeAudioUrl: m['youtubeAudioUrl'] as String?,
    );
  }
}
