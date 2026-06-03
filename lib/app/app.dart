import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';

import '../features/player/models/app_theme_preference.dart';
import '../features/player/providers/app_providers.dart';
import '../features/player/providers/preferences_notifier.dart';
import 'router.dart';
import 'theme.dart';

class MusicApp extends ConsumerStatefulWidget {
  const MusicApp({super.key});

  @override
  ConsumerState<MusicApp> createState() => _MusicAppState();
}

class _MusicAppState extends ConsumerState<MusicApp> {
  static bool _didTrackAppOpen = false;
  static bool _backgroundSyncStarted = false;
  Timer? _backgroundSyncTimer;

  void _startBackgroundSync(WidgetRef ref) {
    _backgroundSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (kIsWeb) return;
      ref.read(localLibraryProvider.notifier).runDeviceScanInBackground();
    });
  }

  @override
  void dispose() {
    _backgroundSyncTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_didTrackAppOpen) {
      _didTrackAppOpen = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(reviewPromptServiceProvider).onAppOpenAndMaybePrompt();
      });
    }
    if (!_backgroundSyncStarted) {
      _backgroundSyncStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startBackgroundSync(ref);
      });
    }
    final router = ref.watch(goRouterProvider);
    final prefs = ref.watch(preferencesNotifierProvider);
    final t = prefs.themePreference;

    if (t == AppThemePreference.windowsClassic ||
        t == AppThemePreference.windowsClassicDark) {
      final dark = t == AppThemePreference.windowsClassicDark;
      final winTheme =
          dark ? AppTheme.windowsClassicDarkTheme() : AppTheme.windowsClassicTheme();
      return MaterialApp.router(
        title: 'Timeless Music Player: Offline MP3 Player',
        debugShowCheckedModeBanner: false,
        theme: winTheme,
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        themeAnimationDuration: Duration.zero,
        routerConfig: router,
        builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: const Color(0xFF000080),
            systemNavigationBarColor: dark
                ? const Color(0xFF4A4A4A)
                : const Color(0xFFC0C0C0),
            systemNavigationBarIconBrightness: Brightness.light,
          ),
          child: child ?? const SizedBox.shrink(),
        ),
      );
    }

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final light = AppTheme.lightTheme(lightDynamic);
        final dark = switch (t) {
          AppThemePreference.blackAmoled => AppTheme.blackAmoledTheme(),
          AppThemePreference.glassmorphism => AppTheme.glassmorphismTheme(),
          _ => AppTheme.darkTheme(darkDynamic),
        };

        final themeMode = switch (t) {
          AppThemePreference.glassmorphism => ThemeMode.dark,
          AppThemePreference.blackAmoled => ThemeMode.dark,
          _ => ThemeMode.system,
        };

        final appTheme = switch (t) {
          AppThemePreference.glassmorphism => dark,
          _ => light,
        };

        return MaterialApp.router(
          title: 'Timeless Music Player: Offline MP3 Player',
          debugShowCheckedModeBanner: false,
          theme: appTheme,
          darkTheme: dark,
          themeMode: themeMode,
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
