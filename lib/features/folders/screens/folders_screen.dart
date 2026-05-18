import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../player/data/music_catalog.dart';
import '../../player/providers/app_providers.dart';
import '../../player/widgets/library_scan_progress_dialog.dart';
import '../../library/screens/library_folder_screen.dart';

class FoldersScreen extends ConsumerWidget {
  const FoldersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(musicCatalogProvider);
    final local = ref.watch(localLibraryProvider);
    final folders = catalog.deviceSongsByFolder.entries.toList()
      ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));

    return ListView(
      padding: AppSpacing.screenHorizontal.copyWith(
        top: AppSpacing.xl,
        bottom: AppSpacing.section,
      ),
      children: [
        Text('Folders', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Browse music by your file structure.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (local.isEmpty)
          _EmptyFolders(
            onScan: () async {
              final n = await runDeviceMusicScanWithProgressDialog(
                context,
                ref,
              );
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
            },
          )
        else ...[
          Text(
            '${folders.length} folders · ${local.length} songs',
            style: Theme.of(context).textTheme.bodySmall,
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
            Text('No local music found', style: Theme.of(context).textTheme.titleMedium),
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
