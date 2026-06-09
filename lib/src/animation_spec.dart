import 'animatable/vector_arithmetic.dart';
import 'custom_animation/bezier_animation.dart';
import 'custom_animation/custom_animation.dart';
import 'custom_animation/fluid_spring_animation.dart';
import 'custom_animation/keyframe_track.dart';
import 'custom_animation/repeat_animation.dart';
import 'custom_animation/speed_animation.dart';
import 'custom_animation/spring_animation.dart';

/// Type-erased animation handle. Mirror of SwiftUI's `Animation` struct.
///
/// Renamed from `Animation` to avoid collision with Flutter's `Animation<T>`.
class AnimationSpec {
  final CustomAnimation base;
  const AnimationSpec(this.base);

  static AnimationSpec easeInOut({
    Duration duration = const Duration(milliseconds: 3500),
  }) => AnimationSpec(BezierAnimation.easeInOut(duration));
  static AnimationSpec easeIn({
    Duration duration = const Duration(milliseconds: 3500),
  }) => AnimationSpec(BezierAnimation.easeIn(duration));
  static AnimationSpec easeOut({
    Duration duration = const Duration(milliseconds: 3500),
  }) => AnimationSpec(BezierAnimation.easeOut(duration));
  static AnimationSpec linear({
    Duration duration = const Duration(milliseconds: 3500),
  }) => AnimationSpec(BezierAnimation.linear(duration));

  static AnimationSpec spring({
    double mass = 1,
    double stiffness = 100,
    double damping = 10,
  }) => AnimationSpec(
    SpringAnimation(mass: mass, stiffness: stiffness, damping: damping),
  );

  /// Modern SwiftUI spring parameterised by perceptual duration and damping.
  /// Mirror of `Animation.spring(response:dampingFraction:blendDuration:)`.
  static AnimationSpec fluidSpring({
    double response = 0.5,
    double dampingFraction = 0.825,
    double blendDuration = 0,
  }) => AnimationSpec(
    FluidSpringAnimation(
      response: response,
      dampingFraction: dampingFraction,
      blendDuration: blendDuration,
    ),
  );

  /// A smooth, non-bouncy spring. Mirror of SwiftUI's `Animation.smooth`.
  static AnimationSpec smooth({
    double duration = 0.5,
    double extraBounce = 0.0,
  }) => fluidSpring(
    response: duration,
    dampingFraction: fluidSpringDampingFraction(extraBounce),
  );

  /// A slightly bouncy spring. Mirror of SwiftUI's `Animation.snappy`.
  static AnimationSpec snappy({
    double duration = 0.5,
    double extraBounce = 0.0,
  }) => fluidSpring(
    response: duration,
    dampingFraction: fluidSpringDampingFraction(0.15 + extraBounce),
  );

  /// A noticeably bouncy spring. Mirror of SwiftUI's `Animation.bouncy`.
  static AnimationSpec bouncy({
    double duration = 0.5,
    double extraBounce = 0.0,
  }) => fluidSpring(
    response: duration,
    dampingFraction: fluidSpringDampingFraction(0.3 + extraBounce),
  );

  /// A short, responsive spring tuned for driving interactive gestures.
  /// Mirror of SwiftUI's `Animation.interactiveSpring`.
  static AnimationSpec interactiveSpring({
    double response = 0.15,
    double dampingFraction = 0.86,
    double blendDuration = 0.25,
  }) => fluidSpring(
    response: response,
    dampingFraction: dampingFraction,
    blendDuration: blendDuration,
  );

  /// Drives the animation through a list of [Keyframe]s along one timeline.
  /// Mirror of SwiftUI's `KeyframeTrack`.
  static AnimationSpec keyframeTrack<T extends VectorArithmetic<T>>(
    List<Keyframe<T>> keyframes,
  ) => AnimationSpec(KeyframeTrack<T>(keyframes));

  /// Runs two child animations in parallel on the two halves of an
  /// [AnimatablePair]. Typically each child is a [KeyframeTrack] over its own
  /// [VectorArithmetic] type. Mirror of SwiftUI's `Keyframes` builder with
  /// multiple `KeyframeTrack`s.
  static AnimationSpec parallelKeyframeTracks<
    A extends VectorArithmetic<A>,
    B extends VectorArithmetic<B>
  >(CustomAnimation first, CustomAnimation second) =>
      AnimationSpec(ParallelKeyframeTracks<A, B>(first, second));

  /// Repeats the animation [count] times, optionally reversing on every
  /// other cycle. Mirror of SwiftUI's `Animation.repeatCount`.
  AnimationSpec repeatCount(int count, {bool autoreverses = true}) =>
      AnimationSpec(
        RepeatAnimation(
          base: base,
          repeatCount: count.toDouble(),
          autoreverses: autoreverses,
        ),
      );

  /// Repeats the animation indefinitely. Mirror of SwiftUI's
  /// `Animation.repeatForever`.
  AnimationSpec repeatForever({bool autoreverses = true}) => AnimationSpec(
    RepeatAnimation(
      base: base,
      repeatCount: double.infinity,
      autoreverses: autoreverses,
    ),
  );

  /// Scales the time axis of the animation. `> 1` plays faster, `< 1` plays
  /// slower. Mirror of SwiftUI's `Animation.speed`.
  AnimationSpec speed(double speed) =>
      AnimationSpec(SpeedAnimation(base: base, speed: speed));
}
