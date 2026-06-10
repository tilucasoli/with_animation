/// Vector-space contract every animatable projection must satisfy.
///
/// Any value that participates in animation must be able to add, subtract,
/// and scale by a `double`. `magnitudeSquared` is used by spring physics to
/// detect "settled" state.
abstract class VectorArithmetic<Self extends VectorArithmetic<Self>> {
  double get magnitudeSquared;
  Self get zero;

  const VectorArithmetic();

  Self operator +(Self other);
  Self operator -(Self other);
  Self scale(double factor);
}

/// Composes two [VectorArithmetic] values into one, so a pair of independent
/// axes can be animated together as a single projection.
class VectorPair<A extends VectorArithmetic<A>, B extends VectorArithmetic<B>>
    extends VectorArithmetic<VectorPair<A, B>> {
  final A first;
  final B second;

  const VectorPair(this.first, this.second);

  @override
  VectorPair<A, B> operator +(VectorPair<A, B> o) =>
      VectorPair(first + o.first, second + o.second);
  @override
  VectorPair<A, B> operator -(VectorPair<A, B> o) =>
      VectorPair(first - o.first, second - o.second);
  @override
  VectorPair<A, B> scale(double f) =>
      VectorPair(first.scale(f), second.scale(f));
  @override
  double get magnitudeSquared =>
      first.magnitudeSquared + second.magnitudeSquared;
  @override
  VectorPair<A, B> get zero => VectorPair(first.zero, second.zero);

  @override
  bool operator ==(Object other) =>
      other is VectorPair<A, B> &&
      other.first == first &&
      other.second == second;
  @override
  int get hashCode => Object.hash(first, second);
  @override
  String toString() => '($first, $second)';
}

/// A list of [VectorArithmetic] values that itself conforms to
/// [VectorArithmetic].
///
/// `+`/`-` operate element-wise up to `min(lhs.length, rhs.length)`; extra
/// trailing elements from `lhs` are preserved unchanged.
class VectorList<E extends VectorArithmetic<E>>
    extends VectorArithmetic<VectorList<E>> {
  final List<E> elements;

  VectorList(List<E> elements) : elements = List<E>.from(elements);

  @override
  VectorList<E> operator +(VectorList<E> o) {
    final next = List<E>.from(elements);
    final count = next.length < o.elements.length
        ? next.length
        : o.elements.length;
    for (var i = 0; i < count; i++) {
      next[i] = next[i] + o.elements[i];
    }
    return VectorList<E>(next);
  }

  @override
  VectorList<E> operator -(VectorList<E> o) {
    final next = List<E>.from(elements);
    final count = next.length < o.elements.length
        ? next.length
        : o.elements.length;
    for (var i = 0; i < count; i++) {
      next[i] = next[i] - o.elements[i];
    }
    return VectorList<E>(next);
  }

  @override
  VectorList<E> scale(double f) =>
      VectorList<E>(elements.map((e) => e.scale(f)).toList());

  @override
  double get magnitudeSquared =>
      elements.fold<double>(0, (acc, e) => acc + e.magnitudeSquared);

  @override
  VectorList<E> get zero => VectorList<E>(const []);

  @override
  bool operator ==(Object other) {
    if (other is! VectorList<E>) return false;
    if (other.elements.length != elements.length) return false;
    for (var i = 0; i < elements.length; i++) {
      if (other.elements[i] != elements[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(elements);

  @override
  String toString() => 'VectorList($elements)';
}
