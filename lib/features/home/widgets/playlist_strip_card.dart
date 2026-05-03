import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/artwork_tile.dart';
import '../../player/models/playlist.dart';

class PlaylistStripCard extends StatelessWidget {
  const PlaylistStripCard({
    super.key,
    required this.playlist,
    this.width = 168,
  });

  final Playlist playlist;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/playlist/${playlist.id}'),
          child: SizedBox(
            width: width,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ArtworkTile(
                  url: playlist.coverUrl,
                  size: width,
                  borderRadius: AppTheme.cardRadius,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.sm,
                      AppSpacing.sm,
                      AppSpacing.sm,
                      AppSpacing.xs,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          playlist.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                        Text(
                          '${playlist.songCount} songs',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              theme.textTheme.bodySmall?.copyWith(height: 1.2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
