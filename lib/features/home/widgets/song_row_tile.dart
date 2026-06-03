import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/duration_format.dart';
import '../../../core/widgets/artwork_tile.dart';
import '../../../theme/windows_classic_theme_extension.dart';
import '../../player/models/song.dart';

String _formatSongDurationLine(Song song) {
  if (song.isLocalFile && song.duration <= const Duration(seconds: 2)) {
    return '—';
  }
  return formatTrackDuration(song.duration);
}

class SongRowTile extends StatelessWidget {
  const SongRowTile({
    super.key,
    required this.song,
    required this.onTap,
    this.trailing,
    this.onSwipeLeftEnqueue,
  });

  final Song song;
  final VoidCallback onTap;
  final Widget? trailing;

  /// Swipe left (LTR) to play this track next in queue.
  final Future<void> Function()? onSwipeLeftEnqueue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final classic = context.isWindowsClassicTheme;
    final wc = classic ? context.winColors : null;
    final tile = ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 2,
      ),
      leading: ArtworkTile(
        url: song.artworkUrl,
        size: 52,
        borderRadius: classic ? 0 : 12,
      ),
      title: Text(
        song.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style:
            theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${song.artistName} · ${_formatSongDurationLine(song)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodySmall,
      ),
      trailing: trailing,
      onTap: onTap,
    );

    if (onSwipeLeftEnqueue == null) {
      return tile;
    }

    return Dismissible(
      key: ValueKey('songrow-${song.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        color: classic ? wc!.navy : theme.colorScheme.primaryContainer,
        child: Icon(
          Icons.queue_music_rounded,
          color: classic ? Colors.white : theme.colorScheme.onPrimaryContainer,
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          await onSwipeLeftEnqueue!();
          if (context.mounted) {
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              SnackBar(
                content: Text('Will play next: "${song.title}"'),
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
  }
}
