import 'package:flutter/material.dart';

import '../../features/player/widgets/mini_player_slot.dart';
import '../../theme/windows_classic_theme_extension.dart';
import 'app_bottom_bar.dart';

/// Mini player + main navigation — used in [AppShell] and root-stack routes.
class AppBottomChrome extends StatelessWidget {
  const AppBottomChrome({
    super.key,
    required this.selectedIndex,
    this.showMiniPlayer = true,
  });

  final int selectedIndex;
  final bool showMiniPlayer;

  @override
  Widget build(BuildContext context) {
    final classic = context.isWindowsClassicTheme;

    final miniPlayer = showMiniPlayer
        ? AnimatedSize(
            duration: Duration(
              milliseconds: classic ? 0 : 220,
            ),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: const MiniPlayerSlot(),
          )
        : null;

    final navBar = AppBottomBar(selectedIndex: selectedIndex);

    if (!classic) {
      return SafeArea(
        top: false,
        minimum: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (miniPlayer != null) miniPlayer,
            navBar,
          ],
        ),
      );
    }

    return SafeArea(
      top: false,
      minimum: EdgeInsets.zero,
      child: Builder(
        builder: (context) {
          final c = context.winColors;
          return DecoratedBox(
            decoration: BoxDecoration(
              color: c.chrome,
              border: Border(
                top: BorderSide(color: c.shadow, width: 2),
              ),
            ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (miniPlayer != null)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: c.shadow, width: 1),
                  ),
                ),
                child: miniPlayer,
              ),
            navBar,
            _ClassicNavStatusBar(colors: c),
          ],
        ),
          );
        },
      ),
    );
  }
}

class _ClassicNavStatusBar extends StatelessWidget {
  const _ClassicNavStatusBar({required this.colors});

  final WindowsClassicColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.shadow)),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        'Ready',
        style: TextStyle(
          fontSize: 10,
          fontFamily: 'Tahoma',
          color: colors.onSurface,
        ),
      ),
    );
  }
}
