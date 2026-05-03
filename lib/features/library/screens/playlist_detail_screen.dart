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
import '../../playlists/providers/user_playlists_notifier.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  const PlaylistDetailScreen({super.key, required this.playlistId});

  final String playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(musicCatalogProvider);
    final playlist = catalog.playlistById(playlistId);
    if (playlist == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Playlist')),
        bottomNavigationBar: const _RootBottomChrome(selectedIndex: 2),
        body: const Center(child: Text('Playlist not found.')),
      );
    }
    final songs = catalog.songsForPlaylist(playlist);
    final isUserPlaylist = playlist.category == 'User';
    final theme = Theme.of(context);

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
      appBar: AppBar(
        title: Text(playlist.title),
        actions: [
          if (isUserPlaylist)
            IconButton(
              tooltip: 'Add songs',
              onPressed: () async {
                final allSongs = catalog.allSongs;
                final selected = await showModalBottomSheet<String>(
                  context: context,
                  showDragHandle: true,
                  isScrollControlled: true,
                  builder: (ctx) => SafeArea(
                    child: ListView(
                      children: allSongs.map((s) {
                        final inPlaylist = playlist.songIds.contains(s.id);
                        return ListTile(
                          leading: Icon(
                            inPlaylist
                                ? Icons.check_circle_rounded
                                : Icons.add_circle_outline_rounded,
                          ),
                          title: Text(s.title),
                          subtitle: Text(s.artistName),
                          onTap: () => Navigator.pop(ctx, s.id),
                        );
                      }).toList(),
                    ),
                  ),
                );
                if (selected == null) return;
                await ref
                    .read(userPlaylistsProvider.notifier)
                    .addSong(playlist.id, selected);
              },
              icon: const Icon(Icons.playlist_add_rounded),
            ),
        ],
      ),
      bottomNavigationBar: const _RootBottomChrome(selectedIndex: 2),
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
                      url: playlist.coverUrl,
                      size: 220,
                      borderRadius: AppTheme.cardRadius,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    playlist.title,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    playlist.description,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${playlist.songCount} songs',
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
          SliverToBoxAdapter(
            child: isUserPlaylist
                ? ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: songs.length,
                    onReorder: (oldIndex, newIndex) async {
                      var target = newIndex;
                      if (oldIndex < newIndex) target -= 1;
                      await ref
                          .read(userPlaylistsProvider.notifier)
                          .reorderSongs(playlist.id, oldIndex, target);
                    },
                    itemBuilder: (context, i) {
                      final s = songs[i];
                      return SongRowTile(
                        key: ValueKey('${playlist.id}-${s.id}'),
                        song: s,
                        onSwipeLeftEnqueue: () => ref
                            .read(playerNotifierProvider.notifier)
                            .playNext(s),
                        trailing: SizedBox(
                          width: 92,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'Remove from playlist',
                                onPressed: () => ref
                                    .read(userPlaylistsProvider.notifier)
                                    .removeSong(playlist.id, s.id),
                                icon:
                                    const Icon(Icons.remove_circle_outline_rounded),
                              ),
                              ReorderableDragStartListener(
                                index: i,
                                child: const Icon(Icons.drag_handle_rounded),
                              ),
                            ],
                          ),
                        ),
                        onTap: () => ref
                            .read(playerNotifierProvider.notifier)
                            .playFromCollection(songs, i),
                      );
                    },
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: songs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
                    itemBuilder: (context, i) {
                      final s = songs[i];
                      return SongRowTile(
                        song: s,
                        onSwipeLeftEnqueue: () => ref
                            .read(playerNotifierProvider.notifier)
                            .playNext(s),
                        onTap: () => ref
                            .read(playerNotifierProvider.notifier)
                            .playFromCollection(songs, i),
                      );
                    },
                  ),
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
