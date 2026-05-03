import 'package:flutter/material.dart';

import '../core/constants/app_spacing.dart';

class AppTheme {
  AppTheme._();

  static const Color seedColor = Color(0xFF6750A4);
  static const double cardRadius = 20;
  static const double inputRadius = 16;

  static const PageTransitionsTheme _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: ZoomPageTransitionsBuilder(),
      TargetPlatform.windows: ZoomPageTransitionsBuilder(),
      TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
    },
  );

  static ColorScheme fallbackLightScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.light,
  );

  static ColorScheme fallbackDarkScheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.dark,
  );

  static ThemeData lightTheme(ColorScheme? dynamicScheme) {
    final colorScheme = dynamicScheme ?? fallbackLightScheme;
    return _buildTheme(colorScheme);
  }

  static ThemeData darkTheme(ColorScheme? dynamicScheme) {
    final colorScheme = dynamicScheme ?? fallbackDarkScheme;
    return _buildTheme(colorScheme);
  }

  static ThemeData blackAmoledTheme() {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFB7D4FF),
      onPrimary: Color(0xFF00203B),
      primaryContainer: Color(0xFF00305A),
      onPrimaryContainer: Color(0xFFD7E3FF),
      secondary: Color(0xFFC8C5D0),
      onSecondary: Color(0xFF302E36),
      secondaryContainer: Color(0xFF47464E),
      onSecondaryContainer: Color(0xFFE4E1E9),
      tertiary: Color(0xFFE0BBDD),
      onTertiary: Color(0xFF422741),
      tertiaryContainer: Color(0xFF5A3D58),
      onTertiaryContainer: Color(0xFFFFD7F9),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: Color(0xFF000000),
      onSurface: Color(0xFFE8E1F0),
      surfaceContainerHighest: Color(0xFF1A1720),
      onSurfaceVariant: Color(0xFFCBC3CF),
      outline: Color(0xFF958E99),
      outlineVariant: Color(0xFF4A454F),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFE8E1F0),
      onInverseSurface: Color(0xFF322F37),
      inversePrimary: Color(0xFF6750A4),
    );
    return _buildTheme(scheme).copyWith(scaffoldBackgroundColor: Colors.black);
  }

  // Backwards-compatible aliases for existing call sites.
  static ThemeData light() => lightTheme(null);
  static ThemeData dark() => darkTheme(null);
  static ThemeData androidLight() => lightTheme(null);
  static ThemeData androidDark() => darkTheme(null);
  static ThemeData blackAmoled() => blackAmoledTheme();

  static ThemeData _buildTheme(ColorScheme colorScheme) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      pageTransitionsTheme: _pageTransitions,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );

    return base.copyWith(
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.secondaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      sliderTheme: base.sliderTheme.copyWith(
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.3),
        ),
      ),
    );
  }
}
