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

/// Composes two [VectorArithmetic] values into one. Mirror of SwiftUI's
/// `AnimatablePair<First, Second>`.
class AnimatablePair<
  A extends VectorArithmetic<A>,
  B extends VectorArithmetic<B>
>
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

/// A list of [VectorArithmetic] values that itself conforms to [VectorArithmetic].
///
/// Mirror of OpenSwiftUI's `AnimatableArray<Element>`. `+`/`-` operate
/// element-wise up to `min(lhs.length, rhs.length)`; extra trailing elements
/// from `lhs` are preserved unchanged (matching the Swift package-private
/// behavior).
class AnimatableArray<E extends VectorArithmetic<E>>
    extends VectorArithmetic<AnimatableArray<E>> {
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
