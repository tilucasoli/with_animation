import 'package:flutter/animation.dart' show Cubic, Curve, Curves;

import '../animation_context.dart';
import 'custom_animation.dart';
import '../animatable/vector_arithmetic.dart';

/// Cubic-Bezier eased animation. Backs `Animations.easeIn` / `easeOut` /
/// `easeInOut` / `linear` by delegating to Flutter's `Cubic` curve evaluator.
class BezierAnimation extends CustomAnimation {
  final Curve curve;
  final Duration duration;

  BezierAnimation({required this.curve, required this.duration});

  factory BezierAnimation.linear(Duration d) =>
      BezierAnimation(curve: Curves.linear, duration: d);
  factory BezierAnimation.easeIn(Duration d) =>
      BezierAnimation(curve: const Cubic(0.42, 0, 1.0, 1.0), duration: d);
  factory BezierAnimation.easeOut(Duration d) =>
      BezierAnimation(curve: const Cubic(0, 0, 0.58, 1.0), duration: d);
  factory BezierAnimation.easeInOut(Duration d) =>
      BezierAnimation(curve: const Cubic(0.42, 0, 0.58, 1.0), duration: d);

  @override
  T? animate<T extends VectorArithmetic<T>>(
    T value,
    double time,
    AnimationContext<T> ctx,
  ) {
    final d = duration.inMicroseconds / 1e6;
    if (d <= 0 || time > d) return null;
    final fraction = curve.transform((time / d).clamp(0.0, 1.0));
    return value.scale(fraction);
  }
}
