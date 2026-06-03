import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_spacing.dart';
import '../../home/widgets/song_row_tile.dart';
import '../../player/data/music_catalog.dart';
import '../../player/models/song.dart';
import '../../player/providers/app_providers.dart';
import '../../player/providers/player_notifier.dart';
import '../../../shared/widgets/app_bottom_chrome.dart';

/// Route [extra] — folder browsing from Library.
class LibraryFolderArgs {
  const LibraryFolderArgs({
    required this.folderKey,
    required this.songs,
  });

  final String folderKey;
  final List<Song> songs;
}

class LibraryFolderScreen extends ConsumerStatefulWidget {
  const LibraryFolderScreen({super.key, required this.args});

  final LibraryFolderArgs args;

  @override
  ConsumerState<LibraryFolderScreen> createState() => _LibraryFolderScreenState();
}

class _LibraryFolderScreenState extends ConsumerState<LibraryFolderScreen> {
  var _scheduledProbe = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _scheduledProbe) return;
      _scheduledProbe = true;
      unawaited(
        ref
            .read(localLibraryProvider.notifier)
            .probeMissingDurationsInBackground(widget.args.songs),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final args = widget.args;

    return Scaffold(
      appBar: AppBar(
        title: Text(MusicCatalog.folderDisplayTitle(args.folderKey)),
      ),
      bottomNavigationBar: const AppBottomChrome(selectedIndex: 0),
      body: ListView(
        padding: AppSpacing.screenHorizontal.copyWith(top: AppSpacing.sm),
        children: [
          if (args.folderKey.contains('/') ||
              args.folderKey.contains(r'\')) ...[
            SelectableText(
              args.folderKey,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          ...args.songs.map(
            (s) => SongRowTile(
              song: s,
              onSwipeLeftEnqueue: () => ref
                  .read(playerNotifierProvider.notifier)
                  .playNext(s),
              onTap: () => ref.read(playerNotifierProvider.notifier).playFromCollection(
                    args.songs,
                    args.songs.indexOf(s),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

