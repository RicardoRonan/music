import '../models/song.dart';

/// MusicBrainz-backed row for outbound discovery — not playable in-app unless
/// you later resolve a stream.
class DiscoveredRecording {
  const DiscoveredRecording({
    required this.recordingMbid,
    required this.title,
    required this.artistName,
    required this.albumTitle,
    this.artworkUrl,
  });

  final String recordingMbid;
  final String title;
  final String artistName;
  final String albumTitle;

  /// Cover Art Archive front when a release mbid was available.
  final String? artworkUrl;

  /// Placeholder catalog entry for Spotify / YouTube / Apple outbound links only.
  Song toOutboundSong() {
    return Song(
      id: 'disc_mb_$recordingMbid',
      title: title,
      artistId: 'disc_art_$recordingMbid',
      artistName: artistName,
      albumId: 'disc_rel_$recordingMbid',
      albumTitle: albumTitle,
      duration: Duration.zero,
      artworkUrl: artworkUrl,
      genreTag: 'Discover',
    );
  }
}
