import '../../../core/utils/track_title_sanitize.dart';
import 'enriched_track_metadata.dart';

/// Single playable unit. Resolution order in [AudioPlayerService]: [localAudioUri],
/// then [assetPath], then [streamingUrl].
class Song {
  const Song({
    required this.id,
    required this.title,
    required this.artistId,
    required this.artistName,
    required this.albumId,
    required this.albumTitle,
    required this.duration,
    this.artworkUrl,
    this.streamingUrl,
    this.assetPath,
    this.localAudioUri,
    this.localParentPath,
    this.genreTag,
    this.spotifyUrl,
    this.youtubeVideoUrl,
    this.youtubeAudioUrl,
  });

  final String id;
  final String title;
  final String artistId;
  final String artistName;
  final String albumId;
  final String albumTitle;
  final Duration duration;
  final String? artworkUrl;

  /// HTTPS stream when you move off mock assets (watch CORS on web).
  final String? streamingUrl;

  /// Local asset path, e.g. `assets/audio/sample.mp3`.
  final String? assetPath;

  /// `file://` or `content://` URI from the device — used for imported files.
  final String? localAudioUri;

  /// Absolute parent directory of the file when known (device scan / import path).
  final String? localParentPath;

  /// UI chips: Focus, Chill, Workout, etc.
  final String? genreTag;

  /// Curated Spotify URL; when null, [spotifyOpenLink] uses search.
  final String? spotifyUrl;

  /// Official / music-video style YouTube watch URL (shown before audio).
  final String? youtubeVideoUrl;

  /// YouTube Music or topic / audio-focused URL (after [youtubeVideoOpenLink] in UI).
  final String? youtubeAudioUrl;

  bool get isLocalFile =>
      localAudioUri != null && localAudioUri!.trim().isNotEmpty;

  /// Whether [AudioPlayerService] can build an [AudioSource] for this row.
  bool get hasPlayableSource =>
      (localAudioUri != null && localAudioUri!.trim().isNotEmpty) ||
      (assetPath != null && assetPath!.trim().isNotEmpty) ||
      (streamingUrl != null && streamingUrl!.trim().isNotEmpty);

  String _trimOrEmpty(String? s) => s?.trim() ?? '';

  /// Spotify app/web — search fallback uses title + artist (sanitized for search).
  String get spotifyOpenLink {
    final o = _trimOrEmpty(spotifyUrl);
    if (o.isNotEmpty) return o;
    final q =
        '${sanitizeTrackTitleForSearch(title)} ${sanitizeTrackTitleForSearch(artistName)}';
    return 'https://open.spotify.com/search/${Uri.encodeComponent(q)}';
  }

  /// YouTube (video-first discovery) — search biases official music videos.
  String get youtubeVideoOpenLink {
    final o = _trimOrEmpty(youtubeVideoUrl);
    if (o.isNotEmpty) return o;
    final q =
        '${sanitizeTrackTitleForSearch(title)} ${sanitizeTrackTitleForSearch(artistName)} official music video';
    return 'https://www.youtube.com/results?search_query=${Uri.encodeComponent(q)}';
  }

  /// YouTube Music / audio-oriented search.
  String get youtubeAudioOpenLink {
    final o = _trimOrEmpty(youtubeAudioUrl);
    if (o.isNotEmpty) return o;
    final q =
        '${sanitizeTrackTitleForSearch(title)} ${sanitizeTrackTitleForSearch(artistName)}';
    return 'https://music.youtube.com/search?q=${Uri.encodeComponent(q)}';
  }

  /// Same track with an updated length (e.g. after decoder resolves duration).
  Song withDuration(Duration newDuration) {
    return Song(
      id: id,
      title: title,
      artistId: artistId,
      artistName: artistName,
      albumId: albumId,
      albumTitle: albumTitle,
      duration: newDuration,
      artworkUrl: artworkUrl,
      streamingUrl: streamingUrl,
      assetPath: assetPath,
      localAudioUri: localAudioUri,
      localParentPath: localParentPath,
      genreTag: genreTag,
      spotifyUrl: spotifyUrl,
      youtubeVideoUrl: youtubeVideoUrl,
      youtubeAudioUrl: youtubeAudioUrl,
    );
  }

  Song withGenreTag(String? newGenreTag) {
    return Song(
      id: id,
      title: title,
      artistId: artistId,
      artistName: artistName,
      albumId: albumId,
      albumTitle: albumTitle,
      duration: duration,
      artworkUrl: artworkUrl,
      streamingUrl: streamingUrl,
      assetPath: assetPath,
      localAudioUri: localAudioUri,
      localParentPath: localParentPath,
      genreTag: newGenreTag,
      spotifyUrl: spotifyUrl,
      youtubeVideoUrl: youtubeVideoUrl,
      youtubeAudioUrl: youtubeAudioUrl,
    );
  }

  Song withArtworkUrl(String? newArtworkUrl) {
    return Song(
      id: id,
      title: title,
      artistId: artistId,
      artistName: artistName,
      albumId: albumId,
      albumTitle: albumTitle,
      duration: duration,
      artworkUrl: newArtworkUrl,
      streamingUrl: streamingUrl,
      assetPath: assetPath,
      localAudioUri: localAudioUri,
      localParentPath: localParentPath,
      genreTag: genreTag,
      spotifyUrl: spotifyUrl,
      youtubeVideoUrl: youtubeVideoUrl,
      youtubeAudioUrl: youtubeAudioUrl,
    );
  }

  /// Re-tags a local row from AcoustID / MusicBrainz enrichment (stable [id] and URI).
  Song withEnrichedLocalMetadata(EnrichedTrackMetadata meta) {
    final artist = meta.artistName.trim();
    final album = meta.albumTitle.trim();
    final tit = meta.title.trim();
    final albumKey = Object.hash(album, artist);
    final newAlbumId = 'loc_alb_$albumKey';
    final newArtistId = 'loc_art_${artist.hashCode.abs()}';
    final art = meta.artworkUrl?.trim();
    final spot = meta.spotifyOpenUrl?.trim();
    return Song(
      id: id,
      title: tit.isEmpty ? title : tit,
      artistId: newArtistId,
      artistName: artist.isEmpty ? artistName : artist,
      albumId: newAlbumId,
      albumTitle: album.isEmpty ? albumTitle : album,
      duration: duration,
      artworkUrl: (art != null && art.isNotEmpty) ? art : artworkUrl,
      streamingUrl: streamingUrl,
      assetPath: assetPath,
      localAudioUri: localAudioUri,
      localParentPath: localParentPath,
      genreTag: genreTag,
      spotifyUrl: (spot != null && spot.isNotEmpty) ? spot : spotifyUrl,
      youtubeVideoUrl: youtubeVideoUrl,
      youtubeAudioUrl: youtubeAudioUrl,
    );
  }
}
