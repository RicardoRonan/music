import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/windows_classic_theme_extension.dart';
import 'app_loader.dart';
import 'artwork_tile_local_stub.dart'
    if (dart.library.io) 'artwork_tile_local_io.dart' as artwork_local;

/// Network artwork with calm local fallback — no heavy gradients.
class ArtworkTile extends StatelessWidget {
  const ArtworkTile({
    super.key,
    this.url,
    required this.size,
    this.borderRadius = 14,
  });

  final String? url;
  final double size;
  final double borderRadius;

  static const String _placeholderAsset =
      'assets/images/artwork_placeholder.svg';

  @override
  Widget build(BuildContext context) {
    final radius = context.isWindowsClassicTheme ? 0.0 : borderRadius;
    final r = BorderRadius.circular(radius);
    final fallback = ClipRRect(
      borderRadius: r,
      child: SvgPicture.asset(
        _placeholderAsset,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );

    if (url == null || url!.isEmpty) {
      return SizedBox(width: size, height: size, child: fallback);
    }

    final trimmed = url!.trim();
    final local = artwork_local.artworkFromFileUri(trimmed, size, r, fallback);
    if (local != null) {
      return local;
    }

    return ClipRRect(
      borderRadius: r,
      child: SizedBox(
        width: size,
        height: size,
        child: CachedNetworkImage(
          imageUrl: trimmed,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          memCacheWidth:
              (size * MediaQuery.of(context).devicePixelRatio).round().clamp(
                    48,
                    800,
                  ),
          placeholder: (_, __) => ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Center(child: AppLoader.small()),
          ),
          errorWidget: (ctx, url, error) => fallback,
        ),
      ),
    );
  }
}
