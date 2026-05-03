import 'package:path/path.dart' as p;

import 'local_library_dedupe.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../models/playlist.dart';
import '../models/song.dart';
import 'local_song_factory.dart';

/// Catalog merging local imports with user playlists.
class MusicCatalog {
  MusicCatalog({
    List<Song> localSongs = const [],
    List<Playlist> userPlaylists = const [],
    Map<String, String> albumArtworkByAlbumId = const {},
  })  : _local = localSongs,
        _userPlaylists = userPlaylists,
        _albumArtworkByAlbumId = albumArtworkByAlbumId;

  final List<Song> _local;
  final List<Playlist> _userPlaylists;
  final Map<String, String> _albumArtworkByAlbumId;

  Song _withAlbumArtOverlay(Song s) {
    final overlay = _albumArtworkByAlbumId[s.albumId];
    if (overlay != null && overlay.isNotEmpty) {
      return s.withArtworkUrl(overlay);
    }
    return s;
  }

  List<Song> get _localWithArtOverlay =>
      _local.map(_withAlbumArtOverlay).toList();

  String? _albumArtUrlForAlbumId(String albumId) {
    final u = _albumArtworkByAlbumId[albumId];
    return (u != null && u.isNotEmpty) ? u : null;
  }

  static const String _devicePlaylistId = LocalSongFactory.devicePlaylistId;

  List<Song> get allSongs => _localWithArtOverlay;

  List<Playlist> get allPlaylists => [
        ..._userPlaylists,
        if (_local.isNotEmpty) _devicePlaylist(),
      ];

  List<Artist> get allArtists => _localArtists();

  List<Album> get allAlbums => _localAlbums();

  Playlist _devicePlaylist() => Playlist(
        id: _devicePlaylistId,
        title: 'On this device',
        description: 'Imported audio files on this device.',
        songIds: _localWithArtOverlay.map((s) => s.id).toList(),
        category: 'Local',
      );

  List<Album> _localAlbums() {
    final byAlbum = <String, List<Song>>{};
    for (final s in _local) {
      byAlbum.putIfAbsent(s.albumId, () => []).add(s);
    }
    return byAlbum.entries.map((e) {
      final first = e.value.first;
      return Album(
        id: e.key,
        title: first.albumTitle,
        artistId: first.artistId,
        artworkUrl: _albumArtUrlForAlbumId(e.key),
      );
    }).toList();
  }

  List<Artist> _localArtists() {
    final byId = <String, Song>{};
    for (final s in _local) {
      byId[s.artistId] = s;
    }
    return byId.entries
        .map(
          (e) => Artist(
            id: e.key,
            name: e.value.artistName,
          ),
        )
        .toList();
  }

  Song? songById(String id) {
    for (final s in _localWithArtOverlay) {
      if (s.id == id) return s;
    }
    return null;
  }

  Album? albumById(String id) {
    for (final a in allAlbums) {
      if (a.id == id) return a;
    }
    return null;
  }

  Playlist? playlistById(String id) {
    for (final p in _userPlaylists) {
      if (p.id == id) return p;
    }
    if (id == _devicePlaylistId) {
      return _local.isNotEmpty ? _devicePlaylist() : null;
    }
    return null;
  }

  List<Song> songsForAlbum(String albumId) =>
      allSongs.where((s) => s.albumId == albumId).toList();

  List<Song> songsForPlaylist(Playlist p) {
    if (p.id == _devicePlaylistId) {
      final map = {for (final s in _localWithArtOverlay) s.id: s};
      return p.songIds.map((id) => map[id]).whereType<Song>().toList();
    }
    return p.songIds.map((id) => songById(id)).whereType<Song>().toList();
  }

  List<Song> recommendedForYou() => _localWithArtOverlay.where((s) => s.genreTag == 'For You').toList();

  List<Song> recentlyPlayedFromIds(List<String> ids) =>
      ids.map(songById).whereType<Song>().toList();

  List<Song> likedFromIds(Set<String> ids) =>
      allSongs.where((s) => ids.contains(s.id)).toList();

  List<Playlist> playlistsByCategory(String category) =>
      allPlaylists.where((p) => p.category == category).toList();

  List<Song> searchSongs(String q) {
    final needle = q.toLowerCase();
    return allSongs
        .where(
          (s) =>
              s.title.toLowerCase().contains(needle) ||
              s.artistName.toLowerCase().contains(needle) ||
              s.albumTitle.toLowerCase().contains(needle),
        )
        .toList();
  }

  List<Artist> searchArtists(String q) {
    final needle = q.toLowerCase();
    return allArtists
        .where((a) => a.name.toLowerCase().contains(needle))
        .toList();
  }

  List<Album> searchAlbums(String q) {
    final needle = q.toLowerCase();
    return allAlbums
        .where((a) => a.title.toLowerCase().contains(needle))
        .toList();
  }

  List<Playlist> searchPlaylists(String q) {
    final needle = q.toLowerCase();
    return allPlaylists
        .where(
          (p) =>
              p.title.toLowerCase().contains(needle) ||
              p.description.toLowerCase().contains(needle),
        )
        .toList();
  }

  /// Imported / scanned device files grouped by parent path (fallback: album title).
  Map<String, List<Song>> get deviceSongsByFolder {
    final m = <String, List<Song>>{};
    final seenKeysByFolder = <String, Set<String>>{};
    for (final s in _localWithArtOverlay) {
      final key = (s.localParentPath != null &&
              s.localParentPath!.trim().isNotEmpty)
          ? s.localParentPath!
          : s.albumTitle;
      final dk = songPlaybackDedupeKey(s);
      final seen =
          seenKeysByFolder.putIfAbsent(key, () => <String>{});
      if (!seen.add(dk)) {
        continue;
      }
      m.putIfAbsent(key, () => []).add(s);
    }
    for (final list in m.values) {
      list.sort(
        (a, b) =>
            a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    }
    return m;
  }

  static String folderDisplayTitle(String folderKey) {
    if (folderKey.contains(p.separator) ||
        folderKey.contains('/') ||
        folderKey.contains(r'\')) {
      return p.basename(folderKey);
    }
    return folderKey;
  }

  List<String> allGenreLabelsSorted() {
    final set = <String>{};
    for (final s in allSongs) {
      final g = s.genreTag?.trim();
      set.add((g != null && g.isNotEmpty) ? g : 'Unknown');
    }
    final list = set.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }
}
