import 'dart:ui';

import 'animatable_color.dart';
import 'animatable_double.dart';
import 'animatable_offset.dart';
import 'empty_animatable_data.dart';

/// Dart port of OpenSwiftUI's `VectorArithmetic` protocol.
///
/// Any value that participates in animation must be able to add, subtract,
/// and scale by a `double`. `magnitudeSquared` is used by spring physics to
/// detect "settled" state.
abstract class CustomVectorArithmetic<T extends CustomVectorArithmetic<T>> {
  T operator +(T other);
  T operator -(T other);
  T scale(double factor);
  double get magnitudeSquared;
  T get zero;
}

/// Composes two [CustomVectorArithmetic] values into one. Mirror of SwiftUI's
/// `AnimatablePair<First, Second>`.
class AnimatablePair<
  A extends CustomVectorArithmetic<A>,
  B extends CustomVectorArithmetic<B>
>
    extends CustomVectorArithmetic<AnimatablePair<A, B>> {
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

/// A list of [CustomVectorArithmetic] values that itself conforms to
/// [CustomVectorArithmetic].
///
/// Mirror of OpenSwiftUI's `AnimatableArray<Element>`. `+`/`-` operate
/// element-wise up to `min(lhs.length, rhs.length)`; extra trailing elements
/// from `lhs` are preserved unchanged (matching the Swift package-private
/// behavior).
class AnimatableArray<E extends CustomVectorArithmetic<E>>
    extends CustomVectorArithmetic<AnimatableArray<E>> {
  final List<E> elements;

  AnimatableArray(List<E> elements) : elements = List<E>.from(elements);

  @override
  AnimatableArray<E> operator +(AnimatableArray<E> o) {
    final next = List<E>.from(elements);
    final count = next.length < o.elements.length
        ? next.length
        : o.elements.length;
    for (var i = 0; i < count; i++) {
      next[i] = next[i] + o.elements[i];
    }
    return AnimatableArray<E>(next);
  }

  @override
  AnimatableArray<E> operator -(AnimatableArray<E> o) {
    final next = List<E>.from(elements);
    final count = next.length < o.elements.length
        ? next.length
        : o.elements.length;
    for (var i = 0; i < count; i++) {
      next[i] = next[i] - o.elements[i];
    }
    return AnimatableArray<E>(next);
  }

  @override
  AnimatableArray<E> scale(double f) =>
      AnimatableArray<E>(elements.map((e) => e.scale(f)).toList());

  @override
  double get magnitudeSquared =>
      elements.fold<double>(0, (acc, e) => acc + e.magnitudeSquared);

  @override
  AnimatableArray<E> get zero => AnimatableArray<E>(const []);

  @override
  bool operator ==(Object other) {
    if (other is! AnimatableArray<E>) return false;
    if (other.elements.length != elements.length) return false;
    for (var i = 0; i < elements.length; i++) {
      if (other.elements[i] != elements[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(elements);

  @override
  String toString() => 'AnimatableArray($elements)';
}

/// Type-erased handle around a [CustomVectorArithmetic] value, with static
/// factories for the pre-built conformers. Mirror of [AnimationSpec]'s
/// relationship to `CustomAnimation`.
class VectorArithmetic {
  final CustomVectorArithmetic base;
  const VectorArithmetic(this.base);

  /// Wraps a `double` as an [AnimatableDouble].
  static VectorArithmetic double_(double value) =>
      VectorArithmetic(AnimatableDouble(value));

  /// Wraps an [Offset] as an [AnimatableOffset].
  static VectorArithmetic offset(Offset offset) =>
      VectorArithmetic(AnimatableOffset(offset));

  /// Wraps a [Color] as an [AnimatableColor].
  static VectorArithmetic color(Color color) =>
      VectorArithmetic(AnimatableColor(color));

  /// An [EmptyAnimatableData] placeholder for types with no animatable data.
  static VectorArithmetic empty() => VectorArithmetic(EmptyAnimatableData());

  /// Composes two [CustomVectorArithmetic] values into a single
  /// [AnimatablePair].
  static VectorArithmetic pair<
    A extends CustomVectorArithmetic<A>,
    B extends CustomVectorArithmetic<B>
  >(A first, B second) =>
      VectorArithmetic(AnimatablePair<A, B>(first, second));

  /// Wraps a list of [CustomVectorArithmetic] values as an [AnimatableArray].
  static VectorArithmetic array<E extends CustomVectorArithmetic<E>>(
    List<E> elements,
  ) => VectorArithmetic(AnimatableArray<E>(elements));
}
