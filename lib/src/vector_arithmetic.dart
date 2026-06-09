import 'dart:ui';

/// Dart port of OpenSwiftUI's `VectorArithmetic` protocol.
///
/// Any value that participates in animation must be able to add, subtract,
/// and scale by a `double`. `magnitudeSquared` is used by spring physics to
/// detect "settled" state.
abstract class VectorArithmetic<T extends VectorArithmetic<T>> {
  T operator +(T other);
  T operator -(T other);
  T scale(double factor);
  double get magnitudeSquared;
  T get zero;
}

/// Boxed `double` that conforms to [VectorArithmetic].
class AnimatableDouble extends VectorArithmetic<AnimatableDouble> {
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

/// Two-component [VectorArithmetic] suitable for animating `Offset`-like values.
class AnimatableOffset extends VectorArithmetic<AnimatableOffset> {
  final double dx;
  final double dy;
  AnimatableOffset(this.dx, this.dy);

  @override
  AnimatableOffset operator +(AnimatableOffset o) =>
      AnimatableOffset(dx + o.dx, dy + o.dy);
  @override
  AnimatableOffset operator -(AnimatableOffset o) =>
      AnimatableOffset(dx - o.dx, dy - o.dy);
  @override
  AnimatableOffset scale(double f) => AnimatableOffset(dx * f, dy * f);
  @override
  double get magnitudeSquared => dx * dx + dy * dy;
  @override
  AnimatableOffset get zero => AnimatableOffset(0, 0);

  @override
  bool operator ==(Object other) =>
      other is AnimatableOffset && other.dx == dx && other.dy == dy;
  @override
  int get hashCode => Object.hash(dx, dy);
  @override
  String toString() => 'AnimatableOffset($dx, $dy)';
}

/// Four-component [VectorArithmetic] suitable for animating ARGB colors component-wise.
class AnimatableColor extends VectorArithmetic<AnimatableColor> {
  final double a;
  final double r;
  final double g;
  final double b;

  AnimatableColor(this.a, this.r, this.g, this.b);

  /// Constructs from a dart:ui [Color].
  factory AnimatableColor.fromColor(Color color) {
    return AnimatableColor(
      color.alpha.toDouble(),
      color.red.toDouble(),
      color.green.toDouble(),
      color.blue.toDouble(),
    );
  }

  /// Converts to a dart:ui [Color].
  Color toColor() {
    return Color.fromARGB(
      a.round().clamp(0, 255),
      r.round().clamp(0, 255),
      g.round().clamp(0, 255),
      b.round().clamp(0, 255),
    );
  }

  /// Construct from a 32-bit ARGB int (Color.value).
  factory AnimatableColor.fromInt(int value) {
    return AnimatableColor.fromColor(Color(value));
  }

  /// Convert to a 32-bit ARGB int (Color.value).
  int toInt() => toColor().value;

  @override
  AnimatableColor operator +(AnimatableColor o) =>
      AnimatableColor(a + o.a, r + o.r, g + o.g, b + o.b);
  @override
  AnimatableColor operator -(AnimatableColor o) =>
      AnimatableColor(a - o.a, r - o.r, g - o.g, b - o.b);
  @override
  AnimatableColor scale(double f) =>
      AnimatableColor(a * f, r * f, g * f, b * f);

  @override
  double get magnitudeSquared => a * a + r * r + g * g + b * b;

  @override
  AnimatableColor get zero => AnimatableColor(0, 0, 0, 0);

  @override
  bool operator ==(Object other) =>
      other is AnimatableColor &&
      a == other.a &&
      r == other.r &&
      g == other.g &&
      b == other.b;

  @override
  int get hashCode => Object.hash(a, r, g, b);

  @override
  String toString() => 'AnimatableColor($a, $r, $g, $b)';
}
