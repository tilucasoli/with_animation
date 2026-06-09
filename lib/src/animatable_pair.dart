import 'vector_arithmetic.dart';

/// Composes two [VectorArithmetic] values into one. Mirror of SwiftUI's
/// `AnimatablePair<First, Second>`.
class AnimatablePair<A extends VectorArithmetic<A>,
        B extends VectorArithmetic<B>>
    extends VectorArithmetic<AnimatablePair<A, B>> {
  final A first;
  final B second;
  AnimatablePair(this.first, this.second);

  @override
  AnimatablePair<A, B> operator +(AnimatablePair<A, B> o) =>
      AnimatablePair(first + o.first, second + o.second);
  @override
  AnimatablePair<A, B> operator -(AnimatablePair<A, B> o) =>
      AnimatablePair(first - o.first, second - o.second);
  @override
  AnimatablePair<A, B> scale(double f) =>
      AnimatablePair(first.scale(f), second.scale(f));
  @override
  double get magnitudeSquared =>
      first.magnitudeSquared + second.magnitudeSquared;
  @override
  AnimatablePair<A, B> get zero => AnimatablePair(first.zero, second.zero);

  @override
  bool operator ==(Object other) =>
      other is AnimatablePair<A, B> &&
      other.first == first &&
      other.second == second;
  @override
  int get hashCode => Object.hash(first, second);
  @override
  String toString() => '($first, $second)';
}
