import 'package:flutter_test/flutter_test.dart';

import 'package:with_animation/with_animation.dart';

void main() {
  group('AnimatorState.sample', () {
    test('returns zero delta at beginTime for a bezier animation', () {
      final state = AnimationDriver<AnimatableDouble>(
        animation: Animations(
          BezierAnimation.linear(const Duration(seconds: 1)),
        ),
        interval: AnimatableDouble(10.0),
        beginTime: Duration.zero,
      );
      final delta = state.sample(Duration.zero);
      expect(delta, isNotNull);
      expect(delta!.value, closeTo(0.0, 1e-9));
    });

    test('returns full interval at end of duration', () {
      final state = AnimationDriver<AnimatableDouble>(
        animation: Animations(
          BezierAnimation.linear(const Duration(seconds: 1)),
        ),
        interval: AnimatableDouble(10.0),
        beginTime: Duration.zero,
      );
      final delta = state.sample(const Duration(seconds: 1));
      expect(delta, isNotNull);
      expect(delta!.value, closeTo(10.0, 1e-9));
    });

    test('returns null after duration elapses', () {
      final state = AnimationDriver<AnimatableDouble>(
        animation: Animations(
          BezierAnimation.linear(const Duration(seconds: 1)),
        ),
        interval: AnimatableDouble(10.0),
        beginTime: Duration.zero,
      );
      expect(state.sample(const Duration(seconds: 2)), isNull);
    });

    test('beginTime shifts the curve', () {
      final shifted = AnimationDriver<AnimatableDouble>(
        animation: Animations(
          BezierAnimation.linear(const Duration(seconds: 1)),
        ),
        interval: AnimatableDouble(1.0),
        beginTime: const Duration(seconds: 1),
      );
      final zero = AnimationDriver<AnimatableDouble>(
        animation: Animations(
          BezierAnimation.linear(const Duration(seconds: 1)),
        ),
        interval: AnimatableDouble(1.0),
        beginTime: Duration.zero,
      );
      final shiftedSample = shifted.sample(const Duration(milliseconds: 1500));
      final zeroSample = zero.sample(const Duration(milliseconds: 500));
      expect(shiftedSample, isNotNull);
      expect(zeroSample, isNotNull);
      expect(shiftedSample!.value, closeTo(zeroSample!.value, 1e-9));
    });

    test('context persists across sample calls', () {
      final state = AnimationDriver<AnimatableDouble>(
        animation: Animations(
          BezierAnimation.linear(const Duration(seconds: 1)),
        ),
        interval: AnimatableDouble(1.0),
        beginTime: Duration.zero,
      );
      state.context.state.set<int>(42);
      // Sample doesn't mutate state for bezier; just verify it survives.
      state.sample(const Duration(milliseconds: 100));
      expect(state.context.state.get<int>(0), 42);
    });
  });
}
