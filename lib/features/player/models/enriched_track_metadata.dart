/// Metadata resolved from MusicBrainz, Cover Art Archive, AcoustID, and/or
/// Spotify search for display when local files lack embedded tags.
class EnrichedTrackMetadata {
  const EnrichedTrackMetadata({
    required this.title,
    required this.artistName,
    required this.albumTitle,
    this.artworkUrl,
    this.recordingMbid,
    this.releaseMbid,
    this.spotifyOpenUrl,
  });

  final String title;
  final String artistName;
  final String albumTitle;

  /// Cover Art Archive or Spotify album image URL; may 404 at runtime.
  final String? artworkUrl;

  final String? recordingMbid;
  final String? releaseMbid;

  /// `https://open.spotify.com/track/...` when resolved via Spotify API.
  final String? spotifyOpenUrl;

  String? get musicBrainzRecordingUrl => recordingMbid == null
      ? null
      : 'https://musicbrainz.org/recording/$recordingMbid';

  /// Spotify wins display fields; keeps AcoustID MB ids when [previous] had them.
  static EnrichedTrackMetadata preferSpotifyPrimary(
    EnrichedTrackMetadata? previous,
    EnrichedTrackMetadata spotify,
  ) {
    return EnrichedTrackMetadata(
      title: spotify.title,
      artistName: spotify.artistName,
      albumTitle: spotify.albumTitle,
      artworkUrl: spotify.artworkUrl,
      recordingMbid: previous?.recordingMbid,
      releaseMbid: previous?.releaseMbid,
      spotifyOpenUrl: spotify.spotifyOpenUrl ?? previous?.spotifyOpenUrl,
    );
  }
}
