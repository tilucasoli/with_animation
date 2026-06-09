import 'dart:math' as math;

import '../animation_context.dart';
import 'custom_animation.dart';
import '../animatable/vector_arithmetic.dart';

/// Modern SwiftUI-style spring. Port of OpenSwiftUI's
/// `Sources/.../Spring/FluidSpringAnimation.swift`.
///
/// Backs `Animation.spring(response:dampingFraction:blendDuration:)` and the
/// presets `smooth`, `snappy`, `bouncy`, and `interactiveSpring`. Parameters
/// are perceptual:
///
/// * [response] — approximate "duration" / pace of the spring (seconds).
/// * [dampingFraction] — drag as a fraction of critical damping. `1` is
///   critically damped (no bounce), `< 1` bounces, `> 1` is overdamped.
/// * [blendDuration] — over this many seconds, blend a stale spring's
///   response into the new one when [shouldMerge] swaps animations.
class FluidSpringAnimation extends CustomAnimation {
  final double response;
  final double dampingFraction;
  final double blendDuration;

  FluidSpringAnimation({
    this.response = 0.5,
    this.dampingFraction = 0.825,
    this.blendDuration = 0,
  });

  static const double _maxStiffness = 45000.0;

  @override
  T? animate<T extends CustomVectorArithmetic<T>>(
    T value,
    double time,
    AnimationContext<T> ctx,
  ) {
    var state = ctx.state.get<_FluidSpringState<T>?>(null);
    if (state == null) {
      state = _FluidSpringState<T>(
        offset: value.zero,
        velocity: value.zero,
        force: value.zero,
      );
      ctx.state.set<_FluidSpringState<T>?>(state);
    }

    final double r;
    if (blendDuration > 0 && state.blendInterval != 0) {
      // Literal port: in the source `.clamp(...)` binds to `blendDuration`,
      // not to the whole division, so the divisor is the clamped duration.
      final clampedBlend = blendDuration.clamp(0.0, 1.0);
      final progress = (time - state.blendStart) / clampedBlend;
      final smoothstep = 1.0 - progress * progress * (3.0 - progress * 2.0);
      r = response + state.blendInterval * smoothstep;
    } else {
      r = response;
    }

    final double rawStiffness;
    if (r > 0) {
      final freq = 2 * math.pi / r;
      rawStiffness = freq * freq;
    } else {
      rawStiffness = 1.0;
    }
    final stiffness = math.min(rawStiffness, _maxStiffness);

    if (time - state.startTime >= r) {
      ctx.isLogicallyComplete = true;
    }
    if (time - state.time > 1.0) {
      state.time = time - 1.0 / 60.0;
    }

    final damping = -_springDamping(dampingFraction, stiffness);

    var t = state.time;
    while (t < time) {
      final force = state.force.scale(1.0 / 600.0) + state.velocity;
      state.offset = state.offset + force.scale(1.0 / 300.0);
      final dampedForce = force.scale(damping);
      final displacement = (value - state.offset).scale(stiffness);
      state.force = dampedForce + displacement;
      state.velocity = state.force.scale(1.0 / 600.0) + force;
      t += 1.0 / 300.0;
    }
    state.time = t;

    final motion = math.max(
      state.velocity.magnitudeSquared,
      state.force.magnitudeSquared,
    );
    if (motion > 0.0036) return state.offset;

    final tolerance = value.scale(0.01);
    final remainingDistance = value - state.offset;
    if (tolerance.magnitudeSquared > 0 &&
        tolerance.magnitudeSquared < remainingDistance.magnitudeSquared) {
      return state.offset;
    }
    return null;
  }
}

class _FluidSpringState<T extends CustomVectorArithmetic<T>> {
  T offset;
  T velocity;
  T force;
  double time;
  double startTime;
  double blendStart;
  double blendInterval;

  _FluidSpringState({
    required this.offset,
    required this.velocity,
    required this.force,
    this.time = 0,
    this.startTime = 0,
    this.blendStart = 0,
    this.blendInterval = 0,
  });
}

double _springDamping(double fraction, double stiffness) =>
    2 * math.sqrt(stiffness) * fraction;

/// Maps SwiftUI's `bounce` parameter onto a damping fraction. `bounce == 0`
/// yields critical damping (1.0), positive values bounce, negative values
/// overdamp. Mirror of OpenSwiftUI's `springDampingFraction(bounce:)`.
double fluidSpringDampingFraction(double bounce) =>
    bounce < 0 ? 1.0 / (bounce + 1.0) : 1.0 - bounce;
