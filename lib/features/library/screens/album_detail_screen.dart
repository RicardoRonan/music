import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/artwork_tile.dart';
import '../../../shared/widgets/app_bottom_bar.dart';
import '../../home/widgets/song_row_tile.dart';
import '../../player/providers/app_providers.dart';
import '../../player/providers/player_notifier.dart';
import '../../player/widgets/full_screen_mini_player_strip.dart';

class AlbumDetailScreen extends ConsumerWidget {
  const AlbumDetailScreen({super.key, required this.albumId});

  final String albumId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(musicCatalogProvider);
    final album = catalog.albumById(albumId);
    if (album == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Album')),
        bottomNavigationBar: const _RootBottomChrome(selectedIndex: 0),
        body: const Center(child: Text('Album not found.')),
      );
    }
    final songs = catalog.songsForAlbum(albumId);
    final theme = Theme.of(context);
    final subtitle = songs.isEmpty
        ? 'No tracks'
        : (() {
            final names = songs.map((s) => s.artistName).toSet();
            if (names.length == 1) return names.first;
            return '${names.length} artists';
          })();

    Future<void> playAll({required bool shuffle}) async {
      if (songs.isEmpty) return;
      final n = ref.read(playerNotifierProvider.notifier);
      if (shuffle && songs.length > 1) {
        await n.playFromCollection(songs, math.Random().nextInt(songs.length));
      } else {
        await n.playQueue(songs, startIndex: 0);
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(album.title)),
      bottomNavigationBar: const _RootBottomChrome(selectedIndex: 0),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.screenHorizontal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: ArtworkTile(
                      url: album.artworkUrl,
                      size: 200,
                      borderRadius: AppTheme.cardRadius,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(album.title, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(subtitle, style: theme.textTheme.bodyMedium),
                  if (album.year != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text('${album.year}', style: theme.textTheme.bodySmall),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${songs.length} songs',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: songs.isEmpty
                              ? null
                              : () => playAll(shuffle: true),
                          icon: const Icon(Icons.shuffle_rounded),
                          label: const Text('Shuffle'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: songs.isEmpty
                              ? null
                              : () => playAll(shuffle: false),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Play'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
          SliverList.separated(
            itemCount: songs.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 80),
            itemBuilder: (context, i) {
              final s = songs[i];
              return SongRowTile(
                song: s,
                trailing: Text(
                  '${i + 1}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                onSwipeLeftEnqueue: () => ref
                    .read(playerNotifierProvider.notifier)
                    .playNext(s),
                onTap: () => ref
                    .read(playerNotifierProvider.notifier)
                    .playFromCollection(songs, i),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.section)),
        ],
      ),
    );
  }
}

class _RootBottomChrome extends StatelessWidget {
  const _RootBottomChrome({required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const FullScreenMiniPlayerStrip(),
        AppBottomBar(selectedIndex: selectedIndex),
      ],
    );
  }
}
