import 'dart:ui';

import '../../with_animation.dart';

/// Dart port of SwiftUI's `Animatable` protocol.
///
/// A wrapper around a user-facing domain value (e.g. [Offset], [Color]) that
/// exposes a [CustomVectorArithmetic] projection used by the animation
/// pipeline. Reading [animatableData] gets the current projection; writing it
/// mutates the wrapper in place. [clone] returns a detached copy of the same
/// state so [AnimatableValue] can own a frame-local instance to mutate without
/// scribbling over the user's value.
abstract class AnimatableData<V extends CustomVectorArithmetic<V>> {
  V get animatableData;
  set animatableData(V value);
  AnimatableData<V> clone();
}

mixin ValueEquality<T> {
  T get value;

  @override
  bool operator ==(Object other) =>
      other.runtimeType == runtimeType &&
      (other as dynamic).value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => '$runtimeType($value)';
}

typedef OffsetAnimatablePair =
    AnimatablePair<DoubleVectorArithmetic, DoubleVectorArithmetic>;

/// Two-component [AnimatableData] suitable for animating [Offset]-like values.
class AnimatableOffset extends AnimatableData<OffsetAnimatablePair>
    with ValueEquality<Offset> {
  @override
  Offset value;

  AnimatableOffset(this.value);

  @override
  OffsetAnimatablePair get animatableData => AnimatablePair(
    DoubleVectorArithmetic(value.dx),
    DoubleVectorArithmetic(value.dy),
  );

  @override
  set animatableData(OffsetAnimatablePair value) {
    this.value = Offset(value.first.value, value.second.value);
  }

  @override
  AnimatableOffset clone() => AnimatableOffset(value);
}

typedef ColorAnimatablePair =
    AnimatablePair<
      AnimatablePair<DoubleVectorArithmetic, DoubleVectorArithmetic>,
      AnimatablePair<DoubleVectorArithmetic, DoubleVectorArithmetic>
    >;

/// Four-component [AnimatableData] for animating [Color] values.
///
/// Interpolation happens component-wise in the sRGB color space using the
/// floating-point channels (0.0–1.0). Components are clamped on write-back
/// so intermediate spring overshoot never produces invalid colors.
class AnimatableColor extends AnimatableData<ColorAnimatablePair>
    with ValueEquality<Color> {
  @override
  Color value;

  AnimatableColor(this.value);

  @override
  ColorAnimatablePair get animatableData => .new(
    AnimatablePair(.new(value.r), .new(value.g)),
    AnimatablePair(.new(value.b), .new(value.a)),
  );

  @override
  set animatableData(ColorAnimatablePair value) {
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
