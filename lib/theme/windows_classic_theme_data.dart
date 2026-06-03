import 'package:flutter/material.dart';

import '../core/constants/app_spacing.dart';
import 'windows_classic_theme_extension.dart';

/// Full Material 2–style theme — does not use [AppTheme._buildTheme] (no M3 bleed).
abstract final class WindowsClassicThemeData {
  static const String _font = 'Tahoma';

  static ThemeData build({bool dark = false}) {
    return _build(
      dark ? WindowsClassicColors.darkPalette : WindowsClassicColors.lightPalette,
    );
  }

  static ThemeData _build(WindowsClassicColors c) {
    final grey = c.chrome;
    final navy = c.navy;
    final panel = c.panel;
    final onSurface = c.onSurface;
    final border = c.borderSide;

    final scheme = ColorScheme(
      brightness: c.dark ? Brightness.dark : Brightness.light,
      primary: navy,
      onPrimary: Colors.white,
      primaryContainer: navy,
      onPrimaryContainer: Colors.white,
      secondary: c.shadow,
      onSecondary: onSurface,
      secondaryContainer: grey,
      onSecondaryContainer: Colors.white,
      tertiary: const Color(0xFF008000),
      onTertiary: Colors.white,
      tertiaryContainer: WindowsClassicThemeExtension.visualizerGreen,
      onTertiaryContainer: onSurface,
      error: const Color(0xFFFF0000),
      onError: Colors.white,
      errorContainer: c.dark ? const Color(0xFF4A2020) : const Color(0xFFFFE0E0),
      onErrorContainer: Colors.white,
      surface: grey,
      onSurface: onSurface,
      surfaceContainerHighest: panel,
      onSurfaceVariant: onSurface,
      outline: c.shadow,
      outlineVariant: c.disabled,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: onSurface,
      onInverseSurface: grey,
      inversePrimary: const Color(0xFFB7D4FF),
    );

    final base = ThemeData(
      useMaterial3: false,
      brightness: c.dark ? Brightness.dark : Brightness.light,
      colorScheme: scheme,
      primaryColor: navy,
      canvasColor: grey,
      cardColor: panel,
      dividerColor: c.shadow,
      disabledColor: c.disabled,
      scaffoldBackgroundColor: grey,
      fontFamily: _font,
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: navy.withValues(alpha: 0.25),
      hoverColor: Colors.transparent,
      focusColor: navy.withValues(alpha: 0.35),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      extensions: [
        WindowsClassicThemeExtension(enabled: true, dark: c.dark),
      ],
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme, onSurface),
      primaryTextTheme: _textTheme(base.primaryTextTheme, onSurface),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: navy,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: _font,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white, size: 16),
        actionsIconTheme: IconThemeData(color: Colors.white, size: 16),
      ),
      iconTheme: IconThemeData(color: onSurface, size: 16),
      cardTheme: CardThemeData(
        elevation: 0,
        color: panel,
        surfaceTintColor: Colors.transparent,
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: border,
        ),
      ),
      listTileTheme: ListTileThemeData(
        dense: true,
        minVerticalPadding: 2,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        textColor: onSurface,
        iconColor: onSurface,
        tileColor: Colors.transparent,
        selectedTileColor: navy,
        selectedColor: Colors.white,
        shape: Border(
          bottom: BorderSide(color: c.shadow, width: 1),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: c.shadow,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: grey,
        elevation: 0,
        height: 48,
        indicatorColor: navy,
        surfaceTintColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: grey,
        selectedItemColor: navy,
        unselectedItemColor: onSurface,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: grey,
        indicatorColor: navy,
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: grey,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: grey,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        textStyle: TextStyle(fontSize: 11, fontFamily: _font, color: onSurface),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: grey,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        titleTextStyle: TextStyle(
          fontFamily: _font,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: onSurface,
        ),
        contentTextStyle: TextStyle(
          fontFamily: _font,
          fontSize: 11,
          color: onSurface,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: grey,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.fixed,
        backgroundColor: grey,
        contentTextStyle: TextStyle(
          color: onSurface,
          fontSize: 11,
          fontFamily: _font,
        ),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        elevation: 0,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: WindowsClassicThemeExtension.visualizerGreen,
        linearTrackColor: c.shadow,
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return navy;
          return c.disabled;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return navy;
          return Colors.transparent;
        }),
        side: BorderSide(color: onSurface, width: 1.5),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return navy;
          return c.disabled;
        }),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          backgroundColor: grey,
          foregroundColor: onSurface,
          selectedBackgroundColor: navy,
          selectedForegroundColor: Colors.white,
          disabledBackgroundColor: grey,
          disabledForegroundColor: c.disabled,
          side: border,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          textStyle: const TextStyle(fontSize: 11, fontFamily: _font),
          iconSize: 14,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(64, 22)),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          ),
          backgroundColor: WidgetStatePropertyAll(grey),
          foregroundColor: WidgetStatePropertyAll(onSurface),
          elevation: const WidgetStatePropertyAll(0),
          shadowColor: const WidgetStatePropertyAll(Colors.transparent),
          overlayColor: WidgetStatePropertyAll(navy.withValues(alpha: 0.2)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: border),
          ),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontSize: 11, fontFamily: _font),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 22),
          backgroundColor: grey,
          foregroundColor: onSurface,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: border,
          ),
          textStyle: const TextStyle(fontSize: 11, fontFamily: _font),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 22),
          foregroundColor: onSurface,
          backgroundColor: grey,
          side: border,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          textStyle: const TextStyle(fontSize: 11, fontFamily: _font),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 22),
          foregroundColor: navy,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          textStyle: const TextStyle(fontSize: 11, fontFamily: _font),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(28, 22)),
          padding: const WidgetStatePropertyAll(EdgeInsets.all(2)),
          backgroundColor: WidgetStatePropertyAll(grey),
          foregroundColor: WidgetStatePropertyAll(onSurface),
          elevation: const WidgetStatePropertyAll(0),
          overlayColor: WidgetStatePropertyAll(navy.withValues(alpha: 0.2)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: border),
          ),
        ),
      ),
      sliderTheme: SliderThemeData(
        trackHeight: 4,
        activeTrackColor: WindowsClassicThemeExtension.visualizerGreen,
        inactiveTrackColor: c.shadow,
        thumbColor: c.thumb,
        overlayShape: RoundSliderOverlayShape(overlayRadius: 0),
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 5),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(grey),
        trackColor: WidgetStateProperty.all(panel),
        thickness: WidgetStateProperty.all(16),
        radius: Radius.zero,
        crossAxisMargin: 0,
        mainAxisMargin: 0,
        interactive: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.inputFill,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        hintStyle: TextStyle(
          fontSize: 11,
          fontFamily: _font,
          color: c.disabled,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: border,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: border,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: navy, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: grey,
        selectedColor: navy,
        checkmarkColor: Colors.white,
        deleteIconColor: onSurface,
        labelStyle: TextStyle(
          fontSize: 11,
          fontFamily: _font,
          color: onSurface,
        ),
        secondaryLabelStyle: const TextStyle(
          fontSize: 11,
          fontFamily: _font,
          color: Colors.white,
        ),
        side: border,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: grey,
        foregroundColor: onSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(grey),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(0),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: border),
          ),
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(grey),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: border),
          ),
        ),
      ),
    );
  }

  static TextTheme _textTheme(TextTheme base, Color onSurface) {
    final style = TextStyle(fontFamily: _font, color: onSurface);
    return TextTheme(
      displayLarge: style.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
      displayMedium: style.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
      displaySmall: style.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
      headlineLarge: style.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
      headlineMedium: style.copyWith(fontSize: 13, fontWeight: FontWeight.bold),
      headlineSmall: style.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
      titleLarge: style.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
      titleMedium: style.copyWith(fontSize: 11, fontWeight: FontWeight.bold),
      titleSmall: style.copyWith(fontSize: 11, fontWeight: FontWeight.bold),
      bodyLarge: style.copyWith(fontSize: 12),
      bodyMedium: style.copyWith(fontSize: 11),
      bodySmall: style.copyWith(fontSize: 11),
      labelLarge: style.copyWith(fontSize: 11),
      labelMedium: style.copyWith(fontSize: 10),
      labelSmall: style.copyWith(fontSize: 10),
    );
  }
}
