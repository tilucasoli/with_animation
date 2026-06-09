import 'bezier_animation.dart';
import 'custom_animation.dart';
import 'spring_animation.dart';

/// Type-erased animation handle. Mirror of SwiftUI's `Animation` struct.
class Animation {
  final CustomAnimation base;
  const Animation(this.base);

  static Animation easeInOut({
    Duration duration = const Duration(milliseconds: 3500),
  }) => Animation(BezierAnimation.easeInOut(duration));
  static Animation easeIn({
    Duration duration = const Duration(milliseconds: 3500),
  }) => Animation(BezierAnimation.easeIn(duration));
  static Animation easeOut({
    Duration duration = const Duration(milliseconds: 3500),
  }) => Animation(BezierAnimation.easeOut(duration));
  static Animation linear({
    Duration duration = const Duration(milliseconds: 3500),
  }) => Animation(BezierAnimation.linear(duration));

  static Animation spring({
    double mass = 1,
    double stiffness = 100,
    double damping = 10,
  }) => Animation(
    SpringAnimation(mass: mass, stiffness: stiffness, damping: damping),
  );
}
