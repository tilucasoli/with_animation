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
      final r =
          AnimatableOffset(const Offset(1, 2)) +
          AnimatableOffset(const Offset(3, 4));
      expect(r.value.dx, 4);
      expect(r.value.dy, 6);
    });

    test('subtraction', () {
      final r =
          AnimatableOffset(const Offset(5, 7)) -
          AnimatableOffset(const Offset(2, 3));
      expect(r.value.dx, 3);
      expect(r.value.dy, 4);
    });

    test('scale', () {
      final r = AnimatableOffset(const Offset(2, 4)).scale(0.5);
      expect(r.value.dx, 1);
      expect(r.value.dy, 2);
    });

    test('magnitudeSquared sums components', () {
      expect(AnimatableOffset(const Offset(3, 4)).magnitudeSquared, 25.0);
      expect(AnimatableOffset(const Offset(0, 0)).magnitudeSquared, 0.0);
    });

    test('zero', () {
      final z = AnimatableOffset(const Offset(10, 20)).zero;
      expect(z.value.dx, 0);
      expect(z.value.dy, 0);
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
    // Unit scale OpenSwiftUI applies inside Color.Resolved.animatableData.
    const unitScale = 128.0;

    test('fromColor → toColor round-trips an 8-bit sRGB color', () {
      const c = Color.fromARGB(200, 100, 150, 50);
      final ac = AnimatableColor(c);
      // Round-trip should land back on the exact same 8-bit values after
      // sRGB → linear → sRGB. (Compared in 8-bit space because the linear
      // round-trip leaves sub-1/255 noise in the float channels.)
      expect(ac.value.toARGB32(), c.toARGB32());
    });

    // test('fromColor stores channels in Linear sRGB space', () {
    //   const c = Color.fromARGB(255, 128, 128, 128);
    //   final ac = AnimatableColor(c);
    //   // 0x80 / 255 = 0.5019…; linearised that's ~0.2158, well below 0.5.
    //   expect(ac.value.r, closeTo(0.2158, 0.005));
    //   expect(ac.value.g, closeTo(0.2158, 0.005));
    //   expect(ac.value.b, closeTo(0.2158, 0.005));
    //   expect(ac.value.a, closeTo(1.0, 1e-9));
    // });

    test('toColor clamps out-of-range channels', () {
      // After gamma encoding, -0.5 → some negative sRGB → clamps to 0 byte;
      // 2.0 → > 1.0 sRGB → clamps to 255 byte.
      final negative = AnimatableColor(
        const Color.from(alpha: -0.5, red: -0.5, green: -0.5, blue: 2.0),
      );
      final clamped = negative.value.toARGB32();
      expect((clamped >> 24) & 0xff, 0);
      expect((clamped >> 16) & 0xff, 0);
      expect((clamped >> 8) & 0xff, 0);
      expect(clamped & 0xff, 255);
    });

    test('arithmetic is component-wise on linear channels', () {
      final a = AnimatableColor(
        const Color.from(alpha: 0.4, red: 0.1, green: 0.2, blue: 0.3),
      );
      final b = AnimatableColor(
        const Color.from(alpha: 0.04, red: 0.01, green: 0.02, blue: 0.03),
      );

      final sum = a + b;
      expect(sum.value.r, closeTo(0.11, 1e-9));
      expect(sum.value.g, closeTo(0.22, 1e-9));
      expect(sum.value.b, closeTo(0.33, 1e-9));
      expect(sum.value.a, closeTo(0.44, 1e-9));

      final diff = a - b;
      expect(diff.value.r, closeTo(0.09, 1e-9));
      expect(diff.value.g, closeTo(0.18, 1e-9));
      expect(diff.value.b, closeTo(0.27, 1e-9));
      expect(diff.value.a, closeTo(0.36, 1e-9));

      final scaled = a.scale(0.5);
      expect(scaled.value.r, closeTo(0.05, 1e-9));
      expect(scaled.value.g, closeTo(0.10, 1e-9));
      expect(scaled.value.b, closeTo(0.15, 1e-9));
      expect(scaled.value.a, closeTo(0.20, 1e-9));
    });

    test('magnitudeSquared applies the OpenSwiftUI unitScale (128)', () {
      // sum of (channel * 128)^2 across the four channels.
      final ac = AnimatableColor(
        const Color.from(alpha: 0.0, red: 0.1, green: 0.2, blue: 0.2),
      );
      const expected =
          0.1 * unitScale * (0.1 * unitScale) +
          0.2 * unitScale * (0.2 * unitScale) +
          0.2 * unitScale * (0.2 * unitScale) +
          0.0;
      expect(ac.magnitudeSquared, closeTo(expected, 1e-9));
    });

    test('zero', () {
      final z = AnimatableColor(
        const Color.from(alpha: 1.0, red: 0.5, green: 0.5, blue: 0.5),
      ).zero;
      expect(z.value.r, 0);
      expect(z.value.g, 0);
      expect(z.value.b, 0);
      expect(z.value.a, 0);
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
        AnimatableDouble(1.0),
        AnimatableOffset(const Offset(2, 3)),
      );
      final p2 = AnimatablePair(
        AnimatableDouble(0.5),
        AnimatableOffset(const Offset(1, 1)),
      );
      final sum = p1 + p2;
      expect(sum.first.value, 1.5);
      expect(sum.second.value.dx, 3);
      expect(sum.second.value.dy, 4);

      final scaled = p1.scale(2.0);
      expect(scaled.first.value, 2.0);
      expect(scaled.second.value.dx, 4);
      expect(scaled.second.value.dy, 6);
    });

    test('magnitudeSquared sums components', () {
      final p = AnimatablePair(
        AnimatableDouble(3.0),
        AnimatableOffset(const Offset(0, 4)),
      );
      expect(p.magnitudeSquared, 9.0 + 16.0);
    });

    test('zero', () {
      final p = AnimatablePair(
        AnimatableDouble(5.0),
        AnimatableOffset(const Offset(1, 2)),
      );
      final z = p.zero;
      expect(z.first.value, 0);
      expect(z.second.value.dx, 0);
      expect(z.second.value.dy, 0);
    });

    test('equality and hashCode', () {
      final a = AnimatablePair(
        AnimatableDouble(1.0),
        AnimatableOffset(const Offset(2, 3)),
      );
      final b = AnimatablePair(
        AnimatableDouble(1.0),
        AnimatableOffset(const Offset(2, 3)),
      );
      expect(a == b, isTrue);
      expect(a.hashCode, b.hashCode);
    });
  });
}
