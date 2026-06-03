import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/windows_classic_theme_extension.dart';

/// Windows Media Player–style spectrum bars: lime bars on black with blue peak hold.
class AudioSpectrumVisualizer extends StatefulWidget {
  const AudioSpectrumVisualizer({
    super.key,
    required this.isPlaying,
    this.barCount = 48,
    this.height = 120,
    this.barColor,
    this.peakColor,
    this.backgroundColor = Colors.black,
    this.showPeakMeters = true,
  });

  final bool isPlaying;
  final int barCount;
  final double height;
  final Color? barColor;
  final Color? peakColor;
  final Color backgroundColor;
  final bool showPeakMeters;

  @override
  State<AudioSpectrumVisualizer> createState() =>
      _AudioSpectrumVisualizerState();
}

class _AudioSpectrumVisualizerState extends State<AudioSpectrumVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tick;
  late List<double> _levels;
  late List<double> _peaks;
  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _levels = List.filled(widget.barCount, 0.06);
    _peaks = List.filled(widget.barCount, 0.06);
    _tick = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 70),
    )..addListener(_advance);
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant AudioSpectrumVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.barCount != widget.barCount) {
      _levels = List.filled(widget.barCount, 0.06);
      _peaks = List.filled(widget.barCount, 0.06);
    }
    _syncAnimation();
  }

  void _syncAnimation() {
    if (widget.isPlaying) {
      if (!_tick.isAnimating) _tick.repeat();
    } else {
      _tick.stop();
    }
  }

  void _advance() {
    final n = widget.barCount;
    final t = _tick.value * math.pi * 2;
    for (var i = 0; i < n; i++) {
      final center = (i / n - 0.5).abs();
      final wave = math.sin(i * 0.55 + t * 3.2) * 0.5 + 0.5;
      final envelope = 1.0 - center * 1.35;
      final target = widget.isPlaying
          ? (0.08 + _rng.nextDouble() * 0.92 * wave * envelope.clamp(0.15, 1.0))
          : 0.05;
      _levels[i] = _levels[i] * 0.55 + target * 0.45;
      if (_levels[i] > _peaks[i]) {
        _peaks[i] = _levels[i];
      } else {
        _peaks[i] = math.max(0.05, _peaks[i] - 0.028);
      }
    }
    setState(() {});
  }

  @override
  void dispose() {
    _tick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barColor =
        widget.barColor ?? WindowsClassicThemeExtension.visualizerGreen;
    final peakColor =
        widget.peakColor ?? WindowsClassicThemeExtension.visualizerPeak;

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SpectrumPainter(
          levels: _levels,
          peaks: _peaks,
          barColor: barColor,
          peakColor: peakColor,
          backgroundColor: widget.backgroundColor,
          showPeakMeters: widget.showPeakMeters,
        ),
      ),
    );
  }
}

class _SpectrumPainter extends CustomPainter {
  _SpectrumPainter({
    required this.levels,
    required this.peaks,
    required this.barColor,
    required this.peakColor,
    required this.backgroundColor,
    required this.showPeakMeters,
  });

  final List<double> levels;
  final List<double> peaks;
  final Color barColor;
  final Color peakColor;
  final Color backgroundColor;
  final bool showPeakMeters;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor);

    final n = levels.length;
    if (n == 0) return;

    const gap = 1.0;
    final barWidth = (size.width - gap * (n - 1)) / n;
    final bottom = size.height - 4;

    for (var i = 0; i < n; i++) {
      final x = i * (barWidth + gap);
      final h = levels[i].clamp(0.05, 1.0) * (size.height - 10);
      final barRect = Rect.fromLTWH(x, bottom - h, barWidth, h);
      canvas.drawRect(barRect, Paint()..color = barColor);

      if (showPeakMeters) {
        final peakY = bottom - peaks[i].clamp(0.05, 1.0) * (size.height - 10);
        canvas.drawRect(
          Rect.fromLTWH(x, peakY - 1.5, barWidth, 2),
          Paint()..color = peakColor,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SpectrumPainter oldDelegate) => true;
}
