import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../just_audio_import.dart';

import '../../../app/theme.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/duration_format.dart';
import '../../../core/utils/track_title_sanitize.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/artwork_tile.dart';
import '../models/playback_state.dart';
import '../models/song.dart';
import '../providers/player_notifier.dart';
import '../widgets/track_swipe_surface.dart';
import '../providers/preferences_notifier.dart';
import '../providers/track_metadata_providers.dart';
import '../widgets/song_streaming_links.dart';

class NowPlayingScreen extends ConsumerWidget {
  const NowPlayingScreen({super.key, this.showBackButton = true});

  final bool showBackButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final song = ref.watch(playerNotifierProvider.select((p) => p.currentSong));
    final prefs = ref.watch(preferencesNotifierProvider);
    final theme = Theme.of(context);
    final notifier = ref.read(playerNotifierProvider.notifier);

    if (song == null) {
      return Scaffold(
        appBar: AppBar(leading: showBackButton ? const BackButton() : null),
        body: const Center(child: Text('Nothing playing')),
      );
    }

    final liked = prefs.likedSongIds.contains(song.id);
    final enrichKey = TrackEnrichmentKey.fromSong(song);
    final enrichAsync = ref.watch(trackEnrichmentProvider(enrichKey));
    final enriched = enrichAsync.valueOrNull;

    final displayTitle = enriched?.title ??
        (song.isLocalFile ? sanitizeTrackTitleForSearch(song.title) : song.title);
    final displayArtist = enriched?.artistName ??
        (song.isLocalFile
            ? sanitizeTrackTitleForSearch(song.artistName)
            : song.artistName);
    final displayAlbum = enriched?.albumTitle ??
        (song.isLocalFile
            ? sanitizeTrackTitleForSearch(song.albumTitle)
            : song.albumTitle);
    final displayArtwork = enriched?.artworkUrl ?? song.artworkUrl;

