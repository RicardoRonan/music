import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_spacing.dart';
import '../../player/providers/app_providers.dart';
import '../providers/user_playlists_notifier.dart';

class PlaylistsScreen extends ConsumerWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(musicCatalogProvider);
    final userPlaylists = ref.watch(userPlaylistsProvider);
    final all = catalog.allPlaylists;

    return ListView(
      padding: AppSpacing.screenHorizontal.copyWith(top: AppSpacing.xl),
      children: [
        Row(
          children: [
            Expanded(
              child:
                  Text('Playlists', style: Theme.of(context).textTheme.headlineSmall),
            ),
            IconButton.filledTonal(
              tooltip: 'Create playlist',
              onPressed: () => _showCreateDialog(context, ref),
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Create and manage your listening collections.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        if (userPlaylists.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Text('No custom playlists yet. Tap + to create one.'),
            ),
          ),
        ...all.map((playlist) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.queue_music_rounded),
            title: Text(playlist.title),
            subtitle: Text('${playlist.songCount} songs'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/playlist/${playlist.id}'),
          );
        }),
        const SizedBox(height: AppSpacing.section),
      ],
    );
  }

  Future<void> _showCreateDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final description = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Playlist name'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: description,
              decoration: const InputDecoration(labelText: 'Description (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (result != true || !context.mounted) return;
    final playlist = await ref.read(userPlaylistsProvider.notifier).createPlaylist(
          controller.text,
          description: description.text,
        );
    if (!context.mounted) return;
    if (playlist == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a playlist name.')),
      );
      return;
    }
    context.push('/playlist/${playlist.id}');
  }
}
