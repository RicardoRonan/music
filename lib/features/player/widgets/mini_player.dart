import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/audio_spectrum_visualizer.dart';
import '../../../theme/windows_classic_theme_extension.dart';
import '../../../core/utils/track_title_sanitize.dart';
import '../../../core/widgets/artwork_tile.dart';
import '../models/song.dart';
import '../providers/player_notifier.dart';
import '../providers/track_metadata_providers.dart';
import 'track_swipe_surface.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({
    super.key,
    required this.song,
    required this.isPlaying,
  });

  final Song song;
  final bool isPlaying;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final enrichAsync =
        ref.watch(trackEnrichmentProvider(TrackEnrichmentKey.fromSong(song)));
    final enriched = enrichAsync.valueOrNull;
    final displayArtwork = enriched?.artworkUrl ?? song.artworkUrl;
    final displayTitle = enriched?.title ??
        (song.isLocalFile
            ? sanitizeTrackTitleForSearch(song.title)
            : song.title);
    final displayArtist = enriched?.artistName ??
        (song.isLocalFile
            ? sanitizeTrackTitleForSearch(song.artistName)
            : song.artistName);
    final notifier = ref.read(playerNotifierProvider.notifier);

    final dividerColor =
        theme.dividerTheme.color ?? theme.colorScheme.outlineVariant;
    final isDark = theme.brightness == Brightness.dark;
    final isWindowsClassic = context.isWindowsClassicTheme;
    final wc = isWindowsClassic ? context.winColors : null;

    return Material(
      color: isWindowsClassic ? wc!.chrome : theme.colorScheme.surface,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isWindowsClassic ? wc!.shadow : dividerColor,
              width: isWindowsClassic ? 2 : 1,
            ),
          ),
        ),
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TrackSwipeSurface(
                skipNext: notifier.skipNext,
                skipPrevious: notifier.skipPrevious,
                child: InkWell(
                  onTap: () => context.push('/now-playing'),
                  child: Row(
                    children: [
                      if (isWindowsClassic)
                        SizedBox(
                          width: 96,
                          height: 40,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              border: wc!.insetBorder,
                            ),
                            child: AudioSpectrumVisualizer(
                              isPlaying: isPlaying,
                              height: 40,
                              barCount: 24,
                              showPeakMeters: false,
                            ),
                          ),
                        )
                      else
                        ArtworkTile(
                          url: displayArtwork,
                          size: 56,
                          borderRadius: AppTheme.cardRadius * 0.65,
                        ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              displayTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              displayArtist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Semantics(
              button: true,
              label: isPlaying ? 'Pause playback' : 'Start playback',
              child: isWindowsClassic
                  ? IconButton(
                      tooltip: isPlaying ? 'Pause' : 'Play',
                      onPressed: () => notifier.togglePlay(),
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 22,
                      ),
                    )
                  : IconButton.filledTonal(
                      style: IconButton.styleFrom(
                        padding: const EdgeInsets.all(14),
                        backgroundColor: isDark
                            ? theme.colorScheme.surfaceContainerHigh
                            : null,
                        foregroundColor:
                            isDark ? theme.colorScheme.onSurface : null,
                      ),
                      tooltip: isPlaying ? 'Pause' : 'Play',
                      onPressed: () => notifier.togglePlay(),
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 28,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
