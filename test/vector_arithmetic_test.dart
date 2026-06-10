import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:with_animation/with_animation.dart';

void main() {
  group('AnimatableDouble', () {
    test('addition', () {
      final r = AnimatableDouble(1.5) + AnimatableDouble(2.25);
      expect(r.value, 3.75);
    });

    test('subtraction', () {
      final r = AnimatableDouble(5.0) - AnimatableDouble(2.0);
      expect(r.value, 3.0);
    });

    test('scale', () {
      expect(AnimatableDouble(4.0).scale(0.5).value, 2.0);
      expect(AnimatableDouble(4.0).scale(0.0).value, 0.0);
      expect(AnimatableDouble(4.0).scale(-1.0).value, -4.0);
    });

    test('magnitudeSquared', () {
      expect(AnimatableDouble(3.0).magnitudeSquared, 9.0);
      expect(AnimatableDouble(0.0).magnitudeSquared, 0.0);
    });

    test('zero', () {
      expect(AnimatableDouble(42.0).zero.value, 0.0);
    });

    test('equality and hashCode', () {
      expect(AnimatableDouble(1.0) == AnimatableDouble(1.0), isTrue);
      expect(AnimatableDouble(1.0) == AnimatableDouble(1.1), isFalse);
      expect(AnimatableDouble(1.0).hashCode, AnimatableDouble(1.0).hashCode);
    });

    test('Animatable: vector getter returns self', () {
      final d = AnimatableDouble(7.0);
      expect(identical(d.vector, d), isTrue);
    });

    test('Animatable: setter mutates value in place', () {
      final d = AnimatableDouble(1.0);
      d.vector = AnimatableDouble(9.5);
      expect(d.value, 9.5);
    });

    test('Animatable: clone is detached from original', () {
      final d = AnimatableDouble(3.0);
      final copy = d.clone();
      expect(copy.value, 3.0);
      copy.value = 99.0;
      expect(d.value, 3.0);
    });
  });

  group('AnimatableOffset', () {
    test('vector getter projects dx/dy', () {
      final o = AnimatableOffset(const Offset(3, 4));
      final p = o.vector;
      expect(p.first.value, 3);
      expect(p.second.value, 4);
    });

    test('vector setter mutates the underlying Offset', () {
      final o = AnimatableOffset(Offset.zero);
      o.vector = VectorPair(AnimatableDouble(10), AnimatableDouble(20));
      expect(o.value, const Offset(10, 20));
    });

    test('clone is detached from original', () {
      final o = AnimatableOffset(const Offset(1, 2));
      final copy = o.clone();
      expect(copy.value, const Offset(1, 2));
      copy.value = const Offset(99, 99);
      expect(o.value, const Offset(1, 2));
    });

    test('projection arithmetic interpolates component-wise', () {
      final a = AnimatableOffset(const Offset(1, 2)).vector;
      final b = AnimatableOffset(const Offset(3, 4)).vector;
      final sum = a + b;
      expect(sum.first.value, 4);
      expect(sum.second.value, 6);

      final diff = b - a;
      expect(diff.first.value, 2);
      expect(diff.second.value, 2);

      final scaled = a.scale(0.5);
      expect(scaled.first.value, 0.5);
      expect(scaled.second.value, 1);
    });

    test('equality and hashCode', () {
      expect(
        AnimatableOffset(const Offset(1, 2)) ==
            AnimatableOffset(const Offset(1, 2)),
        isTrue,
      );
      expect(
        AnimatableOffset(const Offset(1, 2)) ==
            AnimatableOffset(const Offset(1, 3)),
        isFalse,
      );
      expect(
        AnimatableOffset(const Offset(1, 2)).hashCode,
        AnimatableOffset(const Offset(1, 2)).hashCode,
      );
    });
  });

  group('AnimatableColor', () {
    test('vector getter projects RGBA channels', () {
      final c = AnimatableColor(
        const Color.from(alpha: 0.4, red: 0.1, green: 0.2, blue: 0.3),
      );
      final p = c.vector;
      expect(p.first.first.value, closeTo(0.1, 1e-9));
      expect(p.first.second.value, closeTo(0.2, 1e-9));
      expect(p.second.first.value, closeTo(0.3, 1e-9));
      expect(p.second.second.value, closeTo(0.4, 1e-9));
    });

    test('vector setter assigns the underlying Color', () {
      final c = AnimatableColor(
        const Color.from(alpha: 1, red: 0, green: 0, blue: 0),
      );
      c.vector = VectorPair(
        VectorPair(AnimatableDouble(0.5), AnimatableDouble(0.6)),
        VectorPair(AnimatableDouble(0.7), AnimatableDouble(0.8)),
      );
      expect(c.value.r, closeTo(0.5, 1e-9));
      expect(c.value.g, closeTo(0.6, 1e-9));
      expect(c.value.b, closeTo(0.7, 1e-9));
      expect(c.value.a, closeTo(0.8, 1e-9));
    });

    test('setter clamps out-of-range channels', () {
      final c = AnimatableColor(
        const Color.from(alpha: 1, red: 0, green: 0, blue: 0),
      );
      // Spring overshoot can produce <0 or >1 channels mid-animation; the
      // setter clamps so the resulting Color is always valid.
      c.vector = VectorPair(
        VectorPair(AnimatableDouble(-0.5), AnimatableDouble(2.0)),
        VectorPair(AnimatableDouble(-1.0), AnimatableDouble(3.0)),
      );
      expect(c.value.r, 0.0);
      expect(c.value.g, 1.0);
      expect(c.value.b, 0.0);
      expect(c.value.a, 1.0);
    });

    test('clone is detached from original', () {
      final c = AnimatableColor(
        const Color.from(alpha: 0.4, red: 0.1, green: 0.2, blue: 0.3),
      );
      final copy = c.clone();
      expect(copy.value, c.value);
      copy.value = const Color.from(alpha: 1, red: 1, green: 1, blue: 1);
      // Original unchanged.
      expect(c.value.r, closeTo(0.1, 1e-9));
      expect(c.value.a, closeTo(0.4, 1e-9));
    });

    test('projection arithmetic interpolates component-wise', () {
      final a = AnimatableColor(
        const Color.from(alpha: 0.4, red: 0.1, green: 0.2, blue: 0.3),
      ).vector;
      final b = AnimatableColor(
        const Color.from(alpha: 0.04, red: 0.01, green: 0.02, blue: 0.03),
      ).vector;

      final sum = a + b;
      expect(sum.first.first.value, closeTo(0.11, 1e-9));
      expect(sum.first.second.value, closeTo(0.22, 1e-9));
      expect(sum.second.first.value, closeTo(0.33, 1e-9));
      expect(sum.second.second.value, closeTo(0.44, 1e-9));

      final scaled = a.scale(0.5);
      expect(scaled.first.first.value, closeTo(0.05, 1e-9));
      expect(scaled.first.second.value, closeTo(0.10, 1e-9));
      expect(scaled.second.first.value, closeTo(0.15, 1e-9));
      expect(scaled.second.second.value, closeTo(0.20, 1e-9));
    });

    test('equality and hashCode', () {
      final a = AnimatableColor(
        const Color.from(alpha: 0.4, red: 0.1, green: 0.2, blue: 0.3),
      );
      final b = AnimatableColor(
        const Color.from(alpha: 0.4, red: 0.1, green: 0.2, blue: 0.3),
      );
      final c = AnimatableColor(
        const Color.from(alpha: 0.5, red: 0.1, green: 0.2, blue: 0.3),
      );
      expect(a == b, isTrue);
      expect(a == c, isFalse);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('VectorPair', () {
    test('arithmetic delegates to both components', () {
      final p1 = VectorPair(AnimatableDouble(1.0), AnimatableDouble(2.0));
      final p2 = VectorPair(AnimatableDouble(0.5), AnimatableDouble(1.5));
      final sum = p1 + p2;
      expect(sum.first.value, 1.5);
      expect(sum.second.value, 3.5);

      final diff = p1 - p2;
      expect(diff.first.value, 0.5);
      expect(diff.second.value, 0.5);

      final scaled = p1.scale(2.0);
      expect(scaled.first.value, 2.0);
      expect(scaled.second.value, 4.0);
    });

    test('magnitudeSquared sums components', () {
      final p = VectorPair(AnimatableDouble(3.0), AnimatableDouble(4.0));
      expect(p.magnitudeSquared, 9.0 + 16.0);
    });

    test('zero', () {
      final p = VectorPair(AnimatableDouble(5.0), AnimatableDouble(7.0));
      final z = p.zero;
      expect(z.first.value, 0);
      expect(z.second.value, 0);
    });

    test('equality and hashCode', () {
      final a = VectorPair(AnimatableDouble(1.0), AnimatableDouble(2.0));
      final b = VectorPair(AnimatableDouble(1.0), AnimatableDouble(2.0));
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
    });

    test('nested pairs compose for higher-arity projections', () {
      // Matches the shape AnimatableColor uses internally:
      // Pair<Pair<Double, Double>, Pair<Double, Double>>.
      final lhs = VectorPair(
        VectorPair(AnimatableDouble(0.1), AnimatableDouble(0.2)),
        VectorPair(AnimatableDouble(0.3), AnimatableDouble(0.4)),
      );
      final scaled = lhs.scale(2.0);
      expect(scaled.first.first.value, closeTo(0.2, 1e-9));
      expect(scaled.first.second.value, closeTo(0.4, 1e-9));
      expect(scaled.second.first.value, closeTo(0.6, 1e-9));
      expect(scaled.second.second.value, closeTo(0.8, 1e-9));
    });
  });
}
