import 'package:flutter_test/flutter_test.dart';
import 'package:with_animation/with_animation.dart';

void main() {
  AnimatableDouble v(double x) => AnimatableDouble(x);
  AnimationContext<AnimatableDouble> ctx() => AnimationContext<AnimatableDouble>();

  group('BezierAnimation.linear', () {
    final a = BezierAnimation.linear(const Duration(seconds: 1));

    test('value at boundaries and quarters', () {
      expect(a.animate(v(1.0), 0.0, ctx())!.value, closeTo(0.0, 1e-9));
      expect(a.animate(v(1.0), 0.25, ctx())!.value, closeTo(0.25, 1e-9));
      expect(a.animate(v(1.0), 0.5, ctx())!.value, closeTo(0.5, 1e-9));
      expect(a.animate(v(1.0), 0.75, ctx())!.value, closeTo(0.75, 1e-9));
      expect(a.animate(v(1.0), 1.0, ctx())!.value, closeTo(1.0, 1e-9));
    });

    test('returns null after duration', () {
      expect(a.animate(v(1.0), 1.0001, ctx()), isNull);
      expect(a.animate(v(1.0), 5.0, ctx()), isNull);
    });

    test('scales the interval value', () {
      expect(a.animate(v(10.0), 0.5, ctx())!.value, closeTo(5.0, 1e-9));
      expect(a.animate(v(-4.0), 0.25, ctx())!.value, closeTo(-1.0, 1e-9));
    });
  });

  group('BezierAnimation.easeIn', () {
    final a = BezierAnimation.easeIn(const Duration(seconds: 1));

    test('endpoints pin to 0 and 1', () {
      expect(a.animate(v(1.0), 0.0, ctx())!.value, closeTo(0.0, 1e-6));
      expect(a.animate(v(1.0), 1.0, ctx())!.value, closeTo(1.0, 1e-6));
    });

    test('curve is below linear in the first half', () {
      final mid = a.animate(v(1.0), 0.5, ctx())!.value;
      expect(mid, lessThan(0.5));
    });
  });

  group('BezierAnimation.easeOut', () {
    final a = BezierAnimation.easeOut(const Duration(seconds: 1));

    test('endpoints pin to 0 and 1', () {
      expect(a.animate(v(1.0), 0.0, ctx())!.value, closeTo(0.0, 1e-6));
      expect(a.animate(v(1.0), 1.0, ctx())!.value, closeTo(1.0, 1e-6));
    });

    test('curve is above linear in the first half', () {
      final mid = a.animate(v(1.0), 0.5, ctx())!.value;
      expect(mid, greaterThan(0.5));
    });
  });

  group('BezierAnimation.easeInOut', () {
    final a = BezierAnimation.easeInOut(const Duration(seconds: 1));

    test('symmetric around midpoint', () {
      expect(a.animate(v(1.0), 0.5, ctx())!.value, closeTo(0.5, 0.01));
    });
  });

  // Regression for OpenSwiftUI bug #459: fraction must scale with `duration`,
  // not behave like a fixed 1-time-duration animation. The original Swift test
  // uses identity-shaped control points; the linear factory is equivalent.
  group('bug #459: fraction scales with duration', () {
    test('linear 100s scales exactly with time', () {
      final a = BezierAnimation.linear(const Duration(seconds: 100));
      expect(a.animate(v(1.0), 10.0, ctx())!.value, closeTo(0.1, 0.01));
      expect(a.animate(v(1.0), 50.0, ctx())!.value, closeTo(0.5, 0.01));
    });

    test('easeInOut 100s is symmetric around the half-point', () {
      final a = BezierAnimation.easeInOut(const Duration(seconds: 100));
      expect(a.animate(v(1.0), 50.0, ctx())!.value, closeTo(0.5, 0.01));
    });
  });

  group('edge cases', () {
    test('zero duration returns null immediately', () {
      final a = BezierAnimation.linear(Duration.zero);
      expect(a.animate(v(1.0), 0.0, ctx()), isNull);
      expect(a.animate(v(1.0), 1.0, ctx()), isNull);
    });

    test('negative time is clamped (no NaN)', () {
      final a = BezierAnimation.linear(const Duration(seconds: 1));
      final r = a.animate(v(1.0), -10.0, ctx());
      expect(r, isNotNull);
      expect(r!.value.isFinite, isTrue);
      expect(r.value, closeTo(0.0, 1e-9));
    });
  });
}
