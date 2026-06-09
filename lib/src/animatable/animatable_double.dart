import 'vector_arithmetic.dart';

/// Boxed `double` that conforms to [CustomVectorArithmetic].
///
/// Mirrors OpenSwiftUI's `Float`/`Double`/`CGFloat` conformances, which all
/// collapse to a single floating-point type in Dart.
class AnimatableDouble extends CustomVectorArithmetic<AnimatableDouble> {
  final double value;
  AnimatableDouble(this.value);

  @override
  AnimatableDouble operator +(AnimatableDouble o) =>
      AnimatableDouble(value + o.value);
  @override
  AnimatableDouble operator -(AnimatableDouble o) =>
      AnimatableDouble(value - o.value);
  @override
  AnimatableDouble scale(double f) => AnimatableDouble(value * f);
  @override
  double get magnitudeSquared => value * value;
  @override
  AnimatableDouble get zero => AnimatableDouble(0);

  @override
  bool operator ==(Object other) =>
      other is AnimatableDouble && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => 'AnimatableDouble($value)';
}
