import 'animation_context.dart';
import 'animations.dart';
import 'animatable/vector_arithmetic.dart';

/// Drives a single in-flight animation for one [AnimatableValue]. Kept as a
/// pure value-producer — the ticker lives on [AnimatableValue].
class AnimationDriver<T extends VectorArithmetic<T>> {
  final Animations animation;
  final T interval; // newValue - previousValue
  final Duration beginTime;
  AnimationContext<T> context;

  AnimationDriver({
    required this.animation,
    required this.interval,
    required this.beginTime,
  }) : context = AnimationContext<T>();

  /// Returns the scaled delta to add to the previous value at the current
  /// ticker `now`, or `null` once the underlying animation is done.
  T? sample(Duration now) {
    final elapsed = (now - beginTime).inMicroseconds / 1e6;
    return animation.base.animate<T>(interval, elapsed, context);
  }
}
