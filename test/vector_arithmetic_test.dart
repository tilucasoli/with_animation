import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:with_animation/with_animation.dart';

void main() {
  group('AnimatableDouble', () {
    test('addition', () {
      final r = DoubleVectorArithmetic(1.5) + DoubleVectorArithmetic(2.25);
      expect(r.value, 3.75);
    });

    test('subtraction', () {
      final r = DoubleVectorArithmetic(5.0) - DoubleVectorArithmetic(2.0);
      expect(r.value, 3.0);
    });

    test('scale', () {
      expect(DoubleVectorArithmetic(4.0).scale(0.5).value, 2.0);
      expect(DoubleVectorArithmetic(4.0).scale(0.0).value, 0.0);
      expect(DoubleVectorArithmetic(4.0).scale(-1.0).value, -4.0);
    });

    test('magnitudeSquared', () {
      expect(DoubleVectorArithmetic(3.0).magnitudeSquared, 9.0);
      expect(DoubleVectorArithmetic(0.0).magnitudeSquared, 0.0);
    });

    test('zero', () {
      expect(DoubleVectorArithmetic(42.0).zero.value, 0.0);
    });

    test('equality and hashCode', () {
      expect(
        DoubleVectorArithmetic(1.0) == DoubleVectorArithmetic(1.0),
        isTrue,
      );
      expect(
        DoubleVectorArithmetic(1.0) == DoubleVectorArithmetic(1.1),
        isFalse,
      );
      expect(
        DoubleVectorArithmetic(1.0).hashCode,
        DoubleVectorArithmetic(1.0).hashCode,
      );
    });

    test('AnimatableData: animatableData getter returns self', () {
      final d = DoubleVectorArithmetic(7.0);
      expect(identical(d.animatableData, d), isTrue);
    });

    test('AnimatableData: setter mutates value in place', () {
      final d = DoubleVectorArithmetic(1.0);
      d.animatableData = DoubleVectorArithmetic(9.5);
      expect(d.value, 9.5);
    });

    test('AnimatableData: clone is detached from original', () {
      final d = DoubleVectorArithmetic(3.0);
      final copy = d.clone();
      expect(copy.value, 3.0);
      copy.value = 99.0;
      expect(d.value, 3.0);
    });
  });

  group('AnimatableOffset', () {
    test('animatableData getter projects dx/dy', () {
      final o = AnimatableOffset(const Offset(3, 4));
      final p = o.animatableData;
      expect(p.first.value, 3);
      expect(p.second.value, 4);
    });

    test('animatableData setter mutates the underlying Offset', () {
      final o = AnimatableOffset(Offset.zero);
      o.animatableData = AnimatablePair(
        DoubleVectorArithmetic(10),
        DoubleVectorArithmetic(20),
      );
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
      final a = AnimatableOffset(const Offset(1, 2)).animatableData;
      final b = AnimatableOffset(const Offset(3, 4)).animatableData;
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
    test('animatableData getter projects RGBA channels', () {
      final c = AnimatableColor(
        const Color.from(alpha: 0.4, red: 0.1, green: 0.2, blue: 0.3),
      );
      final p = c.animatableData;
      expect(p.first.first.value, closeTo(0.1, 1e-9));
      expect(p.first.second.value, closeTo(0.2, 1e-9));
      expect(p.second.first.value, closeTo(0.3, 1e-9));
      expect(p.second.second.value, closeTo(0.4, 1e-9));
    });

    test('animatableData setter assigns the underlying Color', () {
      final c = AnimatableColor(
        const Color.from(alpha: 1, red: 0, green: 0, blue: 0),
      );
      c.animatableData = AnimatablePair(
        AnimatablePair(DoubleVectorArithmetic(0.5), DoubleVectorArithmetic(0.6)),
        AnimatablePair(DoubleVectorArithmetic(0.7), DoubleVectorArithmetic(0.8)),
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
      c.animatableData = AnimatablePair(
        AnimatablePair(DoubleVectorArithmetic(-0.5), DoubleVectorArithmetic(2.0)),
        AnimatablePair(DoubleVectorArithmetic(-1.0), DoubleVectorArithmetic(3.0)),
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
      ).animatableData;
      final b = AnimatableColor(
        const Color.from(alpha: 0.04, red: 0.01, green: 0.02, blue: 0.03),
      ).animatableData;

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

  group('AnimatablePair', () {
    test('arithmetic delegates to both components', () {
      final p1 = AnimatablePair(
        DoubleVectorArithmetic(1.0),
        DoubleVectorArithmetic(2.0),
      );
      final p2 = AnimatablePair(
        DoubleVectorArithmetic(0.5),
        DoubleVectorArithmetic(1.5),
      );
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
      final p = AnimatablePair(
        DoubleVectorArithmetic(3.0),
        DoubleVectorArithmetic(4.0),
      );
      expect(p.magnitudeSquared, 9.0 + 16.0);
    });

    test('zero', () {
      final p = AnimatablePair(
        DoubleVectorArithmetic(5.0),
        DoubleVectorArithmetic(7.0),
      );
      final z = p.zero;
      expect(z.first.value, 0);
      expect(z.second.value, 0);
    });

    test('equality and hashCode', () {
      final a = AnimatablePair(
        DoubleVectorArithmetic(1.0),
        DoubleVectorArithmetic(2.0),
      );
      final b = AnimatablePair(
        DoubleVectorArithmetic(1.0),
        DoubleVectorArithmetic(2.0),
      );
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
    });

    test('nested pairs compose for higher-arity projections', () {
      // Matches the shape AnimatableColor uses internally:
      // Pair<Pair<Double, Double>, Pair<Double, Double>>.
      final lhs = AnimatablePair(
        AnimatablePair(DoubleVectorArithmetic(0.1), DoubleVectorArithmetic(0.2)),
        AnimatablePair(DoubleVectorArithmetic(0.3), DoubleVectorArithmetic(0.4)),
      );
      final scaled = lhs.scale(2.0);
      expect(scaled.first.first.value, closeTo(0.2, 1e-9));
      expect(scaled.first.second.value, closeTo(0.4, 1e-9));
      expect(scaled.second.first.value, closeTo(0.6, 1e-9));
      expect(scaled.second.second.value, closeTo(0.8, 1e-9));
    });
  });
}
