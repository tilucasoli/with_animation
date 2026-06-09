import 'vector_arithmetic.dart';

/// An empty type for animatable data.
///
/// Mirror of OpenSwiftUI's `EmptyAnimatableData`. Suitable for types that have
/// no animatable properties — every operation is a no-op and the value is its
/// own zero.
class EmptyAnimatableData extends CustomVectorArithmetic<EmptyAnimatableData> {
  EmptyAnimatableData();

  @override
  EmptyAnimatableData operator +(EmptyAnimatableData o) =>
      EmptyAnimatableData();
  @override
  EmptyAnimatableData operator -(EmptyAnimatableData o) =>
      EmptyAnimatableData();
  @override
  EmptyAnimatableData scale(double f) => EmptyAnimatableData();
  @override
  double get magnitudeSquared => 0;
  @override
  EmptyAnimatableData get zero => EmptyAnimatableData();

  @override
  bool operator ==(Object other) => other is EmptyAnimatableData;
  @override
  int get hashCode => 0;
  @override
  String toString() => 'EmptyAnimatableData()';
}
