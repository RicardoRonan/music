import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/playback_state.dart';
import '../providers/player_notifier.dart';
import 'mini_player.dart';

/// Animated mini player strip used under the main shell and on full-screen
/// routes (see [FullScreenMiniPlayerStrip]) pushed on the root navigator.
class MiniPlayerSlot extends ConsumerWidget {
  const MiniPlayerSlot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Do not watch full [PlayerState]: [positionStream] ticks would rebuild the
    // shell, mini player, and enrichment on every update → ANR / OOM on Android.
    final track = ref.watch(
      playerNotifierProvider.select((p) => p.currentSong),
    );
    final processingState = ref.watch(
      playerNotifierProvider.select((p) => p.processingState),
    );
    final isPlaying = ref.watch(
      playerNotifierProvider.select((p) => p.isPlaying),
    );

    Widget child =
        SizedBox.shrink(key: const ValueKey<String>('mini-player-off'));
    if (track != null && processingState != AppProcessingState.error) {
      child = MiniPlayer(
        key: ValueKey(track.id),
        song: track,
        isPlaying: isPlaying,
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: child,
    );
  }
}
