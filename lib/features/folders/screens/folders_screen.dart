import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/windows_classic_ui.dart';
import '../../../theme/windows_classic_theme_extension.dart';
import '../../player/data/music_catalog.dart';
import '../../player/providers/app_providers.dart';
import '../../player/widgets/library_scan_progress_dialog.dart';
import '../../library/screens/library_folder_screen.dart';

class FoldersScreen extends ConsumerWidget {
  const FoldersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final catalog = ref.watch(musicCatalogProvider);
    final local = ref.watch(localLibraryProvider);
    final folders = catalog.deviceSongsByFolder.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));

    if (context.isWindowsClassicTheme) {
      return ListView(
        padding: AppSpacing.screenHorizontal.copyWith(
          top: AppSpacing.md,
          bottom: AppSpacing.section,
        ),
        children: [
          WindowsClassicOutsetBorder(
            child: WindowsClassicInsetBorder(
              color: context.winColors.chrome,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    color: WindowsClassicThemeExtension.navy,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: const Text(
                      'Folders',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tahoma',
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(6, 6, 6, 4),
                    child: Text(
                      'Browse music by your file structure.',
                      style: TextStyle(
                        fontSize: 11,
                        fontFamily: 'Tahoma',
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: local.isEmpty
                        ? _ClassicEmptyFolders(
                            onScan: () => _rescan(context, ref),
                          )
                        : WindowsClassicListPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(4, 4, 4, 6),
                                  child: Text(
                                    '${folders.length} folders · ${local.length} songs',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                                ...folders.map((entry) {
                                  final songs = entry.value;
                                  final first = songs.first;
                                  return WindowsClassicListRow(
                                    icon: Icons.folder,
                                    title: MusicCatalog.folderDisplayTitle(
                                      entry.key,
                                    ),
                                    subtitle:
                                        '${songs.length} songs · ${first.artistName}',
                                    onTap: () => context.push(
                                      '/library/folder',
                                      extra: LibraryFolderArgs(
                                        folderKey: entry.key,
                                        songs: songs,
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
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
        Text('Folders', style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Browse music by your file structure.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (local.isEmpty)
          _EmptyFolders(onScan: () => _rescan(context, ref))
        else ...[
          Text(
            '${folders.length} folders · ${local.length} songs',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          ...folders.map((entry) {
            final songs = entry.value;
            final first = songs.first;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.folder_rounded),
              title: Text(MusicCatalog.folderDisplayTitle(entry.key)),
              subtitle: Text(
                '${songs.length} songs · ${first.artistName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push(
                '/library/folder',
                extra: LibraryFolderArgs(folderKey: entry.key, songs: songs),
              ),
            );
          }),
        ],
      ],
    );
  }

  static Future<void> _rescan(BuildContext context, WidgetRef ref) async {
    final n = await runDeviceMusicScanWithProgressDialog(context, ref);
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (n == -1) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Could not read storage. Allow audio access in settings, then try again.',
          ),
        ),
      );
    } else if (n > 0) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            kIsWeb
                ? 'Imported $n track${n == 1 ? '' : 's'}.'
                : 'Added $n track${n == 1 ? '' : 's'} from device scan.',
          ),
        ),
      );
    } else if (kIsWeb) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No files chosen (or picker was cancelled).'),
        ),
      );
    }
  }
}

class _ClassicEmptyFolders extends StatelessWidget {
  const _ClassicEmptyFolders({required this.onScan});

  final Future<void> Function() onScan;

  @override
  Widget build(BuildContext context) {
    return WindowsClassicInsetBorder(
      color: Colors.white,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No local music found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            kIsWeb
                ? 'Choose audio files from your computer to build your library.'
                : 'Scan your device or import audio files to get started.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          WindowsClassicButton(
            onPressed: () => onScan(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  kIsWeb ? Icons.upload_file : Icons.manage_search,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(kIsWeb ? 'Choose music files' : 'Rescan Library'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFolders extends StatelessWidget {
  const _EmptyFolders({required this.onScan});

  final Future<void> Function() onScan;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No local music found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              kIsWeb
                  ? 'Choose audio files from your computer to build your library.'
                  : 'Scan your device or import audio files to get started.',
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onScan,
              icon: Icon(
                kIsWeb ? Icons.upload_file_rounded : Icons.manage_search_rounded,
              ),
              label: Text(kIsWeb ? 'Choose music files' : 'Rescan Library'),
            ),
          ],
        ),
      ),
    );
  }
}
