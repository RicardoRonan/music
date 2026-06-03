import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../just_audio_import.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/duration_format.dart';
import '../../../core/widgets/audio_spectrum_visualizer.dart';
import '../../../core/widgets/windows_classic_ui.dart';
import '../../../theme/windows_classic_theme_extension.dart';
import '../models/song.dart';
import '../providers/player_notifier.dart';

/// Now playing layout: Win95 window chrome, WMP visualizer, minimal transport row.
class WindowsClassicNowPlayingBody extends ConsumerWidget {
  const WindowsClassicNowPlayingBody({
    super.key,
    required this.song,
    required this.displayTitle,
    required this.displayArtist,
    required this.onSwipeDownPop,
    this.showBackButton = true,
    this.onShowDetails,
    this.onShowMusicBrainz,
  });

  final Song song;
  final String displayTitle;
  final String displayArtist;
  final VoidCallback onSwipeDownPop;
  final bool showBackButton;
  final VoidCallback? onShowDetails;
  final VoidCallback? onShowMusicBrainz;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(
      playerNotifierProvider.select((p) => p.isPlaying),
    );
    final notifier = ref.read(playerNotifierProvider.notifier);

    return SafeArea(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragEnd: (details) {
          if ((details.primaryVelocity ?? 0) > 420) onSwipeDownPop();
        },
        child: Padding(
          padding: AppSpacing.screenHorizontal.copyWith(
            top: AppSpacing.sm,
            bottom: AppSpacing.sm,
          ),
          child: WindowsClassicOutsetBorder(
            child: WindowsClassicInsetBorder(
              color: context.winColors.chrome,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    color: WindowsClassicThemeExtension.navy,
                    padding: const EdgeInsets.only(left: 2, right: 2, top: 1),
                    child: Row(
                      children: [
                        if (showBackButton)
                          _TitleBarIcon(
                            tooltip: 'Close',
                            icon: Icons.close,
                            onPressed: onSwipeDownPop,
                          ),
                        const Expanded(
                          child: Text(
                            'Now Playing',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Tahoma',
                            ),
                          ),
                        ),
                        if (onShowMusicBrainz != null)
                          _TitleBarIcon(
                            tooltip: 'Sources',
                            icon: Icons.info_outline,
                            onPressed: onShowMusicBrainz!,
                          ),
                        if (onShowDetails != null)
                          _TitleBarIcon(
                            tooltip: 'Track details',
                            icon: Icons.more_horiz,
                            onPressed: onShowDetails!,
                          ),
                      ],
                    ),
                  ),
                const WindowsClassicTabRow(
                  tabs: ['Now Playing', 'Library', 'Rip', 'Burn'],
                  activeIndex: 0,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: WindowsClassicInsetBorder(
                      color: Colors.black,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                            child: Text(
                              displayArtist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontFamily: 'Tahoma',
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 2, 8, 4),
                            child: Text(
                              displayTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Tahoma',
                              ),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'Bars and Waves : Bars',
                              style: TextStyle(
                                color: Color(0xFF6699CC),
                                fontSize: 9,
                                fontFamily: 'Tahoma',
                              ),
                            ),
                          ),
                          Expanded(
                            child: AudioSpectrumVisualizer(
                              isPlaying: isPlaying,
                              height: double.infinity,
                              barCount: 52,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const _ClassicSeekRow(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
                  child: _ClassicTransportRow(
                    isPlaying: isPlaying,
                    notifier: notifier,
                  ),
                ),
                Container(
                  height: 22,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: WindowsClassicThemeExtension.darkGrey),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          isPlaying ? 'Playing' : 'Stopped',
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'Tahoma',
                          ),
                        ),
                      ),
                      Text(
                        formatTrackDuration(song.duration),
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'Tahoma',
                        ),
                      ),
                    ],
                  ),
                ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleBarIcon extends StatelessWidget {
  const _TitleBarIcon({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 18,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Icon(icon, size: 14, color: Colors.white),
      ),
    );
  }
}

class _ClassicSeekRow extends ConsumerStatefulWidget {
  const _ClassicSeekRow();

  @override
  ConsumerState<_ClassicSeekRow> createState() => _ClassicSeekRowState();
}

class _ClassicSeekRowState extends ConsumerState<_ClassicSeekRow> {
  @override
  Widget build(BuildContext context) {
    final snap = ref.watch(
      playerNotifierProvider.select(
        (p) => (p.position, p.duration, p.processingState),
      ),
    );
    final (position, duration, _) = snap;
    final notifier = ref.read(playerNotifierProvider.notifier);
    final maxMs = duration.inMilliseconds > 0
        ? duration.inMilliseconds.toDouble()
        : 1.0;
    final posMs =
        position.inMilliseconds.clamp(0, maxMs.round()).toDouble();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        children: [
          SliderTheme(
            data: theme.sliderTheme.copyWith(
              trackShape: const RectangularSliderTrackShape(),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
            ),
            child: Slider(
              value: posMs,
              max: maxMs,
              onChanged: (v) {
                notifier.seekTo(Duration(milliseconds: v.round()));
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatTrackDuration(position),
                style: theme.textTheme.bodySmall,
              ),
              Text(
                formatTrackDuration(duration),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClassicTransportRow extends ConsumerWidget {
  const _ClassicTransportRow({
    required this.isPlaying,
    required this.notifier,
  });

  final bool isPlaying;
  final PlayerNotifier notifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shuffle = ref.watch(
      playerNotifierProvider.select((p) => p.shuffleEnabled),
    );
    final loop = ref.watch(
      playerNotifierProvider.select((p) => p.loopMode),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        WindowsClassicButton(
          onPressed: () => notifier.toggleShuffle(),
          child: Icon(
            Icons.shuffle,
            size: 14,
            color: shuffle ? WindowsClassicThemeExtension.navy : Colors.black,
          ),
        ),
        const SizedBox(width: 4),
        WindowsClassicButton(
          onPressed: () => notifier.skipPrevious(),
          child: const Icon(Icons.skip_previous, size: 16),
        ),
        const SizedBox(width: 4),
        WindowsClassicButton(
          onPressed: () => notifier.skipPrevious(),
          child: const Icon(Icons.fast_rewind, size: 16),
        ),
        const SizedBox(width: 6),
        WindowsClassicButton(
          onPressed: () => notifier.togglePlay(),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Icon(
            isPlaying ? Icons.pause : Icons.play_arrow,
            size: 22,
          ),
        ),
        const SizedBox(width: 6),
        WindowsClassicButton(
          onPressed: () => notifier.skipNext(),
          child: const Icon(Icons.fast_forward, size: 16),
        ),
        const SizedBox(width: 4),
        WindowsClassicButton(
          onPressed: () => notifier.skipNext(),
          child: const Icon(Icons.skip_next, size: 16),
        ),
        const SizedBox(width: 4),
        WindowsClassicButton(
          onPressed: () => notifier.cycleRepeat(),
          child: Icon(
            loop == LoopMode.one ? Icons.repeat_one : Icons.repeat,
            size: 14,
            color: loop == LoopMode.off
                ? Colors.black
                : WindowsClassicThemeExtension.navy,
          ),
        ),
      ],
    );
  }
}
