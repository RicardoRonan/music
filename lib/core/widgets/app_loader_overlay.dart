import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_loader.dart';

const _loadingMessages = [
  'Tuning the equalizer…',
  'Convincing the bass to drop…',
  'Asking the drummer to count in…',
  'Negotiating with the copyright fairy…',
  'Warming up the vinyl…',
  'Finding the song stuck in your head…',
  'Polishing the album art…',
  'Teaching your phone to carry a tune…',
  'Loading bangers at 320kbps…',
  'Shuffling the deck (not really)…',
  'Syncing your good taste…',
  'Almost ready to rock…',
];

/// Full-area loader overlay (matches web bootstrap loader layout).
class AppLoaderOverlay extends StatelessWidget {
  const AppLoaderOverlay({
    super.key,
    this.backgroundColor,
    this.loaderColor,
  });

  final Color? backgroundColor;
  final Color? loaderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = backgroundColor ?? theme.scaffoldBackgroundColor;
    final message =
        _loadingMessages[math.Random().nextInt(_loadingMessages.length)];

    return ColoredBox(
      color: bg,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppLoader(color: loaderColor),
              const SizedBox(height: 24),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hang tight — good things take a beat.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.72,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
