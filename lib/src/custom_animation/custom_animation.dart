import '../animation_context.dart';
import '../animatable/vector_arithmetic.dart';

/// "Where on the curve am I at time `time`, for an interval `value`?"
///
/// Return `null` from [animate] to signal the animation has completed.
abstract class CustomAnimation {
  T? animate<T extends CustomVectorArithmetic<T>>(
    T value,
    double time,
    AnimationContext<T> context,
  );

  /// Default: don't merge — run alongside the previous animation. Same
  /// default as SwiftUI's `CustomAnimation`.
  bool shouldMerge<T extends CustomVectorArithmetic<T>>(
    CustomAnimation previous,
    T value,
    double time,
    AnimationContext<T> context,
  ) => false;
}
