import 'package:flutter_test/flutter_test.dart';
import 'package:with_animation/with_animation.dart';

void main() {
  AnimatableDouble v(double x) => AnimatableDouble(x);
  AnimationContext<AnimatableDouble> ctx() =>
      AnimationContext<AnimatableDouble>();

  group('Keyframe factories', () {
    test('linear/easeIn/easeOut/easeInOut build a BezierAnimation', () {
      final d = const Duration(milliseconds: 200);
      expect(Keyframe.linear(v(1), d).animation, isA<BezierAnimation>());
      expect(Keyframe.easeIn(v(1), d).animation, isA<BezierAnimation>());
      expect(Keyframe.easeOut(v(1), d).animation, isA<BezierAnimation>());
      expect(Keyframe.easeInOut(v(1), d).animation, isA<BezierAnimation>());
    });

    test('spring builds a FluidSpringAnimation', () {
      expect(
        Keyframe.spring(v(1), const Duration(milliseconds: 300)).animation,
        isA<FluidSpringAnimation>(),
      );
    });

    test('value and duration are stored verbatim', () {
      final kf = Keyframe.linear(v(0.7), const Duration(milliseconds: 250));
      expect(kf.value.value, 0.7);
      expect(kf.duration, const Duration(milliseconds: 250));
    });
  });

  group('KeyframeTrack — single linear segment', () {
    final track = KeyframeTrack<AnimatableDouble>([
      Keyframe.linear(v(1.0), const Duration(milliseconds: 200)),
    ]);

    test('interpolates from 0 to value across the duration', () {
      final c = ctx();
      expect(track.animate(v(1.0), 0.0, c)!.value, closeTo(0.0, 1e-9));
      expect(track.animate(v(1.0), 0.1, c)!.value, closeTo(0.5, 1e-6));
    });

    test('returns null once past the total duration', () {
      final c = ctx();
      for (double t = 0.0; t < 0.2; t += 0.01) {
        track.animate(v(1.0), t, c);
      }
      expect(track.animate(v(1.0), 0.2001, c), isNull);
    });

    test('empty keyframes list completes immediately', () {
      final empty = KeyframeTrack<AnimatableDouble>(const []);
      expect(empty.animate(v(1.0), 0.0, ctx()), isNull);
    });
  });

  group('KeyframeTrack — multi-segment handoff', () {
    AnimationContext<AnimatableDouble> walkUntil(
      KeyframeTrack<AnimatableDouble> track,
      double target,
    ) {
      final c = ctx();
      for (double t = 0.0; t <= target; t += 0.005) {
        track.animate(v(1.0), t, c);
      }
      return c;
    }

    test('passes through declared targets at segment boundaries', () {
      final track = KeyframeTrack<AnimatableDouble>([
        Keyframe.linear(v(1.0), const Duration(milliseconds: 200)),
        Keyframe.linear(v(0.5), const Duration(milliseconds: 200)),
      ]);

      // Just past the first segment boundary the second segment is starting
      // from the locked-in 1.0 baseline.
      final c = walkUntil(track, 0.2);
      final atBoundary = track.animate(v(1.0), 0.2001, c)!.value;
      expect(atBoundary, closeTo(1.0, 0.02));

      // End of the second segment lands on the declared target.
      final atEnd = track.animate(v(1.0), 0.3999, c)!.value;
      expect(atEnd, closeTo(0.5, 0.05));
      expect(track.animate(v(1.0), 0.4001, c), isNull);
    });

    test('animates through an overshoot waypoint then back down', () {
      final track = KeyframeTrack<AnimatableDouble>([
        Keyframe.easeOut(v(1.2), const Duration(milliseconds: 200)),
        Keyframe.easeIn(v(1.0), const Duration(milliseconds: 200)),
      ]);

      double peak = 0;
      final c = ctx();
      for (double t = 0.0; t <= 0.4; t += 0.005) {
        final r = track.animate(v(1.0), t, c);
        if (r == null) break;
        if (r.value > peak) peak = r.value;
      }
      expect(peak, greaterThan(1.0));
      expect(peak, lessThanOrEqualTo(1.2 + 1e-6));
    });
  });

  group('KeyframeTrack — strict timeline', () {
    test('spring segment snaps to declared target at the boundary even when '
        'its physics has not settled', () {
      // Very long spring response, short slot — the spring cannot possibly
      // reach 1.0 in 50 ms on its own.
      final track = KeyframeTrack<AnimatableDouble>([
        Keyframe.spring(v(1.0), const Duration(milliseconds: 50), bounce: 0.5),
        Keyframe.linear(v(0.0), const Duration(milliseconds: 100)),
      ]);

      final c = ctx();
      for (double t = 0.0; t <= 0.05; t += 0.001) {
        track.animate(v(1.0), t, c);
      }
      // Just into the second segment, baseline is locked at 1.0 and the
      // linear segment is at the very start.
      final justAfter = track.animate(v(1.0), 0.051, c)!.value;
      expect(justAfter, closeTo(1.0, 0.05));
    });
  });

  group('KeyframeTrack — non-scalar interval', () {
    test('works on AnimatableOffset', () {
      final track = KeyframeTrack<AnimatableOffset>([
        Keyframe.linear(
          AnimatableOffset(const Offset(10, 20)),
          const Duration(milliseconds: 100),
        ),
      ]);
      final c = AnimationContext<AnimatableOffset>();
      final mid = track
          .animate(AnimatableOffset(const Offset(10, 20)), 0.05, c)!
          .value;
      expect(mid.dx, closeTo(5.0, 1e-6));
      expect(mid.dy, closeTo(10.0, 1e-6));
    });
  });

  group('ParallelKeyframeTracks', () {
    AnimatablePair<AnimatableDouble, AnimatableOffset> pair(
      double a,
      Offset b,
    ) => AnimatablePair(AnimatableDouble(a), AnimatableOffset(b));

    test('animates both halves independently mid-segment', () {
      final scale = KeyframeTrack<AnimatableDouble>([
        Keyframe.linear(v(1.0), const Duration(milliseconds: 200)),
      ]);
      final offset = KeyframeTrack<AnimatableOffset>([
        Keyframe.linear(
          AnimatableOffset(const Offset(100, 0)),
          const Duration(milliseconds: 200),
        ),
      ]);

      final track = ParallelKeyframeTracks<AnimatableDouble, AnimatableOffset>(
        scale,
        offset,
      );
      final c =
          AnimationContext<
            AnimatablePair<AnimatableDouble, AnimatableOffset>
          >();
      final interval = pair(1.0, const Offset(100, 0));

      final mid = track.animate(interval, 0.1, c)!;
      expect(mid.first.value, closeTo(0.5, 1e-6));
      expect(mid.second.value.dx, closeTo(50.0, 1e-6));
    });

    test('short track holds at its target while long track continues, then '
        'composite completes when both finish', () {
      final shortTrack = KeyframeTrack<AnimatableDouble>([
        Keyframe.linear(v(1.0), const Duration(milliseconds: 100)),
      ]);
      final longTrack = KeyframeTrack<AnimatableOffset>([
        Keyframe.linear(
          AnimatableOffset(const Offset(100, 0)),
          const Duration(milliseconds: 300),
        ),
      ]);

      final track = ParallelKeyframeTracks<AnimatableDouble, AnimatableOffset>(
        shortTrack,
        longTrack,
      );
      final c =
          AnimationContext<
            AnimatablePair<AnimatableDouble, AnimatableOffset>
          >();
      final interval = pair(1.0, const Offset(100, 0));

      // Drive both halves through the short track's timeline.
      for (double t = 0.0; t <= 0.1; t += 0.005) {
        track.animate(interval, t, c);
      }

      // Long track is still running; short track is held at its 1.0 target.
      final between = track.animate(interval, 0.15, c)!;
      expect(between.first.value, closeTo(1.0, 1e-9));
      expect(between.second.value.dx, closeTo(50.0, 1.0));

      // Past the long track too — composite completes.
      for (double t = 0.15; t <= 0.3; t += 0.005) {
        track.animate(interval, t, c);
      }
      expect(track.animate(interval, 0.3001, c), isNull);
    });
  });

  group('AnimationSpec integration', () {
    test('keyframeTrack factory wires through to the sequencer', () {
      final spec = AnimationSpec.keyframeTrack<AnimatableDouble>([
        Keyframe.linear(v(1.0), const Duration(milliseconds: 100)),
      ]);
      expect(spec.base, isA<KeyframeTrack<AnimatableDouble>>());
    });

    test('parallelKeyframeTracks factory wires through to the composite', () {
      final spec =
          AnimationSpec.parallelKeyframeTracks<
            AnimatableDouble,
            AnimatableOffset
          >(
            KeyframeTrack<AnimatableDouble>(const []),
            KeyframeTrack<AnimatableOffset>(const []),
          );
      expect(
        spec.base,
        isA<ParallelKeyframeTracks<AnimatableDouble, AnimatableOffset>>(),
      );
    });
  });
}
