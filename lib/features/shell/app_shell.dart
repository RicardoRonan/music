import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/windows_classic_theme_extension.dart';
import '../../shared/widgets/app_bottom_chrome.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final classic = context.isWindowsClassicTheme;
    final tabBody = KeyedSubtree(
      key: ValueKey<int>(navigationShell.currentIndex),
      child: navigationShell,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: classic
            ? tabBody
            : AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final fade = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  );
                  final slide = Tween<Offset>(
                    begin: const Offset(0.03, 0),
                    end: Offset.zero,
                  ).animate(fade);
                  return FadeTransition(
                    opacity: fade,
                    child: SlideTransition(position: slide, child: child),
                  );
                },
                child: tabBody,
              ),
      ),
      bottomNavigationBar: AppBottomChrome(
        selectedIndex: navigationShell.currentIndex,
      ),
    );
  }
}
