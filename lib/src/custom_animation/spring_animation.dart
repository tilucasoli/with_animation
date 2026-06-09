import 'dart:math' as math;

import '../animation_context.dart';
import 'custom_animation.dart';
import '../animatable/vector_arithmetic.dart';

/// Damped-spring animation. Closed-form `1 - amp * decay` evaluator ported
/// from OpenSwiftUI's `Sources/.../Spring/SpringAnimation.swift`.
class SpringAnimation extends CustomAnimation {
  final double mass;
  final double stiffness;
  final double damping;
  final double initialVelocity;

  SpringAnimation({
    this.mass = 1,
    required this.stiffness,
    required this.damping,
    this.initialVelocity = 0,
  });

  late final double _angularFreq = math.sqrt(stiffness / mass);
  late final double _zeta = damping / (2 * math.sqrt(mass * stiffness));
  late final double _decay = _zeta < 1
      ? _angularFreq * math.sqrt(1 - _zeta * _zeta)
      : 0;
  late final double _adjusted = _zeta >= 1
      ? _angularFreq - initialVelocity
      : (_angularFreq * _zeta - initialVelocity) / _decay;

  double _sample(double t) {
    if (_zeta >= 1) {
      final amp = 1 + _adjusted * t;
      return 1 - amp * math.exp(-t * _angularFreq);
    }
    final amp = math.exp(-_zeta * _angularFreq * t);
    return 1 - amp * (math.cos(_decay * t) + _adjusted * math.sin(_decay * t));
  }

  @override
  T? animate<T extends CustomVectorArithmetic<T>>(
    T value,
    double time,
    AnimationContext<T> ctx,
  ) {
    final s = _sample(time);
    if (!s.isFinite) return null;
    // Settling heuristic: once past one period and within 0.1% of target,
    // declare done.
    final period = stiffness.isFinite && stiffness > 0
        ? 2 * math.pi / math.sqrt(stiffness / mass)
        : 0;
    if (time >= period && (1 - s).abs() < 0.001) {
      ctx.isLogicallyComplete = true;
      return null;
    }
    return value.scale(s);
  }
}
