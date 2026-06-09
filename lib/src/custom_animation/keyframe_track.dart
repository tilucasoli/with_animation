import '../animatable/vector_arithmetic.dart';
import '../animation_context.dart';
import 'bezier_animation.dart';
import 'custom_animation.dart';
import 'fluid_spring_animation.dart';

/// A single waypoint on a [KeyframeTrack]: the target [value] to reach and the
/// [duration] of the segment that leads into it from the previous keyframe (or
/// from `value.zero` for the first keyframe).
///
/// Each factory picks a [CustomAnimation] to drive that segment, so keyframes
/// compose only the package's existing animation primitives — no [Curve]
/// dependency leaks into the public API.
///
/// Mirror of SwiftUI's `LinearKeyframe` / `CubicKeyframe` / `SpringKeyframe`,
/// parameterised by `(value, duration)` rather than `(value, duration, curve)`.
class Keyframe<T extends VectorArithmetic<T>> {
  final T value;
  final Duration duration;
  final CustomAnimation animation;

  Keyframe._({
    required this.value,
    required this.duration,
    required this.animation,
  });

  factory Keyframe.linear(T value, Duration duration) => Keyframe._(
    value: value,
    duration: duration,
    animation: BezierAnimation.linear(duration),
  );

  factory Keyframe.easeIn(T value, Duration duration) => Keyframe._(
    value: value,
    duration: duration,
    animation: BezierAnimation.easeIn(duration),
  );

  factory Keyframe.easeOut(T value, Duration duration) => Keyframe._(
    value: value,
    duration: duration,
    animation: BezierAnimation.easeOut(duration),
  );

  factory Keyframe.easeInOut(T value, Duration duration) => Keyframe._(
    value: value,
    duration: duration,
    animation: BezierAnimation.easeInOut(duration),
  );

  /// A spring-driven segment. The spring's perceptual `response` is matched to
  /// [duration] so the spring's natural pace aligns with the slot it has been
  /// allotted on the timeline. [bounce] maps to a damping fraction the same way
  /// SwiftUI's modern spring presets do.
  factory Keyframe.spring(T value, Duration duration, {double bounce = 0}) =>
      Keyframe._(
        value: value,
        duration: duration,
        animation: FluidSpringAnimation(
          response: duration.inMicroseconds / 1e6,
          dampingFraction: fluidSpringDampingFraction(bounce),
        ),
      );
}

class _KeyframeTrackState<T extends VectorArithmetic<T>> {
  int index = 0;
  double segmentStart = 0;
  final List<AnimationContext<T>> childCtxs;
  _KeyframeTrackState(this.childCtxs);
}

/// Sequences a list of [Keyframe]s along one shared timeline. The track is
/// itself a [CustomAnimation], so it composes with [AnimationSpec] modifiers
/// like `speed` and `repeatCount` exactly like any other animation in this
/// package.
///
/// Semantics:
/// * Segment `i` starts at the cumulative time of all prior segments and runs
///   for `keyframes[i].duration`. Inside it, the child animation receives the
///   delta `keyframes[i].value − previousValue` as its interval and local time
///   `time − segmentStart`.
/// * The timeline is authoritative: a segment ends exactly at its declared
///   duration even if the child (e.g. an unsettled spring) has not finished.
///   At the boundary the value snaps to `keyframes[i].value`.
/// * Returns `null` once the cumulative time exceeds every segment.
class KeyframeTrack<T extends VectorArithmetic<T>> extends CustomAnimation {
  final List<Keyframe<T>> keyframes;
  KeyframeTrack(this.keyframes);

  @override
  U? animate<U extends VectorArithmetic<U>>(
    U value,
    double time,
    AnimationContext<U> context,
  ) {
    if (keyframes.isEmpty) return null;

    var state = context.state.get<_KeyframeTrackState<U>?>(null);
    if (state == null) {
      state = _KeyframeTrackState<U>(
        List.generate(keyframes.length, (_) => AnimationContext<U>()),
      );
      context.state.set<_KeyframeTrackState<U>?>(state);
    }

    while (state.index < keyframes.length) {
      final kf = keyframes[state.index];
      final segDur = kf.duration.inMicroseconds / 1e6;
      final localTime = time - state.segmentStart;

      if (localTime >= segDur) {
        // Segment timed out — its target value is locked in as the new
        // baseline and we advance to the next one.
        state.segmentStart += segDur;
        state.index += 1;
        continue;
      }

      final baseline = state.index == 0
          ? value.zero
          : (keyframes[state.index - 1].value as U);
      final delta = (kf.value as U) - baseline;
      final t = localTime < 0 ? 0.0 : localTime;
      final progress = kf.animation.animate<U>(
        delta,
        t,
        state.childCtxs[state.index],
      );
      return baseline + (progress ?? delta);
    }

    return null;
  }
}

class _ParallelKeyframeTracksState<
  A extends VectorArithmetic<A>,
  B extends VectorArithmetic<B>
> {
  final AnimationContext<A> ctxA;
  final AnimationContext<B> ctxB;
  bool firstDone = false;
  bool secondDone = false;
  _ParallelKeyframeTracksState(this.ctxA, this.ctxB);
}

/// Runs two child [CustomAnimation]s in parallel on the two halves of an
/// [AnimatablePair]. Typically each child is a [KeyframeTrack] over its own
/// [VectorArithmetic] type, mirroring SwiftUI's
/// `Keyframes { KeyframeTrack(\.scale){…}; KeyframeTrack(\.offset){…} }`.
///
/// For three or more independent tracks, nest pairs the same way the rest of
/// the package already does with [AnimatablePair].
///
/// Semantics:
/// * Each track keeps its own timeline. When one finishes it holds at its
///   declared target (the interval value) while the other continues.
/// * Returns `null` only once both children have returned `null`.
class ParallelKeyframeTracks<
  A extends VectorArithmetic<A>,
  B extends VectorArithmetic<B>
>
    extends CustomAnimation {
  final CustomAnimation first;
  final CustomAnimation second;
  ParallelKeyframeTracks(this.first, this.second);

  @override
  U? animate<U extends VectorArithmetic<U>>(
    U value,
    double time,
    AnimationContext<U> context,
  ) {
    final pair = value as AnimatablePair<A, B>;

    var state = context.state.get<_ParallelKeyframeTracksState<A, B>?>(null);
    if (state == null) {
      state = _ParallelKeyframeTracksState<A, B>(
        AnimationContext<A>(),
        AnimationContext<B>(),
      );
      context.state.set<_ParallelKeyframeTracksState<A, B>?>(state);
    }

    A? a;
    if (!state.firstDone) {
      a = first.animate<A>(pair.first, time, state.ctxA);
      if (a == null) state.firstDone = true;
    }

    B? b;
    if (!state.secondDone) {
      b = second.animate<B>(pair.second, time, state.ctxB);
      if (b == null) state.secondDone = true;
    }

    if (state.firstDone && state.secondDone) return null;

    return AnimatablePair<A, B>(a ?? pair.first, b ?? pair.second) as U;
  }
}
