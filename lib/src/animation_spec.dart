import 'bezier_animation.dart';
import 'custom_animation.dart';
import 'spring_animation.dart';

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
}
