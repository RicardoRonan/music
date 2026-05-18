import 'package:flutter/material.dart';

import 'app_loader.dart';

/// Full-area loader overlay (matches web bootstrap loader layout).
class AppLoaderOverlay extends StatelessWidget {
  const AppLoaderOverlay({
    super.key,
    this.backgroundColor,
    this.loaderColor,
  });

  final Color? backgroundColor;
  final Color? loaderColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = backgroundColor ?? theme.scaffoldBackgroundColor;

    return ColoredBox(
      color: bg,
      child: Center(
        child: AppLoader(color: loaderColor),
      ),
    );
  }
}
