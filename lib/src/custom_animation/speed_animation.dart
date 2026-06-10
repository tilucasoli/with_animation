import '../animation_context.dart';
import 'custom_animation.dart';
import '../animatable/vector_arithmetic.dart';

/// Wraps a [CustomAnimation] and scales its time axis.
///
/// `speed > 1` plays faster (shorter wall-clock duration). `speed < 1` plays
/// slower. `speed == 0` freezes the animation at its starting value.
class SpeedAnimation extends CustomAnimation {
  final CustomAnimation base;
  final double speed;

  SpeedAnimation({required this.base, required this.speed});

  @override
  T? animate<T extends VectorArithmetic<T>>(
    T value,
    double time,
    AnimationContext<T> context,
  ) => base.animate<T>(value, time * speed, context);
}
