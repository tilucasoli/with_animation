import 'dart:ui';

import 'vector_arithmetic.dart';

/// Animatable RGBA color, mirroring OpenSwiftUI's `Color.Resolved`.
///
/// [value] is a dart:ui [Color] whose channels are stored in *extended-range
/// Linear sRGB* as 0..1 floats (the [Color.colorSpace] tag stays at sRGB; we
/// only ever expose the value through [toColor], which re-encodes). Mixing in
/// linear space gives the physically correct midpoint between two colors;
/// mixing in gamma-encoded sRGB would produce a muddy dark band — try
/// animating `red → green` to see it.
///
/// Conversion between sRGB and linear happens at the dart:ui [Color] boundary
/// in [AnimatableColor.fromColor] / [toColor].
///
/// ### Unit scale (`128.0`)
///
/// OpenSwiftUI applies a per-component scale factor of `128.0` when exposing
/// the color through `animatableData`, unapplying it on the way back. The
/// transform is invariant for `+`, `-` and `scale` (they're linear), so the
/// only externally observable effect is on [magnitudeSquared] — and that
/// matters for spring physics, whose "settled" check compares
/// `magnitudeSquared` against an absolute epsilon. With 0..1 channels the
/// untouched magnitude would be vanishingly small; pre-scaling keeps it in the
/// same order of magnitude as the rest of the animation pipeline. We mirror
/// the trick by scaling inside [magnitudeSquared].
class AnimatableColor extends VectorArithmetic<AnimatableColor> {
  static const double _unitScale = 128.0;

  final Color value;

  AnimatableColor(this.value);

  @override
  AnimatableColor operator +(AnimatableColor o) => .new(
    Color.from(
      alpha: value.a + o.value.a,
      red: value.r + o.value.r,
      green: value.g + o.value.g,
      blue: value.b + o.value.b,
    ),
  );

  @override
  AnimatableColor operator -(AnimatableColor o) => .new(
    Color.from(
      alpha: value.a - o.value.a,
      red: value.r - o.value.r,
      green: value.g - o.value.g,
      blue: value.b - o.value.b,
    ),
  );

  @override
  AnimatableColor scale(double f) => .new(
    Color.from(
      alpha: value.a * f,
      red: value.r * f,
      green: value.g * f,
      blue: value.b * f,
    ),
  );

  @override
  double get magnitudeSquared {
    final r = value.r * _unitScale;
    final g = value.g * _unitScale;
    final b = value.b * _unitScale;
    final o = value.a * _unitScale;
    return r * r + g * g + b * b + o * o;
  }

  @override
  AnimatableColor get zero =>
      .new(const Color.from(alpha: 0, red: 0, green: 0, blue: 0));

  @override
  bool operator ==(Object other) =>
      other is AnimatableColor && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'AnimatableColor($value)';
}
