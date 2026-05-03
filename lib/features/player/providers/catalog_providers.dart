import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../playlists/providers/user_playlists_notifier.dart';
import '../data/music_catalog.dart';
import 'album_artwork_notifier.dart';
import 'local_library_notifier.dart';

final musicCatalogProvider = Provider<MusicCatalog>((ref) {
  final local = ref.watch(localLibraryProvider);
  final userPlaylists = ref.watch(userPlaylistsProvider);
  final albumArtById = ref.watch(albumArtworkProvider);
  return MusicCatalog(
    localSongs: local,
    userPlaylists: userPlaylists,
    albumArtworkByAlbumId: albumArtById,
  );
});
