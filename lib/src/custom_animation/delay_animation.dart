import '../animation_context.dart';
import '../animatable/vector_arithmetic.dart';
import 'custom_animation.dart';

/// Wraps a [CustomAnimation] so it begins after a fixed [delay].
///
/// While `time < delay`, [animate] returns `value.zero` — no progress along
/// the interval, so an [AnimatableValue] holds at the starting projection.
/// Once `time >= delay`, the base animation runs from `t = 0`.
class DelayAnimation extends CustomAnimation {
  final CustomAnimation base;
  final Duration delay;

  DelayAnimation({required this.base, required this.delay});

  @override
  T? animate<T extends VectorArithmetic<T>>(
    T value,
    double time,
    AnimationContext<T> context,
  ) {
    final d = delay.inMicroseconds / 1e6;
    if (time < d) return value.zero;
    return base.animate<T>(value, time - d, context);
  }
}
