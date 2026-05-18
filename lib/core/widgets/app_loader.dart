import 'package:flutter/material.dart';

/// Three-bar loading animation (Jimu primary loading style).
class AppLoader extends StatefulWidget {
  const AppLoader({
    super.key,
    this.color,
    this.scale = 1,
  });

  /// Compact loader for thumbnails and inline use.
  const AppLoader.small({super.key, this.color}) : scale = 0.55;

  static const Color defaultColor = Color(0xFF076FE5);

  final Color? color;
  final double scale;

  static const double _barWidth = 13.6;
  static const double _barHeight = 32;
  static const double _barSpacing = 6.392; // 19.992 - 13.6
  static const Duration _duration = Duration(milliseconds: 800);

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppLoader._duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppLoader.defaultColor;
    final scale = widget.scale;

    return SizedBox(
      width: (AppLoader._barWidth * 3 + AppLoader._barSpacing * 2) * scale,
      height: 40 * scale,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _LoadingBar(
                phase: _phase(0),
                color: color,
                scale: scale,
              ),
              SizedBox(width: AppLoader._barSpacing * scale),
              _LoadingBar(
                phase: _phase(0.16),
                color: color,
                scale: scale,
              ),
              SizedBox(width: AppLoader._barSpacing * scale),
              _LoadingBar(
                phase: _phase(0.32),
                color: color,
                scale: scale,
              ),
            ],
          );
        },
      ),
    );
  }

  double _phase(double delay) {
    final t = (_controller.value - delay) % 1.0;
    return t < 0 ? t + 1.0 : t;
  }
}

class _LoadingBar extends StatelessWidget {
  const _LoadingBar({
    required this.phase,
    required this.color,
    required this.scale,
  });

  final double phase;
  final Color color;
  final double scale;

  static double _heightAt(double t) {
    if (t <= 0.4) {
      final p = Curves.easeInOut.transform(t / 0.4);
      return AppLoader._barHeight + (40 - AppLoader._barHeight) * p;
    }
    if (t <= 0.8) {
      final p = Curves.easeInOut.transform((t - 0.4) / 0.4);
      return 40 + (AppLoader._barHeight - 40) * p;
    }
    return AppLoader._barHeight;
  }

  static double _opacityAt(double t) {
    if (t <= 0.4) {
      final p = Curves.easeInOut.transform(t / 0.4);
      return 0.75 + (1 - 0.75) * p;
    }
    if (t <= 0.8) {
      final p = Curves.easeInOut.transform((t - 0.4) / 0.4);
      return 1 + (0.75 - 1) * p;
    }
    return 0.75;
  }

  static double _shadowBlurAt(double t) {
    if (t <= 0.4) {
      final p = Curves.easeInOut.transform(t / 0.4);
      return 8 * p;
    }
    if (t <= 0.8) {
      final p = Curves.easeInOut.transform((t - 0.4) / 0.4);
      return 8 * (1 - p);
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final height = _heightAt(phase) * scale;
    final opacity = _opacityAt(phase);
    final shadowBlur = _shadowBlurAt(phase) * scale;

    return Opacity(
      opacity: opacity,
      child: Container(
        width: AppLoader._barWidth * scale,
        height: height,
        decoration: BoxDecoration(
          color: color,
          boxShadow: shadowBlur > 0
              ? [
                  BoxShadow(
                    color: color,
                    blurRadius: shadowBlur,
                    offset: Offset(0, -shadowBlur * 0.5),
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}
