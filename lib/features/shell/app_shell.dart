import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../player/widgets/mini_player_slot.dart';
import '../../shared/widgets/app_bottom_bar.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
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
          child: KeyedSubtree(
            key: ValueKey<int>(navigationShell.currentIndex),
            child: navigationShell,
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: EdgeInsets.zero,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MiniPlayerSlot(),
              AppBottomBar(selectedIndex: navigationShell.currentIndex),
            ],
          ),
        ),
      ),
    );
  }
}
