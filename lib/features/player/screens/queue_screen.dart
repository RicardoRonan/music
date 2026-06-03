import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/duration_format.dart';
import '../../../core/widgets/artwork_tile.dart';
import '../../../shared/widgets/app_bottom_chrome.dart';
import '../models/song.dart';
import '../providers/player_notifier.dart';

String _queueRowDuration(Song s) {
  if (s.isLocalFile && s.duration <= const Duration(seconds: 2)) {
    return '—';
  }
  return formatTrackDuration(s.duration);
}

/// Queue from the playing track onward (same order as playback); actions use real indices.
class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queue = ref.watch(playerNotifierProvider.select((p) => p.queue));
    final currentIndex = ref.watch(
      playerNotifierProvider.select((p) => p.currentIndex),
    );
    final notifier = ref.read(playerNotifierProvider.notifier);
    final theme = Theme.of(context);

    if (queue.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Queue')),
        bottomNavigationBar: const AppBottomChrome(selectedIndex: 0),
        body: Center(
          child: Text(
            'Play a song or playlist to see the queue.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.secondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final ci = currentIndex.clamp(0, queue.length - 1);
    final fromHere = queue.sublist(ci);

    return Scaffold(
      appBar: AppBar(
        title: Text('Queue · ${fromHere.length} from here'),
        actions: [
          IconButton(
            tooltip: 'Save queue as playlist',
            onPressed: () async {
              final controller = TextEditingController(
                text: 'Queue ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
              );
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Save queue as playlist'),
                  content: TextField(
                    controller: controller,
                    decoration: const InputDecoration(labelText: 'Playlist name'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              );
              if (ok != true || !context.mounted) return;
              await notifier.saveQueueAsPlaylist(controller.text);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Queue saved to playlists.')),
              );
            },
            icon: const Icon(Icons.playlist_add_check_circle_rounded),
          ),
          IconButton(
            tooltip: 'Clear queue',
            onPressed: () => notifier.clearQueue(),
            icon: const Icon(Icons.clear_all_rounded),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomChrome(selectedIndex: 0),
      body: ListView.separated(
        padding: AppSpacing.screenHorizontal,
        itemCount: fromHere.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 64),
        itemBuilder: (context, displayIndex) {
          final realIndex = ci + displayIndex;
          final s = queue[realIndex];
          final active = realIndex == currentIndex;
          final tile = ListTile(
            leading: ArtworkTile(url: s.artworkUrl, size: 48, borderRadius: 10),
            title: Text(
              s.title,
              style: active
                  ? theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    )
                  : theme.textTheme.titleSmall,
            ),
            subtitle: Text(
              '#${displayIndex + 1} · ${s.artistName} · ${_queueRowDuration(s)}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (active)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'up') notifier.moveQueueItemUp(realIndex);
                    if (value == 'down') notifier.moveQueueItemDown(realIndex);
                    if (value == 'remove') notifier.removeQueueItem(realIndex);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'up',
                      enabled: realIndex > 0,
                      child: const Text('Move up'),
                    ),
                    PopupMenuItem(
                      value: 'down',
                      enabled: realIndex < queue.length - 1,
                      child: const Text('Move down'),
                    ),
                    const PopupMenuItem(value: 'remove', child: Text('Remove')),
                  ],
                ),
              ],
            ),
            onTap: () => notifier.playFromQueueIndex(realIndex),
          );
          return Dismissible(
            key: ValueKey('queue-$realIndex-${s.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              color: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.vertical_align_top_rounded,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.endToStart) {
                await notifier.moveQueueItemAfterCurrent(realIndex);
                if (context.mounted) {
                  ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                    SnackBar(
                      content: Text('Moved after current: "${s.title}"'),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
              return false;
            },
            child: tile,
          );
        },
      ),
    );
  }
}

