import 'custom_animation/bezier_animation.dart';
import 'custom_animation/custom_animation.dart';
import 'custom_animation/fluid_spring_animation.dart';
import 'custom_animation/repeat_animation.dart';
import 'custom_animation/speed_animation.dart';
import 'custom_animation/spring_animation.dart';

/// Type-erased animation handle wrapping a [CustomAnimation] curve.
///
/// Named `Animations` to avoid collision with Flutter's `Animation<T>`.
class Animations {
  final CustomAnimation base;
  const Animations(this.base);

  static Animations easeInOut({
    Duration duration = const Duration(milliseconds: 3500),
  }) => Animations(BezierAnimation.easeInOut(duration));
  static Animations easeIn({
    Duration duration = const Duration(milliseconds: 3500),
  }) => Animations(BezierAnimation.easeIn(duration));
  static Animations easeOut({
    Duration duration = const Duration(milliseconds: 3500),
  }) => Animations(BezierAnimation.easeOut(duration));
  static Animations linear({
    Duration duration = const Duration(milliseconds: 3500),
  }) => Animations(BezierAnimation.linear(duration));

  static Animations spring({
    double mass = 1,
    double stiffness = 100,
    double damping = 10,
  }) => Animations(
    SpringAnimation(mass: mass, stiffness: stiffness, damping: damping),
  );

  /// Fluid spring parameterised by perceptual duration and damping.
  static Animations fluidSpring({
    double response = 0.5,
    double dampingFraction = 0.825,
    double blendDuration = 0,
  }) => Animations(
    FluidSpringAnimation(
      response: response,
      dampingFraction: dampingFraction,
      blendDuration: blendDuration,
    ),
  );

  /// A smooth, non-bouncy spring preset.
  static Animations smooth({double duration = 0.5, double extraBounce = 0.0}) =>
      fluidSpring(
        response: duration,
        dampingFraction: fluidSpringDampingFraction(extraBounce),
      );

  /// A slightly bouncy spring preset.
  static Animations snappy({double duration = 0.5, double extraBounce = 0.0}) =>
      fluidSpring(
        response: duration,
        dampingFraction: fluidSpringDampingFraction(0.15 + extraBounce),
      );

  /// A noticeably bouncy spring preset.
  static Animations bouncy({double duration = 0.5, double extraBounce = 0.0}) =>
      fluidSpring(
        response: duration,
        dampingFraction: fluidSpringDampingFraction(0.3 + extraBounce),
      );

  /// A short, responsive spring tuned for driving interactive gestures.
  static Animations interactiveSpring({
    double response = 0.15,
    double dampingFraction = 0.86,
    double blendDuration = 0.25,
  }) => fluidSpring(
    response: response,
    dampingFraction: dampingFraction,
    blendDuration: blendDuration,
  );

  /// Repeats the animation [count] times, optionally reversing on every
  /// other cycle.
  Animations repeatCount(int count, {bool autoreverses = true}) => Animations(
    RepeatAnimation(
      base: base,
      repeatCount: count.toDouble(),
      autoreverses: autoreverses,
    ),
  );

  /// Repeats the animation indefinitely.
  Animations repeatForever({bool autoreverses = true}) => Animations(
    RepeatAnimation(
      base: base,
      repeatCount: double.infinity,
      autoreverses: autoreverses,
    ),
  );

  /// Scales the time axis of the animation. `> 1` plays faster, `< 1` plays
  /// slower.
  Animations speed(double speed) =>
      Animations(SpeedAnimation(base: base, speed: speed));
}
