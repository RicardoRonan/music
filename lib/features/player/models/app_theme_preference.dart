import 'package:flutter/material.dart';

/// Maps to persisted int for [SharedPreferences].
enum AppThemePreference {
  system(0),
  light(1),
  dark(2),
  android(3),
  blackAmoled(4),
  glassmorphism(5);

  const AppThemePreference(this.storageValue);
  final int storageValue;

  static AppThemePreference fromStorage(int? v) {
    return AppThemePreference.values.firstWhere(
      (e) => e.storageValue == v,
      orElse: () => AppThemePreference.system,
    );
  }

  ThemeMode get themeMode => switch (this) {
        AppThemePreference.system => ThemeMode.system,
        AppThemePreference.light => ThemeMode.light,
        AppThemePreference.dark => ThemeMode.dark,
        AppThemePreference.android => ThemeMode.system,
        AppThemePreference.blackAmoled => ThemeMode.dark,
        AppThemePreference.glassmorphism => ThemeMode.dark,
      };

  String get label => switch (this) {
        AppThemePreference.system => 'System',
        AppThemePreference.light => 'Light',
        AppThemePreference.dark => 'Dark',
        AppThemePreference.android => 'Android',
        AppThemePreference.blackAmoled => 'Black (AMOLED)',
        AppThemePreference.glassmorphism => 'Glassmorphism',
      };
}
