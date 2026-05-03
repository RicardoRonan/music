import 'package:flutter/material.dart';

import 'full_screen_mini_player_strip.dart';

/// Wraps a root-stack route so the mini player matches [AppShell] — playback
/// stays reachable from album, playlist, queue, settings, etc.
class RootMiniPlayerOverlay extends StatelessWidget {
  const RootMiniPlayerOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: child),
        const FullScreenMiniPlayerStrip(),
      ],
    );
  }
}
