import 'dart:collection';

import '../models/song.dart';
import 'io_platform.dart';

/// Stable key per local track for deduplication lists and persistence.
String songPlaybackDedupeKey(Song s) {
  final r = s.localAudioUri?.trim() ?? '';
  if (r.isEmpty) {
    return s.id;
  }
  final k = playbackUriDedupeKey(r);
  return k.isEmpty ? s.id : k;
}

/// One entry per playback target; preserves first-seen ordering.
List<Song> dedupePersistedLibrary(List<Song> songs) {
  final kept = LinkedHashMap<String, Song>();
  for (final s in songs) {
    final k = songPlaybackDedupeKey(s);
    kept.putIfAbsent(k, () => s);
  }
  return kept.values.toList();
}
