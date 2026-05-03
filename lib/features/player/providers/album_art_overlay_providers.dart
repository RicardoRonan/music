import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/album_art_overlay_store.dart';
import 'shared_preferences_provider.dart';

final albumArtOverlayStoreProvider = Provider<AlbumArtOverlayStore>((ref) {
  return AlbumArtOverlayStore(ref.watch(sharedPreferencesProvider));
});
