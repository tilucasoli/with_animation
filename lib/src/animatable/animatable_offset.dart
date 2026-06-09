import 'dart:ui';

import 'vector_arithmetic.dart';

/// Two-component [CustomVectorArithmetic] suitable for animating `Offset`-like values.
class AnimatableOffset extends CustomVectorArithmetic<AnimatableOffset> {
  final Offset value;
  AnimatableOffset(this.value);

  @override
  AnimatableOffset operator +(AnimatableOffset o) => .new(value + o.value);
  @override
  AnimatableOffset operator -(AnimatableOffset o) => .new(value - o.value);
  @override
  AnimatableOffset scale(double f) => .new(value * f);
  @override
  double get magnitudeSquared => value.dx * value.dx + value.dy * value.dy;
  @override
  AnimatableOffset get zero => .new(Offset.zero);

  @override
  bool operator ==(Object other) =>
      other is AnimatableOffset && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => 'AnimatableOffset($value)';
}
