import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../home/widgets/song_row_tile.dart';
import '../../player/data/music_catalog.dart';
import '../../player/models/song.dart';
import '../../player/providers/app_providers.dart';
import '../../player/providers/player_notifier.dart';
import '../../player/providers/preferences_notifier.dart';
import 'library_folder_screen.dart';

enum _LibraryBrowseMode { categories, folders }

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  _LibraryBrowseMode _browseMode = _LibraryBrowseMode.categories;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catalog = ref.watch(musicCatalogProvider);
    final prefs = ref.watch(preferencesNotifierProvider);
    final local = ref.watch(localLibraryProvider);
    final likedFull = catalog.likedFromIds(prefs.likedSongIds);
    final recentFull =
        catalog.recentlyPlayedFromIds(prefs.recentlyPlayedSongIds);

    return ListView(
      padding: AppSpacing.screenHorizontal.copyWith(
        top: AppSpacing.xl,
        bottom: AppSpacing.section,
      ),
      children: [
        Row(
          children: [
            Expanded(
                child: Text('Library', style: theme.textTheme.headlineSmall)),
            IconButton(
              tooltip: 'Settings',
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.library_music_rounded),
          title: const Text('All music'),
          subtitle: const Text('Sort by genre, title, artist, duration'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.push('/library/all-music'),
        ),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<_LibraryBrowseMode>(
          segments: const [
            ButtonSegment(
              value: _LibraryBrowseMode.categories,
              label: Text('Categories'),
              icon: Icon(Icons.view_list_rounded),
            ),
            ButtonSegment(
              value: _LibraryBrowseMode.folders,
              label: Text('Folders'),
              icon: Icon(Icons.folder_rounded),
            ),
          ],
          emptySelectionAllowed: false,
          showSelectedIcon: false,
          selected: {_browseMode},
          onSelectionChanged: (s) {
            setState(() => _browseMode = s.first);
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        if (catalog.allSongs.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your offline library is empty',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Add local MP3/audio files to start listening with no ads and no account.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      FilledButton.icon(
                        onPressed: kIsWeb
                            ? null
                            : () async {
                                final added = await ref
                                    .read(localLibraryProvider.notifier)
                                    .scanDeviceForMusic();
                                if (!context.mounted) return;
                                final messenger = ScaffoldMessenger.of(context);
                                final text = switch (added) {
                                  -1 =>
                                    'Allow media access in Android settings, then try scan again.',
                                  0 => 'No new tracks found on this device.',
                                  _ =>
                                    'Added $added track${added == 1 ? '' : 's'} from device scan.'
                                };
                                messenger.showSnackBar(
                                    SnackBar(content: Text(text)));
                              },
                        icon: const Icon(Icons.manage_search_rounded),
                        label: const Text('Scan device'),
                      ),
                      OutlinedButton.icon(
                        onPressed: kIsWeb
                            ? null
                            : () async {
                                final added = await ref
                                    .read(localLibraryProvider.notifier)
                                    .importAudioFiles();
                                if (!context.mounted) return;
                                final text = added == 0
                                    ? 'No files imported.'
                                    : 'Imported $added track${added == 1 ? '' : 's'}.';
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(text)),
                                );
                              },
                        icon: const Icon(Icons.upload_file_rounded),
                        label: const Text('Import files'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        else if (_browseMode == _LibraryBrowseMode.folders)
          ..._folderBrowseSlivers(context, catalog, local)
        else ...[
          ExpansionTile(
            initiallyExpanded: true,
            title: _SectionTitleText(
                title: 'Liked songs', count: likedFull.length),
            children: [
              if (likedFull.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, AppSpacing.md),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Songs you like appear here.'),
                  ),
                )
              else
                ...likedFull.take(20).map((s) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SongRowTile(
                        song: s,
                        onSwipeLeftEnqueue: () => ref
                            .read(playerNotifierProvider.notifier)
                            .playNext(s),
                        onTap: () => ref
                            .read(playerNotifierProvider.notifier)
                            .playFromCollection(
                              likedFull,
                              likedFull.indexWhere((x) => x.id == s.id),
                            ),
                      ),
                      const Divider(height: 1, indent: 80),
                    ],
                  );
                }),
            ],
          ),
          ExpansionTile(
            initiallyExpanded: true,
            title: const _SectionTitleText(title: 'Recently played'),
            children: [
              if (recentFull.isEmpty)
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, AppSpacing.md),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Your listening history shows up here.'),
                  ),
                )
              else
                ...recentFull.take(15).map((s) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SongRowTile(
                        song: s,
                        onSwipeLeftEnqueue: () => ref
                            .read(playerNotifierProvider.notifier)
                            .playNext(s),
                        onTap: () => ref
                            .read(playerNotifierProvider.notifier)
                            .playFromCollection(
                              recentFull,
                              recentFull.indexWhere((x) => x.id == s.id),
                            ),
                      ),
                      const Divider(height: 1, indent: 80),
                    ],
                  );
                }),
            ],
          ),
          ExpansionTile(
            initiallyExpanded: false,
            title: _SectionTitleText(
              title: 'Playlists',
              count: catalog.allPlaylists.length,
            ),
            children: [
              ...catalog.allPlaylists.map((p) {
                return ListTile(
                  leading: const Icon(Icons.queue_music_rounded),
                  title: Text(p.title),
                  subtitle: Text('${p.songCount} songs'),
                  onTap: () => context.push('/playlist/${p.id}'),
                );
              }),
            ],
          ),
          ExpansionTile(
            initiallyExpanded: false,
            title: _SectionTitleText(
              title: 'Albums',
              count: catalog.allAlbums.length,
            ),
            children: [
              ...catalog.allAlbums.map((a) {
                final n = catalog.songsForAlbum(a.id).length;
                return ListTile(
                  leading: const Icon(Icons.album_rounded),
                  title: Text(a.title),
                  subtitle: Text(n == 0 ? 'Album' : '$n songs'),
                  onTap: () => context.push('/album/${a.id}'),
                );
              }),
            ],
          ),
          ExpansionTile(
            initiallyExpanded: false,
            title: _SectionTitleText(
              title: 'Artists',
              count: catalog.allArtists.length,
            ),
            children: [
              ...catalog.allArtists.map((a) {
                return ListTile(
                  leading: const Icon(Icons.person_outline_rounded),
                  title: Text(a.name),
                );
              }),
            ],
          ),
        ],
      ],
    );
  }

  List<Widget> _folderBrowseSlivers(
    BuildContext context,
    MusicCatalog catalog,
    List<Song> local,
  ) {
    final theme = Theme.of(context);
    if (local.isEmpty) {
      return [
        Text(
          'Folders group tracks you import or scan on this device. '
          'They are not available on web.',
          style: theme.textTheme.bodyMedium,
        ),
      ];
    }

    final entries = catalog.deviceSongsByFolder.entries.toList()
      ..sort(
        (a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()),
      );

    return [
      Text(
        '${entries.length} folder${entries.length == 1 ? '' : 's'} '
        '(${local.length} track${local.length == 1 ? '' : 's'})',
        style: theme.textTheme.bodySmall,
      ),
      const SizedBox(height: AppSpacing.sm),
      ...entries.map((e) {
        final title = MusicCatalog.folderDisplayTitle(e.key);
        return ListTile(
          leading: const Icon(Icons.folder_rounded),
          title: Text(title),
          subtitle: Text(
            '${e.value.length} track${e.value.length == 1 ? '' : 's'}',
          ),
          onTap: () => context.push(
            '/library/folder',
            extra: LibraryFolderArgs(folderKey: e.key, songs: e.value),
          ),
        );
      }),
    ];
  }
}

class _SectionTitleText extends StatelessWidget {
  const _SectionTitleText({required this.title, this.count});

  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      count != null ? '$title · $count' : title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
