import 'package:flutter/material.dart';

/// Notion-like rhythm: 4px base grid, generous section gaps.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double section = 40;

  static const EdgeInsets screenHorizontal =
      EdgeInsets.symmetric(horizontal: md);

  static const EdgeInsets cardPadding = EdgeInsets.all(md);
}
