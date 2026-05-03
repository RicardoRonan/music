import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../player/models/playlist.dart';

const _kUserPlaylists = 'music_user_playlists_v1';

class UserPlaylistStore {
  UserPlaylistStore(this._prefs);

  final SharedPreferences _prefs;

  List<Playlist> load() {
    final raw = _prefs.getString(_kUserPlaylists);
    if (raw == null || raw.isEmpty) return [];
    try {
      final rows = jsonDecode(raw) as List<dynamic>;
      return rows
          .map((row) => _fromMap(row as Map<String, dynamic>))
          .whereType<Playlist>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(List<Playlist> playlists) async {
    final rows = playlists.map(_toMap).toList();
    await _prefs.setString(_kUserPlaylists, jsonEncode(rows));
  }

  Map<String, dynamic> _toMap(Playlist p) => {
        'id': p.id,
        'title': p.title,
        'description': p.description,
        'songIds': p.songIds,
        if (p.coverUrl != null && p.coverUrl!.trim().isNotEmpty)
          'coverUrl': p.coverUrl,
      };

  Playlist? _fromMap(Map<String, dynamic> map) {
    final id = map['id'] as String?;
    final title = map['title'] as String?;
    if (id == null || id.isEmpty || title == null || title.trim().isEmpty) {
      return null;
    }
    final rawSongs = map['songIds'] as List<dynamic>? ?? const [];
    return Playlist(
      id: id,
      title: title.trim(),
      description: (map['description'] as String?)?.trim() ?? '',
      songIds: rawSongs.map((e) => e.toString()).toList(),
      coverUrl: map['coverUrl'] as String?,
      category: 'User',
    );
  }
}
