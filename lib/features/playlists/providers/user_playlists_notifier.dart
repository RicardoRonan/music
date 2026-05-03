import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../player/models/playlist.dart';
import '../../player/providers/shared_preferences_provider.dart';
import '../data/user_playlist_store.dart';

final userPlaylistsProvider =
    NotifierProvider<UserPlaylistsNotifier, List<Playlist>>(
  UserPlaylistsNotifier.new,
);

class UserPlaylistsNotifier extends Notifier<List<Playlist>> {
  UserPlaylistStore get _store =>
      UserPlaylistStore(ref.read(sharedPreferencesProvider));

  @override
  List<Playlist> build() => _store.load();

  Future<Playlist?> createPlaylist(String title, {String? description}) async {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) return null;
    final playlist = Playlist(
      id: 'usr_${DateTime.now().microsecondsSinceEpoch}',
      title: cleanTitle,
      description: (description ?? '').trim(),
      songIds: const [],
      category: 'User',
    );
    final next = [...state, playlist];
    await _store.save(next);
    state = next;
    return playlist;
  }

  Future<void> addSong(String playlistId, String songId) async {
    await _mutate(playlistId, (p) {
      final ids = [...p.songIds];
      if (!ids.contains(songId)) ids.add(songId);
      return Playlist(
        id: p.id,
        title: p.title,
        description: p.description,
        songIds: ids,
        coverUrl: p.coverUrl,
        category: p.category,
      );
    });
  }

  Future<void> removeSong(String playlistId, String songId) async {
    await _mutate(playlistId, (p) {
      final ids = p.songIds.where((id) => id != songId).toList();
      return Playlist(
        id: p.id,
        title: p.title,
        description: p.description,
        songIds: ids,
        coverUrl: p.coverUrl,
        category: p.category,
      );
    });
  }

  Future<void> reorderSongs(String playlistId, int oldIndex, int newIndex) async {
    await _mutate(playlistId, (p) {
      final ids = [...p.songIds];
      if (oldIndex < 0 || oldIndex >= ids.length) return p;
      final target = newIndex.clamp(0, ids.length - 1);
      final item = ids.removeAt(oldIndex);
      ids.insert(target, item);
      return Playlist(
        id: p.id,
        title: p.title,
        description: p.description,
        songIds: ids,
        coverUrl: p.coverUrl,
        category: p.category,
      );
    });
  }

  Future<void> renamePlaylist(String playlistId, String title) async {
    final clean = title.trim();
    if (clean.isEmpty) return;
    await _mutate(playlistId, (p) {
      return Playlist(
        id: p.id,
        title: clean,
        description: p.description,
        songIds: p.songIds,
        coverUrl: p.coverUrl,
        category: p.category,
      );
    });
  }

  Future<void> deletePlaylist(String playlistId) async {
    final next = state.where((p) => p.id != playlistId).toList();
    await _store.save(next);
    state = next;
  }

  Future<void> _mutate(
    String playlistId,
    Playlist Function(Playlist) update,
  ) async {
    final idx = state.indexWhere((p) => p.id == playlistId);
    if (idx == -1) return;
    final next = [...state];
    next[idx] = update(next[idx]);
    await _store.save(next);
    state = next;
  }
}
