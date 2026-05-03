import 'package:flutter/material.dart';

import 'mini_player_slot.dart';

/// Mini player strip for routes on the root navigator — same behavior as
/// [AppShell]’s bar so playback stays reachable from playlists, queue, etc.
class FullScreenMiniPlayerStrip extends StatelessWidget {
  const FullScreenMiniPlayerStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: EdgeInsets.zero,
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: const MiniPlayerSlot(),
      ),
    );
  }
}
