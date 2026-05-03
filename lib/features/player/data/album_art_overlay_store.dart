import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const _kAlbumArtOverlay = 'music_album_art_overlay_v1';

/// Persists MusicBrainz / Cover Art Archive URLs keyed by catalog [Album.id].
class AlbumArtOverlayStore {
  AlbumArtOverlayStore(this._prefs);

  final SharedPreferences _prefs;

  Map<String, String> load() {
    final raw = _prefs.getString(_kAlbumArtOverlay);
    if (raw == null || raw.isEmpty) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }

  Future<void> save(Map<String, String> map) async {
    await _prefs.setString(_kAlbumArtOverlay, jsonEncode(map));
  }
}
