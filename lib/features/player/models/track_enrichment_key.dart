import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import '../../../core/utils/track_title_sanitize.dart';
import '../data/musicbrainz_repository.dart';
import 'song.dart';

/// Cache key for [trackEnrichmentProvider]; includes [albumId] so resolved art
/// can be persisted once per album and reused across all tracks in that album.
@immutable
class TrackEnrichmentKey {
  const TrackEnrichmentKey({
    required this.songId,
    required this.albumId,
    required this.title,
    required this.artistName,
    required this.albumTitle,
    required this.isLocalFile,
    this.localAudioUri,
  });

  final String songId;
  final String albumId;
  final String title;
  final String artistName;
  final String albumTitle;
  final bool isLocalFile;

  /// `file:` URI for AcoustID / fpcalc when MusicBrainz text search fails.
  final String? localAudioUri;

  factory TrackEnrichmentKey.fromSong(Song song) {
    var title = sanitizeTrackTitleForSearch(song.title);
    var artist = sanitizeTrackTitleForSearch(song.artistName);
    var album = sanitizeTrackTitleForSearch(song.albumTitle);

    final artistUnknown = artist.trim().isEmpty ||
        artist.trim().toLowerCase() == 'unknown artist' ||
        artist.trim().toLowerCase() == 'unknown';

    if (artistUnknown) {
      final split = _splitArtistAlbumHint(album);
      if (split != null) {
        artist = split.$1;
        album = split.$2;
      }
    }

    if (song.isLocalFile &&
        MusicBrainzRepository.isGenericAlbumTitle(album) &&
        song.localParentPath != null &&
        song.localParentPath!.trim().isNotEmpty) {
      final leaf = p.basename(song.localParentPath!.trim());
      if (leaf.isNotEmpty && leaf != '.' && leaf != '/') {
        album = leaf;
      }
    }
    final rawUri = song.localAudioUri?.trim();
    return TrackEnrichmentKey(
      songId: song.id,
      albumId: song.albumId,
      title: title,
      artistName: artist,
      albumTitle: album,
      isLocalFile: song.isLocalFile,
      localAudioUri: (rawUri == null || rawUri.isEmpty) ? null : rawUri,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TrackEnrichmentKey &&
      songId == other.songId &&
      albumId == other.albumId &&
      title == other.title &&
      artistName == other.artistName &&
      albumTitle == other.albumTitle &&
      isLocalFile == other.isLocalFile &&
      localAudioUri == other.localAudioUri;

  @override
  int get hashCode => Object.hash(
        songId,
        albumId,
        title,
        artistName,
        albumTitle,
        isLocalFile,
        localAudioUri,
      );
}

(String, String)? _splitArtistAlbumHint(String rawAlbum) {
  final album = rawAlbum.trim();
  if (album.isEmpty) return null;
  final separator = RegExp(r'\s+[-|]\s+');
  final parts = album
      .split(separator)
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
  if (parts.length < 2) return null;
  final artist = parts.first;
  final albumName = parts.sublist(1).join(' - ').trim();
  if (artist.isEmpty || albumName.isEmpty) return null;
  return (artist, albumName);
}
