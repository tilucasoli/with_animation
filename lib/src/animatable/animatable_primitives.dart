import 'animatable_data.dart';
import 'vector_arithmetic.dart';

/// Boxed `double` that conforms to [CustomVectorArithmetic].
///
/// Mirrors OpenSwiftUI's `Float`/`Double`/`CGFloat` conformances, which all
/// collapse to a single floating-point type in Dart. Also conforms to
/// [AnimatableData] with itself as its own projection so it can be passed
/// directly to [AnimatableValue].
class DoubleVectorArithmetic
    extends CustomVectorArithmetic<DoubleVectorArithmetic>
    implements AnimatableData<DoubleVectorArithmetic> {
  double value;
  DoubleVectorArithmetic(this.value);

  @override
  DoubleVectorArithmetic operator +(DoubleVectorArithmetic o) =>
      DoubleVectorArithmetic(value + o.value);
  @override
  DoubleVectorArithmetic operator -(DoubleVectorArithmetic o) =>
      DoubleVectorArithmetic(value - o.value);
  @override
  DoubleVectorArithmetic scale(double f) => DoubleVectorArithmetic(value * f);
  @override
  double get magnitudeSquared => value * value;
  @override
  DoubleVectorArithmetic get zero => DoubleVectorArithmetic(0);

  @override
  DoubleVectorArithmetic get animatableData => this;
  @override
  set animatableData(DoubleVectorArithmetic value) {
    this.value = value.value;
  }

  @override
  DoubleVectorArithmetic clone() => DoubleVectorArithmetic(value);

  @override
  bool operator ==(Object other) =>
      other is DoubleVectorArithmetic && other.value == value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => 'AnimatableDouble($value)';
}

/// Boxed `int` that conforms to [CustomVectorArithmetic].
///
/// Interpolation is carried out in `double` space so that fractional scales
/// (e.g. mid-animation samples) do not collapse small integers to zero. The
/// public [value] getter rounds back to the nearest `int`. Also conforms to
/// [AnimatableData] with itself as its own projection.
class IntVectorArithmetic
    extends CustomVectorArithmetic<IntVectorArithmetic>
    implements AnimatableData<IntVectorArithmetic> {
  double _value;

  IntVectorArithmetic(int value) : _value = value.toDouble();
  IntVectorArithmetic._raw(this._value);

  int get value => _value.round();

  @override
  IntVectorArithmetic operator +(IntVectorArithmetic o) =>
      IntVectorArithmetic._raw(_value + o._value);
  @override
  IntVectorArithmetic operator -(IntVectorArithmetic o) =>
      IntVectorArithmetic._raw(_value - o._value);
  @override
  IntVectorArithmetic scale(double f) => IntVectorArithmetic._raw(_value * f);
  @override
  double get magnitudeSquared => _value * _value;
  @override
  IntVectorArithmetic get zero => IntVectorArithmetic._raw(0);

  @override
  IntVectorArithmetic get animatableData => this;
  @override
  set animatableData(IntVectorArithmetic value) {
    _value = value._value;
  }

  @override
  IntVectorArithmetic clone() => IntVectorArithmetic._raw(_value);

  @override
  bool operator ==(Object other) =>
      other is IntVectorArithmetic && other._value == _value;
  @override
  int get hashCode => _value.hashCode;
  @override
  String toString() => 'AnimatableInt($value)';
}
