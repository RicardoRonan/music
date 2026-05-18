import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/widgets/app_loader.dart';
import '../providers/library_scan_progress_provider.dart';
import '../providers/local_library_notifier.dart';

/// Shows a blocking dialog with live scan progress, runs [scanDeviceForMusic],
/// then closes the dialog. Returns the same result as [LocalLibraryNotifier.scanDeviceForMusic].
Future<int> runDeviceMusicScanWithProgressDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  if (kIsWeb) {
    return ref.read(localLibraryProvider.notifier).scanDeviceForMusic();
  }

  final nav = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (dialogContext) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Consumer(
          builder: (_, ref, __) {
            final progress = ref.watch(libraryScanProgressProvider);
            final theme = Theme.of(dialogContext);

            if (progress == null) {
              return Row(
                children: [
                  const AppLoader.small(),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Preparing…',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                ],
              );
            }

            if (progress.kind == LibraryScanKind.collecting) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const LinearProgressIndicator(),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    !kIsWeb &&
                            defaultTargetPlatform == TargetPlatform.windows
                        ? 'Scanning your Music folder…'
                        : 'Scanning storage for music…',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    progress.filesFound == 0
                        ? 'Searching folders…'
                        : '${progress.filesFound.toString()} audio files found',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            }

            final pct = progress.percent ?? 0;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(value: pct / 100),
                const SizedBox(height: AppSpacing.md),
                Text(
                  '$pct%',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Adding tracks (${progress.current} of ${progress.total})',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );

  try {
    return await ref.read(localLibraryProvider.notifier).scanDeviceForMusic();
  } finally {
    if (context.mounted && nav.canPop()) {
      nav.pop();
    }
  }
}
