import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/player/models/app_theme_preference.dart';
import '../theme/app_theme.dart';

const _kThemePrefKey = 'app_theme_mode';

/// Notification accent aligned with [AppTheme.seedColor] and stored theme prefs.
Color notificationColorForThemePreference(AppThemePreference preference) {
  return switch (preference) {
    AppThemePreference.light => AppTheme.seedColor,
    AppThemePreference.dark => AppTheme.seedColor,
    AppThemePreference.system => AppTheme.seedColor,
    AppThemePreference.android => AppTheme.seedColor,
    AppThemePreference.blackAmoled => const Color(0xFF6750A4),
    AppThemePreference.glassmorphism => const Color(0xFF6750A4),
    AppThemePreference.windowsClassic => const Color(0xFF000080),
    AppThemePreference.windowsClassicDark => const Color(0xFF000080),
  };
}

Future<Color> _resolveNotificationColor(SharedPreferences? prefs) async {
  if (prefs == null) return AppTheme.seedColor;
  final theme = AppThemePreference.fromStorage(prefs.getInt(_kThemePrefKey));
  return notificationColorForThemePreference(theme);
}

/// Registers [audio_service] for lock screen / notification / headset controls.
Future<void> initBackgroundPlayback({SharedPreferences? prefs}) async {
  final resolvedPrefs = prefs ?? await SharedPreferences.getInstance();
  final notificationColor = await _resolveNotificationColor(resolvedPrefs);

  await JustAudioBackground.init(
    androidNotificationChannelId:
        'com.example.flutter_starter.channel.media.v2',
    androidNotificationChannelName: 'Media playback',
    androidNotificationChannelDescription: 'Now playing and transport controls',
    // [androidNotificationOngoing] requires [androidStopForegroundOnPause] true; use
    // ongoing false so we can keep the rich media notification when paused.
    androidNotificationOngoing: false,
    // Keep the media-style notification while paused so transport + seek stay available.
    androidStopForegroundOnPause: false,
    androidNotificationIcon: 'mipmap/ic_launcher',
    preloadArtwork: true,
    fastForwardInterval: const Duration(seconds: 15),
    rewindInterval: const Duration(seconds: 15),
    notificationColor: notificationColor,
  );
}
