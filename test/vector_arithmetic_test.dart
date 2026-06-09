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
  });

  group('AnimatableOffset', () {
    test('addition', () {
      final r = AnimatableOffset(1, 2) + AnimatableOffset(3, 4);
      expect(r.dx, 4);
      expect(r.dy, 6);
    });

    test('subtraction', () {
      final r = AnimatableOffset(5, 7) - AnimatableOffset(2, 3);
      expect(r.dx, 3);
      expect(r.dy, 4);
    });

    test('scale', () {
      final r = AnimatableOffset(2, 4).scale(0.5);
      expect(r.dx, 1);
      expect(r.dy, 2);
    });

    test('magnitudeSquared sums components', () {
      expect(AnimatableOffset(3, 4).magnitudeSquared, 25.0);
      expect(AnimatableOffset(0, 0).magnitudeSquared, 0.0);
    });

    test('zero', () {
      final z = AnimatableOffset(10, 20).zero;
      expect(z.dx, 0);
      expect(z.dy, 0);
    });

    test('equality and hashCode', () {
      expect(AnimatableOffset(1, 2) == AnimatableOffset(1, 2), isTrue);
      expect(AnimatableOffset(1, 2) == AnimatableOffset(1, 3), isFalse);
      expect(
        AnimatableOffset(1, 2).hashCode,
        AnimatableOffset(1, 2).hashCode,
      );
    });
  });

  group('AnimatableColor', () {
    test('fromColor → toColor round-trips', () {
      const c = Color.fromARGB(200, 100, 150, 50);
      final ac = AnimatableColor.fromColor(c);
      expect(ac.toColor(), c);
    });

    test('fromInt → toInt round-trips', () {
      const c = Color.fromARGB(255, 12, 34, 56);
      final ac = AnimatableColor.fromInt(c.value);
      expect(ac.toInt(), c.value);
    });

    test('toColor clamps out-of-range channels', () {
      final negative = AnimatableColor(-10, -50, 300, 1000);
      final clamped = negative.toColor();
      expect(clamped.alpha, 0);
      expect(clamped.red, 0);
      expect(clamped.green, 255);
      expect(clamped.blue, 255);
    });

    test('arithmetic is component-wise linear', () {
      final a = AnimatableColor(10, 20, 30, 40);
      final b = AnimatableColor(1, 2, 3, 4);
      final sum = a + b;
      expect(sum.a, 11);
      expect(sum.r, 22);
      expect(sum.g, 33);
      expect(sum.b, 44);

      final diff = a - b;
      expect(diff.a, 9);
      expect(diff.r, 18);
      expect(diff.g, 27);
      expect(diff.b, 36);

      final scaled = a.scale(0.5);
      expect(scaled.a, 5);
      expect(scaled.r, 10);
      expect(scaled.g, 15);
      expect(scaled.b, 20);
    });

    test('magnitudeSquared sums squared channels', () {
      expect(AnimatableColor(1, 2, 2, 0).magnitudeSquared, 1 + 4 + 4 + 0);
    });

    test('zero', () {
      final z = AnimatableColor(255, 255, 255, 255).zero;
      expect(z.a, 0);
      expect(z.r, 0);
      expect(z.g, 0);
      expect(z.b, 0);
    });

    test('equality and hashCode', () {
      final a = AnimatableColor(1, 2, 3, 4);
      final b = AnimatableColor(1, 2, 3, 4);
      final c = AnimatableColor(1, 2, 3, 5);
      expect(a == b, isTrue);
      expect(a == c, isFalse);
      expect(a.hashCode, b.hashCode);
    });
  });

  group('AnimatablePair', () {
    test('arithmetic delegates to both components', () {
      final p1 = AnimatablePair(
        AnimatableDouble(1.0),
        AnimatableOffset(2, 3),
      );
      final p2 = AnimatablePair(
        AnimatableDouble(0.5),
        AnimatableOffset(1, 1),
      );
      final sum = p1 + p2;
      expect(sum.first.value, 1.5);
      expect(sum.second.dx, 3);
      expect(sum.second.dy, 4);

      final scaled = p1.scale(2.0);
      expect(scaled.first.value, 2.0);
      expect(scaled.second.dx, 4);
      expect(scaled.second.dy, 6);
    });

    test('magnitudeSquared sums components', () {
      final p = AnimatablePair(
        AnimatableDouble(3.0),
        AnimatableOffset(0, 4),
      );
      expect(p.magnitudeSquared, 9.0 + 16.0);
    });

    test('zero', () {
      final p = AnimatablePair(
        AnimatableDouble(5.0),
        AnimatableOffset(1, 2),
      );
      final z = p.zero;
      expect(z.first.value, 0);
      expect(z.second.dx, 0);
      expect(z.second.dy, 0);
    });

    test('equality and hashCode', () {
      final a = AnimatablePair(
        AnimatableDouble(1.0),
        AnimatableOffset(2, 3),
      );
      final b = AnimatablePair(
        AnimatableDouble(1.0),
        AnimatableOffset(2, 3),
      );
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
    });
  });
}
