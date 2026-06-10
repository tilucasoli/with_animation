import 'dart:ui';

import '../../with_animation.dart';

/// Bridge between a user-facing domain value (e.g. [Offset], [Color]) and the
/// [VectorArithmetic] projection consumed by the animation pipeline.
///
/// Reading [vector] gets the current projection; writing it mutates the
/// wrapper in place. [clone] returns a detached copy of the same state so
/// [AnimatableValue] can own a frame-local instance to mutate without
/// scribbling over the user's value.
abstract class Animatable<V extends VectorArithmetic<V>> {
  V get vector;
  set vector(V value);
  Animatable<V> clone();
}

mixin ValueEquality<T> {
  T get value;

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType && (other as dynamic).value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => '$runtimeType($value)';
}

/// Boxed `double` that conforms to [VectorArithmetic].
///
/// Conforms to [Animatable] with itself as its own projection so it can be
/// passed directly to [AnimatableValue].
class AnimatableDouble extends VectorArithmetic<AnimatableDouble>
    implements Animatable<AnimatableDouble> {
  double value;
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
  AnimatableDouble get vector => this;
  @override
  set vector(AnimatableDouble value) {
    this.value = value.value;
  }

  @override
  AnimatableDouble clone() => AnimatableDouble(value);

  @override
  bool operator ==(Object other) =>
      other is AnimatableDouble && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => 'AnimatableDouble($value)';
}

/// Boxed `int` that conforms to [VectorArithmetic].
///
/// Storage and arithmetic stay in `int` space; [scale] rounds to the nearest
/// integer, so fractional factors below `1/(2·value)` collapse to zero. Also
/// conforms to [Animatable] with itself as its own projection.
class AnimatableInt extends VectorArithmetic<AnimatableInt>
    implements Animatable<AnimatableInt> {
  int value;

  AnimatableInt(this.value);

  @override
  AnimatableInt operator +(AnimatableInt o) => AnimatableInt(value + o.value);
  @override
  AnimatableInt operator -(AnimatableInt o) => AnimatableInt(value - o.value);
  @override
  AnimatableInt scale(double f) => AnimatableInt((value * f).toInt());
  @override
  double get magnitudeSquared => (value * value).toDouble();
  @override
  AnimatableInt get zero => AnimatableInt(0);

  @override
  AnimatableInt get vector => this;
  @override
  set vector(AnimatableInt value) {
    this.value = value.value;
  }

  @override
  AnimatableInt clone() => AnimatableInt(value);

  @override
  bool operator ==(Object other) =>
      other is AnimatableInt && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => 'AnimatableInt($value)';
}

typedef OffsetVector = VectorPair<AnimatableDouble, AnimatableDouble>;

/// Two-component [Animatable] suitable for animating [Offset]-like values.
class AnimatableOffset extends Animatable<OffsetVector>
    with ValueEquality<Offset> {
  @override
  Offset value;

  AnimatableOffset(this.value);

  @override
  OffsetVector get vector =>
      VectorPair(AnimatableDouble(value.dx), AnimatableDouble(value.dy));

  @override
  set vector(OffsetVector value) {
    this.value = Offset(value.first.value, value.second.value);
  }

  @override
  AnimatableOffset clone() => AnimatableOffset(value);
}

typedef ColorVector =
    VectorPair<
      VectorPair<AnimatableDouble, AnimatableDouble>,
      VectorPair<AnimatableDouble, AnimatableDouble>
    >;

/// Four-component [Animatable] for animating [Color] values.
///
/// Interpolation happens component-wise in the sRGB color space using the
/// floating-point channels (0.0–1.0). Components are clamped on write-back
/// so intermediate spring overshoot never produces invalid colors.
class AnimatableColor extends Animatable<ColorVector>
    with ValueEquality<Color> {
  @override
  Color value;

  AnimatableColor(this.value);

  @override
  ColorVector get vector => .new(
    VectorPair(.new(value.r), .new(value.g)),
    VectorPair(.new(value.b), .new(value.a)),
  );

  @override
  set vector(ColorVector value) {
    this.value = Color.from(
      red: value.first.first.value.clamp(0.0, 1.0),
      green: value.first.second.value.clamp(0.0, 1.0),
      blue: value.second.first.value.clamp(0.0, 1.0),
      alpha: value.second.second.value.clamp(0.0, 1.0),
    );
  }

  @override
  AnimatableColor clone() => AnimatableColor(value);
}
