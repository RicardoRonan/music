import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/greeting_util.dart';
import '../../../core/utils/responsive_layout.dart';
import '../../../core/widgets/section_header.dart';
import '../../player/providers/app_providers.dart';
import '../../player/providers/player_notifier.dart';
import '../../player/providers/preferences_notifier.dart';
import '../../player/widgets/library_scan_progress_dialog.dart';
import '../widgets/discover_music_strip.dart';
import '../widgets/playlist_strip_card.dart';
import '../widgets/song_row_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(musicCatalogProvider);
    final prefs = ref.watch(preferencesNotifierProvider);
    final mq = MediaQuery.of(context);
    final greetingSize = homeGreetingSizeForWidth(mq.size.width);
    final greeting = greetingForNow(DateTime.now());

    final recentFull =
        catalog.recentlyPlayedFromIds(prefs.recentlyPlayedSongIds);
    final recommended = catalog.recommendedForYou();
    final stripPlaylists =
        catalog.allPlaylists.where((p) => p.id != 'pl_recent').toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPaddingForWidth(mq.size.width),
              AppSpacing.xl,
              horizontalPaddingForWidth(mq.size.width),
              AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Listen calmly',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: greetingSize,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSpacing.lg),
                TextField(
                  readOnly: true,
                  onTap: () => context.go('/search'),
                  decoration: const InputDecoration(
                    hintText: 'Search songs, albums, artists',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                if (catalog.allSongs.isEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No music in your library yet',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            kIsWeb
                                ? 'Choose MP3 or other audio files from your computer to play in the browser.'
                                : 'Import your local MP3 files or run a device scan to start offline playback.',
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              if (!kIsWeb)
                                FilledButton.icon(
                                  onPressed: () async {
                                    final added =
                                        await runDeviceMusicScanWithProgressDialog(
                                      context,
                                      ref,
                                    );
                                    if (!context.mounted) return;
                                    final isWindows = !kIsWeb &&
                                        defaultTargetPlatform ==
                                            TargetPlatform.windows;
                                    final message = switch (added) {
                                      -1 =>
                                        'Allow audio/media access in Android settings, then scan again.',
                                      0 => isWindows
                                          ? 'No audio in your Music folder. Try Choose folder…'
                                          : 'No new music found on this device yet.',
                                      _ => isWindows
                                          ? 'Added $added track${added == 1 ? '' : 's'} from your Music folder.'
                                          : 'Added $added track${added == 1 ? '' : 's'} from your device.'
                                    };
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(message)),
                                    );
                                  },
                                  icon: const Icon(Icons.manage_search_rounded),
                                  label: Text(
                                    !kIsWeb &&
                                            defaultTargetPlatform ==
                                                TargetPlatform.windows
                                        ? 'Scan Music folder'
                                        : 'Scan device',
                                  ),
                                ),
                              if (!kIsWeb &&
                                  defaultTargetPlatform ==
                                      TargetPlatform.windows)
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final added = await ref
                                        .read(localLibraryProvider.notifier)
                                        .pickMusicFolderAndScan();
                                    if (!context.mounted) return;
                                    final message = added == 0
                                        ? 'No files in that folder (or picker cancelled).'
                                        : 'Added $added track${added == 1 ? '' : 's'}.';
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(message)),
                                    );
                                  },
                                  icon: const Icon(Icons.folder_open_rounded),
                                  label: const Text('Choose folder…'),
                                ),
                              FilledButton.icon(
                                onPressed: () async {
                                  final added = await ref
                                      .read(localLibraryProvider.notifier)
                                      .importAudioFiles();
                                  if (!context.mounted) return;
                                  final message = added == 0
                                      ? (kIsWeb
                                          ? 'No files chosen (or picker was cancelled).'
                                          : 'No files imported.')
                                      : 'Imported $added track${added == 1 ? '' : 's'}.';
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(message)),
                                  );
                                },
                                icon: const Icon(Icons.upload_file_rounded),
                                label: Text(
                                  kIsWeb ? 'Choose music files' : 'Import files',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: SectionHeader(title: 'Your playlists'),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 264,
            child: ListView.builder(
              padding: AppSpacing.screenHorizontal,
              scrollDirection: Axis.horizontal,
              itemCount: stripPlaylists.length,
              itemBuilder: (context, i) =>
                  PlaylistStripCard(playlist: stripPlaylists[i]),
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: SectionHeader(title: 'Discover new music'),
        ),
        const SliverToBoxAdapter(
          child: DiscoverMusicStrip(),
        ),
        if (recentFull.isNotEmpty) ...[
          const SliverToBoxAdapter(
              child: SectionHeader(title: 'Recently played')),
          SliverList.separated(
            itemCount: recentFull.length.clamp(0, 6),
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 80),
            itemBuilder: (context, i) {
              final s = recentFull[i];
              return SongRowTile(
                song: s,
                onSwipeLeftEnqueue: () =>
                    ref.read(playerNotifierProvider.notifier).playNext(s),
                onTap: () => ref
                    .read(playerNotifierProvider.notifier)
                    .playFromCollection(
                      recentFull,
                      recentFull.indexWhere((x) => x.id == s.id),
                    ),
              );
            },
          ),
        ],
        const SliverToBoxAdapter(
            child: SectionHeader(title: 'Recommended for you')),
        SliverList.separated(
          itemCount: recommended.length.clamp(0, 8),
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 80),
          itemBuilder: (context, i) {
            final s = recommended[i];
            return SongRowTile(
              song: s,
              onSwipeLeftEnqueue: () =>
                  ref.read(playerNotifierProvider.notifier).playNext(s),
              onTap: () =>
                  ref.read(playerNotifierProvider.notifier).playFromCollection(
                        recommended,
                        i,
                      ),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.section)),
      ],
    );
  }
}
