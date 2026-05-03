import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';

import '../features/player/models/app_theme_preference.dart';
import '../features/player/providers/app_providers.dart';
import '../features/player/providers/preferences_notifier.dart';
import 'router.dart';
import 'theme.dart';

class MusicApp extends ConsumerWidget {
  const MusicApp({super.key});

  static bool _didTrackAppOpen = false;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_didTrackAppOpen) {
      _didTrackAppOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(reviewPromptServiceProvider).onAppOpenAndMaybePrompt();
      });
    }
    final router = ref.watch(goRouterProvider);
    final prefs = ref.watch(preferencesNotifierProvider);
    final t = prefs.themePreference;

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final light = AppTheme.lightTheme(lightDynamic);
        final dark = switch (t) {
          AppThemePreference.blackAmoled => AppTheme.blackAmoledTheme(),
          _ => AppTheme.darkTheme(darkDynamic),
        };

        return MaterialApp.router(
          title: 'Music: Offline MP3 Player',
          debugShowCheckedModeBanner: false,
          theme: light,
          darkTheme: dark,
          themeMode: ThemeMode.system,
          themeAnimationCurve: Curves.easeOutCubic,
          themeAnimationDuration: const Duration(milliseconds: 260),
          routerConfig: router,
          builder: (context, child) {
            final useDark =
                MediaQuery.platformBrightnessOf(context) == Brightness.dark;
            final overlay = useDark
                ? SystemUiOverlayStyle.light.copyWith(
                    statusBarColor: Colors.transparent,
                    systemNavigationBarColor: dark.scaffoldBackgroundColor,
                    systemNavigationBarIconBrightness: Brightness.light,
                  )
                : SystemUiOverlayStyle.dark.copyWith(
                    statusBarColor: Colors.transparent,
                    systemNavigationBarColor: light.scaffoldBackgroundColor,
                    systemNavigationBarIconBrightness: Brightness.dark,
                  );
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: overlay,
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }
}
