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

        return MaterialApp.router(
          title: 'Timeless Music Player: Offline MP3 Player',
          debugShowCheckedModeBanner: false,
          theme: t == AppThemePreference.glassmorphism ? dark : light,
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