    final musicBrainzRecordingUrl = enriched?.musicBrainzRecordingUrl;
    final isDark = theme.brightness == Brightness.dark;
    final transportCircleFill = isDark
        ? theme.colorScheme.surfaceContainerHigh
        : theme.colorScheme.primary;
    final transportCircleOnFill = isDark
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onPrimary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: showBackButton ? const BackButton() : null,
        title: const Text('Now playing'),
        actions: [
          if (musicBrainzRecordingUrl != null)
            Semantics(
              button: true,
              label: 'MusicBrainz and cover art',
              child: IconButton(
                tooltip: 'MusicBrainz and cover art',
                icon: const Icon(Icons.info_outline_rounded),
                onPressed: () => _showMusicBrainzInfoSheet(
                  context,
                  theme,
                  musicBrainzRecordingUrl,
                ),
              ),
            ),
          PopupMenuButton<void>(
            tooltip: 'Track details',
            icon: const Icon(Icons.more_vert_rounded),
            itemBuilder: (_) => nowPlayingTrackDetailsMenuEntries(
              context: context,
              theme: theme,
              song: song,
              displayArtist: displayArtist,
              displayAlbum: displayAlbum,
              searchTitle: enriched?.title,
              searchArtist: enriched?.artistName,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Material(
        color: theme.colorScheme.surfaceContainerHigh,
        elevation: 3,
        shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.2),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: theme.colorScheme.onSurface,
                      side: BorderSide(
                        color: theme.colorScheme.outline,
                        width: 1.5,
                      ),
                    ),
                    onPressed: () => context.push('/queue'),
                    icon: const Icon(Icons.queue_music_rounded, size: 26),
                    label: const Text('Queue'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: liked
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                      side: BorderSide(
                        color: liked
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline,
                        width: 1.5,
                      ),
                    ),
                    onPressed: () => notifier.toggleLikeCurrent(),
                    icon: Icon(
                      liked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 26,
                    ),
                    label: Text(liked ? 'Liked' : 'Like'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: AppSpacing.screenHorizontal,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bodyW = constraints.maxWidth;
            final bodyH = constraints.maxHeight;
            // Reserve vertical space for slider, timestamps, transport row, and gaps.
            const controlStripReserve = 280.0;
            final titleReserve = theme.textTheme.titleLarge?.fontSize != null
                ? theme.textTheme.titleLarge!.fontSize! * 2.6 + AppSpacing.lg
                : 72.0;
            final maxSquareByHeight =
                bodyH - controlStripReserve - titleReserve - AppSpacing.xs;
            final artSide = math
                .min(bodyW * 0.88, math.max(1.0, maxSquareByHeight))
                .clamp(1.0, bodyW);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: TrackSwipeSurface(
                    skipNext: notifier.skipNext,
                    skipPrevious: notifier.skipPrevious,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragEnd: (details) {
                        final v = details.primaryVelocity ?? 0;
                        if (v > 420 && context.mounted) {
                          context.pop();
                        }
                      },
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Hero(
                              tag: 'artwork-${song.id}',
                              child: ArtworkTile(
                                url: displayArtwork,
                                size: artSide,
                                borderRadius: AppTheme.cardRadius * 1.25,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                              ),
                              child: Text(
                                displayTitle,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _NowPlayingSeekBlock(song: song, theme: theme),
                const SizedBox(height: AppSpacing.lg),
                _NowPlayingTransportRow(
                  theme: theme,
                  transportCircleFill: transportCircleFill,
                  transportCircleOnFill: transportCircleOnFill,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Only this subtree rebuilds on each [positionStream] tick — not the artwork
/// / metadata / enrichment chain above.
class _NowPlayingSeekBlock extends ConsumerStatefulWidget {
  const _NowPlayingSeekBlock({
    required this.song,
    required this.theme,
  });

  final Song song;
  final ThemeData theme;

  @override
  ConsumerState<_NowPlayingSeekBlock> createState() =>
      _NowPlayingSeekBlockState();
}

class _NowPlayingSeekBlockState extends ConsumerState<_NowPlayingSeekBlock> {
  bool _volumePopupVisible = false;
  Timer? _volumeDismissTimer;

  @override
  void dispose() {
    _volumeDismissTimer?.cancel();
    super.dispose();
  }

  IconData _volumeIcon(double volume) {
    if (volume <= 0.001) return Icons.volume_off_rounded;
    if (volume < 0.35) return Icons.volume_mute_rounded;
    if (volume < 0.7) return Icons.volume_down_rounded;
    return Icons.volume_up_rounded;
  }

  void _hideVolumePopup() {
    _volumeDismissTimer?.cancel();
    if (_volumePopupVisible) {
      setState(() => _volumePopupVisible = false);
    }
  }

  void _toggleVolumePopup() {
    if (_volumePopupVisible) {
      _hideVolumePopup();
      return;
    }
    setState(() => _volumePopupVisible = true);
    _resetVolumeDismissTimer();
  }

  void _resetVolumeDismissTimer() {
    _volumeDismissTimer?.cancel();
    _volumeDismissTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) _hideVolumePopup();
    });
  }

  void _onVolumeSliderChanged(double value, PlayerNotifier notifier) {
    _resetVolumeDismissTimer();
    notifier.setVolume(value);
  }

  @override
  Widget build(BuildContext context) {
    final snap = ref.watch(
      playerNotifierProvider.select(
        (p) => (
          p.position,
          p.duration,
          p.processingState,
          p.errorMessage,
          p.volume,
        ),
      ),
    );
    final (position, duration, processingState, errorMessage, volume) = snap;
    final notifier = ref.read(playerNotifierProvider.notifier);
    final theme = widget.theme;
    final colorScheme = theme.colorScheme;

    final effectiveDuration =
        duration.inMilliseconds > 0 ? duration : widget.song.duration;
    final maxMs = effectiveDuration.inMilliseconds > 0
        ? effectiveDuration.inMilliseconds.toDouble()
        : 1.0;
    final posMs =
        position.inMilliseconds.clamp(0, maxMs.round()).toDouble();

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (processingState == AppProcessingState.loading)
              const Center(child: AppLoader.small())
            else if (errorMessage != null)
              Text(
                errorMessage,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.error,
                ),
              ),
            if (processingState == AppProcessingState.loading ||
                errorMessage != null)
              const SizedBox(height: AppSpacing.sm),
            Slider(
              value: posMs,
              max: maxMs,
              onChanged: (v) {
                notifier.seekTo(Duration(milliseconds: v.round()));
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xs,
                AppSpacing.xs,
                AppSpacing.xs,
                AppSpacing.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatTrackDuration(position)),
                  Text(formatTrackDuration(effectiveDuration)),
                ],
              ),
            ),
          ],
        ),
        if (_volumePopupVisible)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _hideVolumePopup,
              child: const SizedBox.expand(),
            ),
          ),
        if (_volumePopupVisible)
          Positioned(
            left: AppSpacing.xs,
            right: 52,
            bottom: 52,
            child: Material(
              elevation: 6,
              shadowColor: colorScheme.shadow.withValues(alpha: 0.22),
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  AppSpacing.xs,
                  AppSpacing.sm,
                  AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Icon(
                      _volumeIcon(volume),
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    Expanded(
                      child: Slider(
                        value: volume.clamp(0.0, 1.0),
                        onChanged: (v) => _onVolumeSliderChanged(v, notifier),
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${(volume * 100).round()}%',
                        textAlign: TextAlign.end,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Positioned(
          right: 0,
          bottom: 44,
          child: Semantics(
            button: true,
            label: _volumePopupVisible ? 'Hide volume' : 'Show volume',
            child: IconButton(
              tooltip: _volumePopupVisible ? 'Hide volume' : 'Volume',
              iconSize: 22,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: _toggleVolumePopup,
              icon: Icon(_volumeIcon(volume)),
            ),
          ),
        ),
      ],
    );
  }
}

class _NowPlayingTransportRow extends ConsumerWidget {
  const _NowPlayingTransportRow({
    required this.theme,
    required this.transportCircleFill,
    required this.transportCircleOnFill,
  });

  final ThemeData theme;
  final Color transportCircleFill;
  final Color transportCircleOnFill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(
      playerNotifierProvider.select(
        (p) => (p.shuffleEnabled, p.isPlaying, p.loopMode),
      ),
    );
    final (shuffleEnabled, isPlaying, loopMode) = snap;
    final notifier = ref.read(playerNotifierProvider.notifier);

    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                button: true,
                label: 'Toggle shuffle',
                child: IconButton(
                  tooltip: 'Shuffle',
                  iconSize: 24,
                  color: shuffleEnabled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.secondary,
                  onPressed: () => notifier.toggleShuffle(),
                  icon: const Icon(Icons.shuffle_rounded),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Semantics(
                button: true,
                label: 'Play previous track',
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: transportCircleFill,
                    foregroundColor: transportCircleOnFill,
                    padding: const EdgeInsets.all(16),
                  ),
                  iconSize: 32,
                  tooltip: 'Previous track',
                  onPressed: () => notifier.skipPrevious(),
                  icon: const Icon(Icons.skip_previous_rounded),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Semantics(
                button: true,
                label: isPlaying ? 'Pause playback' : 'Start playback',
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: transportCircleFill,
                    foregroundColor: transportCircleOnFill,
                    padding: const EdgeInsets.all(20),
                  ),
                  iconSize: 36,
                  tooltip: isPlaying ? 'Pause' : 'Play',
                  onPressed: () => notifier.togglePlay(),
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Semantics(
                button: true,
                label: 'Play next track',
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: transportCircleFill,
                    foregroundColor: transportCircleOnFill,
                    padding: const EdgeInsets.all(16),
                  ),
                  iconSize: 32,
                  tooltip: 'Next track',
                  onPressed: () => notifier.skipNext(),
                  icon: const Icon(Icons.skip_next_rounded),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Semantics(
                button: true,
                label: 'Change repeat mode',
                child: IconButton(
                  tooltip: 'Repeat',
                  iconSize: 24,
                  color: loopMode == LoopMode.off
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.primary,
                  onPressed: () => notifier.cycleRepeat(),
                  icon: Icon(
                    loopMode == LoopMode.one
                        ? Icons.repeat_one_rounded
                        : Icons.repeat_rounded,
                  ),
                ),
              ),
            ],
        ),
      ),
    );
  }
}

Future<void> _showMusicBrainzInfoSheet(
  BuildContext context,
  ThemeData theme,
  String musicBrainzRecordingUrl,
) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Sources', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(
              'Album art from Cover Art Archive when available',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () async {
                final u = Uri.parse(musicBrainzRecordingUrl);
                final ok = await launchUrl(
                  u,
                  mode: LaunchMode.externalApplication,
                );
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                }
                if (!context.mounted) return;
                if (!ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not open link.')),
                  );
                }
              },
              icon: const Icon(Icons.open_in_new_rounded, size: 20),
              label: const Text('View on MusicBrainz'),
            ),
          ],
        ),
      ),
    ),
  );
}
