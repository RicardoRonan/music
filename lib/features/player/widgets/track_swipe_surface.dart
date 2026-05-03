import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Horizontal skip gestures using raw pointer deltas so [InkWell] and the
/// gesture arena do not swallow [GestureDetector] drags.
///
/// Commits on [onPointerMove] once distance crosses [minSwipeDistance] so a
/// parent [ScrollView] cancelling the pointer after a horizontal flick still
/// triggers skip/previous when appropriate.
class TrackSwipeSurface extends StatefulWidget {
  const TrackSwipeSurface({
    super.key,
    required this.skipNext,
    required this.skipPrevious,
    required this.child,
    this.minSwipeDistance = 36,
    this.verticalLeakThreshold = 32,
    this.verticalDominanceRatio = 2.2,
  });

  final VoidCallback skipNext;
  final VoidCallback skipPrevious;
  final Widget child;

  /// Minimum net horizontal travel to recognize a swipe.
  final double minSwipeDistance;

  /// Ignore tiny vertical jitter; genuine scrolls exceed this quickly.
  final double verticalLeakThreshold;

  /// Reject as "vertical scroll" when [cumulative |dy|] exceeds
  /// `max(verticalLeakThreshold, |dx| * verticalDominanceRatio)`.
  final double verticalDominanceRatio;

  @override
  State<TrackSwipeSurface> createState() => _TrackSwipeSurfaceState();
}

class _TrackSwipeSurfaceState extends State<TrackSwipeSurface> {
  int? _activePointer;
  double _accumDx = 0;
  double _accumDy = 0;
  bool _committed = false;

  void _reset() {
    _activePointer = null;
    _accumDx = 0;
    _accumDy = 0;
    _committed = false;
  }

  bool _tooVerticalForHorizontalSwipe() {
    final dx = _accumDx.abs();
    final dy = _accumDy;
    final cap = math.max(widget.verticalLeakThreshold, dx * widget.verticalDominanceRatio);
    return dy > cap;
  }

  void _tryCommitSwipe() {
    if (_committed) {
      return;
    }
    final dx = _accumDx;
    if (dx.abs() < widget.minSwipeDistance) {
      return;
    }
    if (_tooVerticalForHorizontalSwipe()) {
      return;
    }
    _committed = true;
    if (dx < 0) {
      widget.skipNext();
    } else {
      widget.skipPrevious();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (PointerDownEvent e) {
        if (_activePointer != null) {
          return;
        }
        _activePointer = e.pointer;
        _accumDx = 0;
        _accumDy = 0;
        _committed = false;
      },
      onPointerMove: (PointerMoveEvent e) {
        if (e.pointer != _activePointer) {
          return;
        }
        _accumDx += e.delta.dx;
        _accumDy += e.delta.dy.abs();
        _tryCommitSwipe();
      },
      onPointerUp: (PointerUpEvent e) {
        if (e.pointer != _activePointer) {
          return;
        }
        if (!_committed) {
          _tryCommitSwipe();
        }
        _reset();
      },
      onPointerCancel: (PointerCancelEvent e) {
        if (e.pointer != _activePointer) {
          return;
        }
        if (!_committed) {
          _tryCommitSwipe();
        }
        _reset();
      },
      child: widget.child,
    );
  }
}
