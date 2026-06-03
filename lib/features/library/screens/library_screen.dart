import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/windows_classic_ui.dart';
import '../../../theme/windows_classic_theme_extension.dart';
import '../../home/widgets/song_row_tile.dart';
import '../../player/data/music_catalog.dart';
import '../../player/models/song.dart';
import '../../player/providers/app_providers.dart';
import '../../player/providers/player_notifier.dart';
import '../../player/providers/preferences_notifier.dart';
import '../../player/widgets/library_scan_progress_dialog.dart';
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

    if (context.isWindowsClassicTheme) {
      return ListView(
        padding: AppSpacing.screenHorizontal.copyWith(
          top: AppSpacing.md,
          bottom: AppSpacing.section,
        ),
        children: [
          _buildClassicLibraryShell(
            context: context,
            theme: theme,
            catalog: catalog,
            local: local,
            likedFull: likedFull,
            recentFull: recentFull,
          ),
        ],
      );
    }

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
                    !kIsWeb &&
                            defaultTargetPlatform == TargetPlatform.windows
                        ? 'Scan your Windows Music folder or import files manually.'
                        : 'Add local MP3/audio files to start listening with no ads and no account.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      if (!kIsWeb)
                        FilledButton.icon(
                          onPressed: () async {
                            final added = await runDeviceMusicScanWithProgressDialog(
                              context,
                              ref,
                            );
                            if (!context.mounted) return;
                            final messenger = ScaffoldMessenger.of(context);
                            final isWindows = !kIsWeb &&
                                defaultTargetPlatform ==
                                    TargetPlatform.windows;
                            final text = switch (added) {
                              -1 =>
                                'Allow media access in Android settings, then try scan again.',
                              0 => isWindows
                                  ? 'No audio found in your Music folder. Try choosing a different folder.'
                                  : 'No new tracks found on this device.',
                              _ => isWindows
                                  ? 'Added $added track${added == 1 ? '' : 's'} from your Music folder.'
                                  : 'Added $added track${added == 1 ? '' : 's'} from device scan.'
                            };
                            messenger.showSnackBar(SnackBar(content: Text(text)));
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
                          defaultTargetPlatform == TargetPlatform.windows)
                        OutlinedButton.icon(
                          onPressed: () async {
                            final added = await ref
                                .read(localLibraryProvider.notifier)
                                .pickMusicFolderAndScan();
                            if (!context.mounted) return;
                            final text = added == 0
                                ? 'No files found in that folder (or picker was cancelled).'
                                : 'Added $added track${added == 1 ? '' : 's'}.';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(text)),
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
                          final text = added == 0
                              ? (kIsWeb
                                  ? 'No files chosen (or picker was cancelled).'
                                  : 'No files imported.')
                              : 'Imported $added track${added == 1 ? '' : 's'}.';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(text)),
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
    final classic = context.isWindowsClassicTheme;

    if (local.isEmpty) {
      const message =
          'Folders group tracks you import or scan on this device. '
          'They are not available on web.';
      if (classic) {
        return const [_ClassicEmptyHint(message)];
      }
      return [
        Text(message, style: theme.textTheme.bodyMedium),
      ];
    }

    final entries = catalog.deviceSongsByFolder.entries.toList()
      ..sort(
        (a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()),
      );

    final summary = Text(
      '${entries.length} folder${entries.length == 1 ? '' : 's'} '
      '(${local.length} track${local.length == 1 ? '' : 's'})',
      style: theme.textTheme.bodySmall,
    );

    final rows = entries.map((e) {
      final title = MusicCatalog.folderDisplayTitle(e.key);
      final subtitle =
          '${e.value.length} track${e.value.length == 1 ? '' : 's'}';
      final onTap = () => context.push(
            '/library/folder',
            extra: LibraryFolderArgs(folderKey: e.key, songs: e.value),
          );

      if (classic) {
        return WindowsClassicListRow(
          icon: Icons.folder,
          title: title,
          subtitle: subtitle,
          onTap: onTap,
        );
      }

      return ListTile(
        leading: const Icon(Icons.folder_rounded),
        title: Text(title),
        subtitle: Text(subtitle),
        onTap: onTap,
      );
    });

    return [
      if (classic)
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
          child: DefaultTextStyle(
            style: theme.textTheme.bodySmall!,
            child: summary,
          ),
        )
      else ...[
        summary,
        const SizedBox(height: AppSpacing.sm),
      ],
      ...rows,
    ];
  }

  Widget _buildClassicLibraryShell({
    required BuildContext context,
    required ThemeData theme,
    required MusicCatalog catalog,
    required List<Song> local,
    required List<Song> likedFull,
    required List<Song> recentFull,
  }) {
    final browseChildren = catalog.allSongs.isEmpty
        ? [_buildClassicEmptyLibrary(context, theme)]
        : [
            WindowsClassicListPanel(
              child: _browseMode == _LibraryBrowseMode.folders
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _folderBrowseSlivers(context, catalog, local),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _categoryBrowseSections(
                        context,
                        catalog,
                        likedFull,
                        recentFull,
                      ),
                    ),
            ),
          ];

    return WindowsClassicOutsetBorder(
      child: WindowsClassicInsetBorder(
        color: context.winColors.chrome,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: WindowsClassicThemeExtension.navy,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Library',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tahoma',
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 22,
                    height: 18,
                    child: GestureDetector(
                      onTap: () => context.push('/settings'),
                      child: const Icon(
                        Icons.settings,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            WindowsClassicListRow(
              icon: Icons.library_music,
              title: 'All music',
              subtitle: 'Sort by genre, title, artist, duration',
              onTap: () => context.push('/library/all-music'),
            ),
            WindowsClassicTabRow(
              tabs: const ['Categories', 'Folders'],
              activeIndex:
                  _browseMode == _LibraryBrowseMode.categories ? 0 : 1,
              onTabSelected: (index) {
                setState(() {
                  _browseMode = index == 0
                      ? _LibraryBrowseMode.categories
                      : _LibraryBrowseMode.folders;
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: browseChildren,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassicEmptyLibrary(BuildContext context, ThemeData theme) {
    return WindowsClassicInsetBorder(
      color: context.winColors.panel,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your offline library is empty',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            !kIsWeb && defaultTargetPlatform == TargetPlatform.windows
                ? 'Scan your Windows Music folder or import files manually.'
                : 'Add local MP3/audio files to start listening with no ads and no account.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (!kIsWeb)
                WindowsClassicButton(
                  onPressed: () async {
                    final added = await runDeviceMusicScanWithProgressDialog(
                      context,
                      ref,
                    );
                    if (!context.mounted) return;
                    _showClassicScanSnack(context, added);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.manage_search, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        !kIsWeb &&
                                defaultTargetPlatform == TargetPlatform.windows
                            ? 'Scan Music folder'
                            : 'Scan device',
                      ),
                    ],
                  ),
                ),
              if (!kIsWeb &&
                  defaultTargetPlatform == TargetPlatform.windows)
                WindowsClassicButton(
                  onPressed: () async {
                    final added = await ref
                        .read(localLibraryProvider.notifier)
                        .pickMusicFolderAndScan();
                    if (!context.mounted) return;
                    final text = added == 0
                        ? 'No files found in that folder (or picker was cancelled).'
                        : 'Added $added track${added == 1 ? '' : 's'}.';
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(text)));
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.folder_open, size: 14),
                      SizedBox(width: 4),
                      Text('Choose folder…'),
                    ],
                  ),
                ),
              WindowsClassicButton(
                onPressed: () async {
                  final added =
                      await ref.read(localLibraryProvider.notifier).importAudioFiles();
                  if (!context.mounted) return;
                  final text = added == 0
                      ? (kIsWeb
                          ? 'No files chosen (or picker was cancelled).'
                          : 'No files imported.')
                      : 'Imported $added track${added == 1 ? '' : 's'}.';
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(text)));
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.upload_file, size: 14),
                    const SizedBox(width: 4),
                    Text(kIsWeb ? 'Choose music files' : 'Import files'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showClassicScanSnack(BuildContext context, int added) {
    final isWindows =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
    final text = switch (added) {
      -1 =>
        'Allow media access in Android settings, then try scan again.',
      0 => isWindows
          ? 'No audio found in your Music folder. Try choosing a different folder.'
          : 'No new tracks found on this device.',
      _ => isWindows
          ? 'Added $added track${added == 1 ? '' : 's'} from your Music folder.'
          : 'Added $added track${added == 1 ? '' : 's'} from device scan.',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  List<Widget> _categoryBrowseSections(
    BuildContext context,
    MusicCatalog catalog,
    List<Song> likedFull,
    List<Song> recentFull,
  ) {
    return [
      WindowsClassicCollapsibleSection(
        initiallyExpanded: true,
        title: 'Liked songs',
        count: likedFull.length,
        children: likedFull.isEmpty
            ? const [_ClassicEmptyHint('Songs you like appear here.')]
            : _classicSongRows(likedFull, likedFull),
      ),
      WindowsClassicCollapsibleSection(
        initiallyExpanded: true,
        title: 'Recently played',
        children: recentFull.isEmpty
            ? const [_ClassicEmptyHint('Your listening history shows up here.')]
            : _classicSongRows(recentFull, recentFull, limit: 15),
      ),
      WindowsClassicCollapsibleSection(
        title: 'Playlists',
        count: catalog.allPlaylists.length,
        children: catalog.allPlaylists
            .map(
              (p) => WindowsClassicListRow(
                icon: Icons.queue_music,
                title: p.title,
                subtitle: '${p.songCount} songs',
                onTap: () => context.push('/playlist/${p.id}'),
              ),
            )
            .toList(),
      ),
      WindowsClassicCollapsibleSection(
        title: 'Albums',
        count: catalog.allAlbums.length,
        children: catalog.allAlbums.map((a) {
          final n = catalog.songsForAlbum(a.id).length;
          return WindowsClassicListRow(
            icon: Icons.album,
            title: a.title,
            subtitle: n == 0 ? 'Album' : '$n songs',
            onTap: () => context.push('/album/${a.id}'),
          );
        }).toList(),
      ),
      WindowsClassicCollapsibleSection(
        title: 'Artists',
        count: catalog.allArtists.length,
        children: catalog.allArtists
            .map(
              (a) => WindowsClassicListRow(
                icon: Icons.person_outline,
                title: a.name,
                onTap: () {},
              ),
            )
            .toList(),
      ),
    ];
  }

  List<Widget> _classicSongRows(
    List<Song> visible,
    List<Song> queue, {
    int limit = 20,
  }) {
    return visible.take(limit).map((s) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SongRowTile(
            song: s,
            onSwipeLeftEnqueue: () =>
                ref.read(playerNotifierProvider.notifier).playNext(s),
            onTap: () => ref.read(playerNotifierProvider.notifier).playFromCollection(
                  queue,
                  queue.indexWhere((x) => x.id == s.id),
                ),
          ),
          const Divider(height: 1, indent: 80),
        ],
      );
    }).toList();
  }
}

class _ClassicEmptyHint extends StatelessWidget {
  const _ClassicEmptyHint(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          message,
          style: TextStyle(
            fontSize: 11,
            fontFamily: 'Tahoma',
            color: context.winColors.onSurface,
          ),
        ),
      ),
    );
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
