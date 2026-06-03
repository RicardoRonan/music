import 'package:flutter/material.dart';

/// Marks [ThemeData] as the Windows 95 / classic UI variant.
class WindowsClassicThemeExtension
    extends ThemeExtension<WindowsClassicThemeExtension> {
  const WindowsClassicThemeExtension({
    this.enabled = false,
    this.dark = false,
  });

  final bool enabled;
  final bool dark;

  /// Light-mode chrome (#C0C0C0).
  static const Color grey = Color(0xFFC0C0C0);
  static const Color navy = Color(0xFF000080);
  static const Color darkGrey = Color(0xFF808080);
  static const Color visualizerGreen = Color(0xFF00CC00);
  static const Color visualizerPeak = Color(0xFF0080FF);

  @override
  WindowsClassicThemeExtension copyWith({bool? enabled, bool? dark}) {
    return WindowsClassicThemeExtension(
      enabled: enabled ?? this.enabled,
      dark: dark ?? this.dark,
    );
  }

  @override
  WindowsClassicThemeExtension lerp(
    covariant ThemeExtension<WindowsClassicThemeExtension>? other,
    double t,
  ) {
    if (other is! WindowsClassicThemeExtension) return this;
    return WindowsClassicThemeExtension(
      enabled: t < 0.5 ? enabled : other.enabled,
      dark: t < 0.5 ? dark : other.dark,
    );
  }
}

/// Resolved palette for light or dark Windows Classic.
class WindowsClassicColors {
  const WindowsClassicColors._({
    required this.dark,
    required this.chrome,
    required this.panel,
    required this.navy,
    required this.onSurface,
    required this.shadow,
    required this.highlight,
    required this.disabled,
    required this.inputFill,
    required this.thumb,
    required this.accent,
  });

  final bool dark;
  final Color chrome;
  final Color panel;
  final Color navy;
  final Color onSurface;
  final Color shadow;
  final Color highlight;
  final Color disabled;
  final Color inputFill;
  final Color thumb;
  final Color accent;

  static final WindowsClassicColors lightPalette = WindowsClassicColors._(
    dark: false,
    chrome: WindowsClassicThemeExtension.grey,
    panel: Colors.white,
    navy: WindowsClassicThemeExtension.navy,
    onSurface: Colors.black,
    shadow: WindowsClassicThemeExtension.darkGrey,
    highlight: Colors.white,
    disabled: WindowsClassicThemeExtension.darkGrey,
    inputFill: Colors.white,
    thumb: Colors.black,
    accent: WindowsClassicThemeExtension.navy,
  );

  static final WindowsClassicColors darkPalette = WindowsClassicColors._(
    dark: true,
    chrome: const Color(0xFF4A4A4A),
    panel: const Color(0xFF2A2A2A),
    navy: WindowsClassicThemeExtension.navy,
    onSurface: const Color(0xFFF0F0F0),
    shadow: const Color(0xFF121212),
    highlight: const Color(0xFF6E6E6E),
    disabled: const Color(0xFF5A5A5A),
    inputFill: const Color(0xFF1E1E1E),
    thumb: const Color(0xFFE8E8E8),
    accent: const Color(0xFF9EB6FF),
  );

  factory WindowsClassicColors.of(BuildContext context) {
    final ext = Theme.of(context).extension<WindowsClassicThemeExtension>();
    if (ext?.dark == true) return WindowsClassicColors.darkPalette;
    return WindowsClassicColors.lightPalette;
  }

  Border get outsetBorder => Border(
        top: BorderSide(color: highlight, width: 2),
        left: BorderSide(color: highlight, width: 2),
        bottom: BorderSide(color: shadow, width: 2),
        right: BorderSide(color: shadow, width: 2),
      );

  Border get insetBorder => Border(
        top: BorderSide(color: shadow, width: 2),
        left: BorderSide(color: shadow, width: 2),
        bottom: BorderSide(color: highlight, width: 2),
        right: BorderSide(color: highlight, width: 2),
      );

  BorderSide get borderSide => BorderSide(color: shadow, width: 2);
}

extension WindowsClassicThemeContext on BuildContext {
  bool get isWindowsClassicTheme {
    return Theme.of(this)
            .extension<WindowsClassicThemeExtension>()
            ?.enabled ==
        true;
  }

  bool get isWindowsClassicDark {
    return Theme.of(this)
            .extension<WindowsClassicThemeExtension>()
            ?.dark ==
        true;
  }

  WindowsClassicColors get winColors => WindowsClassicColors.of(this);
}
