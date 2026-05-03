import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/track_title_sanitize.dart';
import '../models/song.dart';

bool _nonEmpty(String? s) => s != null && s.trim().isNotEmpty;

Future<void> openStreamingUrl(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!context.mounted || ok) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Could not open link.')),
  );
}

/// Resolves Spotify / YouTube search URLs for a [song], with optional enriched
/// strings from MusicBrainz.
class SongStreamingUrls {
  SongStreamingUrls(this.song, {this.searchTitle, this.searchArtist});

  final Song song;
  final String? searchTitle;
  final String? searchArtist;

  String get titleForSearch {
    final raw = (searchTitle?.trim().isNotEmpty ?? false)
        ? searchTitle!.trim()
        : song.title;
    return sanitizeTrackTitleForSearch(raw);
  }

  String get artistForSearch {
    final o = searchArtist?.trim();
    final raw = (o != null && o.isNotEmpty) ? o : song.artistName;
    return sanitizeTrackTitleForSearch(raw);
  }

  String get spotifyUrl => _nonEmpty(song.spotifyUrl)
      ? song.spotifyUrl!.trim()
      : 'https://open.spotify.com/search/${Uri.encodeComponent('$titleForSearch $artistForSearch')}';

  String get youtubeVideoUrl => _nonEmpty(song.youtubeVideoUrl)
      ? song.youtubeVideoUrl!.trim()
      : 'https://www.youtube.com/results?search_query=${Uri.encodeComponent('$titleForSearch $artistForSearch official music video')}';

  String get youtubeAudioUrl => _nonEmpty(song.youtubeAudioUrl)
      ? song.youtubeAudioUrl!.trim()
      : 'https://music.youtube.com/search?q=${Uri.encodeComponent('$titleForSearch $artistForSearch')}';

  String get appleMusicSearchUrl =>
      'https://music.apple.com/search?term=${Uri.encodeComponent('$titleForSearch $artistForSearch')}';
}

/// Opens Spotify, then YouTube (video), then YouTube Music (audio) — fixed order.
///
/// When [searchTitle] / [searchArtist] are set (e.g. from MusicBrainz), outbound
/// searches use those instead of embedded [song] tags.
class SongStreamingLinks extends StatelessWidget {
  const SongStreamingLinks({
    super.key,
    required this.song,
    this.searchTitle,
    this.searchArtist,
    this.includeAppleMusic = false,
  });

  final Song song;

  /// Overrides title for Spotify / YouTube search URLs.
  final String? searchTitle;

  /// Overrides artist for Spotify / YouTube search URLs.
  final String? searchArtist;

  /// Fourth shortcut to Apple Music search (title + artist).
  final bool includeAppleMusic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.colorScheme.secondary;
    final urls = SongStreamingUrls(song,
        searchTitle: searchTitle, searchArtist: searchArtist);
    return Column(
      children: [
        Text(
          'Listen elsewhere',
          textAlign: TextAlign.center,
          style: theme.textTheme.labelLarge?.copyWith(
            color: secondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          runSpacing: 4,
          children: [
            IconButton(
              tooltip: 'Open in Spotify',
              visualDensity: VisualDensity.compact,
              onPressed: () => openStreamingUrl(context, urls.spotifyUrl),
              icon: Icon(Icons.music_note_rounded, color: secondary),
            ),
            IconButton(
              tooltip: 'YouTube (video)',
              visualDensity: VisualDensity.compact,
              onPressed: () => openStreamingUrl(context, urls.youtubeVideoUrl),
              icon: Icon(Icons.play_circle_outline_rounded, color: secondary),
            ),
            IconButton(
              tooltip: 'YouTube Music (audio)',
              visualDensity: VisualDensity.compact,
              onPressed: () => openStreamingUrl(context, urls.youtubeAudioUrl),
              icon: Icon(Icons.headphones_rounded, color: secondary),
            ),
            if (includeAppleMusic)
              IconButton(
                tooltip: 'Apple Music',
                visualDensity: VisualDensity.compact,
                onPressed: () =>
                    openStreamingUrl(context, urls.appleMusicSearchUrl),
                icon: Icon(Icons.apple_rounded, color: secondary),
              ),
          ],
        ),
      ],
    );
  }
}

/// Artist, album, and streaming shortcuts for the now-playing overflow menu.
List<PopupMenuEntry<void>> nowPlayingTrackDetailsMenuEntries({
  required BuildContext context,
  required ThemeData theme,
  required Song song,
  required String displayArtist,
  required String displayAlbum,
  String? searchTitle,
  String? searchArtist,
}) {
  final urls = SongStreamingUrls(song,
      searchTitle: searchTitle, searchArtist: searchArtist);
  final secondary = theme.colorScheme.secondary;

  void afterMenuPop(VoidCallback fn) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) fn();
    });
  }

  Widget menuRow(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 22, color: secondary),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
  }

  return [
    PopupMenuItem<void>(
      enabled: false,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Artist', style: theme.textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(displayArtist, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 10),
          Text('Album', style: theme.textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(
            displayAlbum.trim().isEmpty ? '—' : displayAlbum,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    ),
    const PopupMenuDivider(),
    PopupMenuItem<void>(
      enabled: false,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        'Listen elsewhere',
        style: theme.textTheme.labelLarge?.copyWith(
          color: secondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    PopupMenuItem<void>(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      onTap: () => afterMenuPop(() => openStreamingUrl(context, urls.spotifyUrl)),
      child: menuRow(Icons.music_note_rounded, 'Spotify'),
    ),
    PopupMenuItem<void>(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      onTap: () =>
          afterMenuPop(() => openStreamingUrl(context, urls.youtubeVideoUrl)),
      child: menuRow(Icons.play_circle_outline_rounded, 'YouTube (video)'),
    ),
    PopupMenuItem<void>(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      onTap: () =>
          afterMenuPop(() => openStreamingUrl(context, urls.youtubeAudioUrl)),
      child: menuRow(Icons.headphones_rounded, 'YouTube Music'),
    ),
  ];
}
