import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../core/widgets/artwork_tile.dart';
import '../../player/models/discovered_recording.dart';
import '../../player/widgets/song_streaming_links.dart';
import '../providers/discover_feed_notifier.dart';

class DiscoverMusicStrip extends ConsumerStatefulWidget {
  const DiscoverMusicStrip({super.key});

  @override
  ConsumerState<DiscoverMusicStrip> createState() =>
      _DiscoverMusicStripState();
}

class _DiscoverMusicStripState extends ConsumerState<DiscoverMusicStrip> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final cur = ref.read(discoverFeedNotifierProvider);
      if (cur.items.isEmpty && !cur.loading) {
        ref.read(discoverFeedNotifierProvider.notifier).loadInitial();
      }
    });
  }

  void _listenSheet(BuildContext context, DiscoveredRecording d) {
    final theme = Theme.of(context);
    final song = d.toOutboundSong();
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm,
              AppSpacing.md, AppSpacing.md + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ArtworkTile(
                url: d.artworkUrl,
                size: 112,
                borderRadius: AppTheme.cardRadius,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                d.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                d.artistName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SongStreamingLinks(
                song: song,
                includeAppleMusic: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const double _cardWidth = 152;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoverFeedNotifierProvider);
    final theme = Theme.of(context);
    final hPad = horizontalPaddingForWidth(MediaQuery.sizeOf(context).width);

    if (state.loading && state.items.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: AppSpacing.md),
        child: SizedBox(
          height: 240,
          child: Center(
            child: CircularProgressIndicator(
              color: theme.colorScheme.primary,
              strokeWidth: 2,
            ),
          ),
        ),
      );
    }

    if (state.error != null && state.items.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            TextButton(
              onPressed: () => ref.read(discoverFeedNotifierProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.items.isEmpty) {
      return const SizedBox.shrink();
    }

    final items = state.items;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Text(
            'MusicBrainz catalogue — open in Spotify, YouTube Music, Apple Music, and YouTube.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 252,
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (state.loadingMore ||
                  state.loading ||
                  !state.hasMore) {
                return false;
              }
              final m = n.metrics;
              if (m.pixels >= m.maxScrollExtent - 280) {
                ref.read(discoverFeedNotifierProvider.notifier).loadMore();
              }
              return false;
            },
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              scrollDirection: Axis.horizontal,
              itemCount: items.length + (state.loadingMore ? 1 : 0),
              itemBuilder: (context, i) {
                if (i >= items.length) {
                  return const Padding(
                    padding: EdgeInsets.only(left: AppSpacing.sm, right: AppSpacing.sm),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                final d = items[i];
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Material(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _listenSheet(context, d),
                      child: SizedBox(
                        width: _cardWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ArtworkTile(
                              url: d.artworkUrl,
                              size: _cardWidth,
                              borderRadius: AppTheme.cardRadius,
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.sm,
                                  AppSpacing.sm,
                                  AppSpacing.sm,
                                  AppSpacing.xs,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      d.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        height: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      d.artistName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        height: 1.15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (state.error != null && state.items.isNotEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(hPad, AppSpacing.xs, hPad, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    state.error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => ref.read(discoverFeedNotifierProvider.notifier).loadMore(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
