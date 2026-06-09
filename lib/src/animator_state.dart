import 'animation_context.dart';
import 'animation_spec.dart';
import 'animatable/vector_arithmetic.dart';

/// Drives a single in-flight animation for one [AnimatableValue]. Mirror of
/// SwiftUI's `AnimatorState` — kept as a pure value-producer (no ticker).
class AnimatorState<T extends CustomVectorArithmetic<T>> {
  final AnimationSpec animation;
  final T interval; // newValue - previousValue
  final Duration beginTime;
  AnimationContext<T> context;

  AnimatorState({
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
