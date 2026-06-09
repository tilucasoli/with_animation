import '../animation_context.dart';
import 'custom_animation.dart';
import '../animatable/vector_arithmetic.dart';

/// Per-instance state kept on the [AnimationContext] across frames.
class _RepeatState {
  int index = 0;
  double timeOffset = 0.0;
}

/// Wraps a [CustomAnimation] and replays it `repeatCount` times, optionally
/// alternating direction. Mirror of OpenSwiftUI's `RepeatAnimation` /
/// `Animation.repeatCount` / `Animation.repeatForever`.
///
/// Use `double.infinity` for [repeatCount] to repeat forever.
class RepeatAnimation extends CustomAnimation {
  final CustomAnimation base;
  final double repeatCount;
  final bool autoreverses;

  RepeatAnimation({
    required this.base,
    required this.repeatCount,
    this.autoreverses = true,
  });

  @override
  T? animate<T extends VectorArithmetic<T>>(
    T value,
    double time,
    AnimationContext<T> context,
  ) {
    if (repeatCount <= 0) return null;

    final state = context.state.get<_RepeatState?>(null) ?? _RepeatState();
    context.state.set<_RepeatState?>(state);

    while (true) {
      if (state.index >= repeatCount) return null;

      final elapsed = time - state.timeOffset;
      final isReversed = state.index.isOdd && autoreverses;
      final inner = base.animate<T>(value, elapsed, context);

      if (inner != null) {
        return isReversed ? value - inner : inner;
      }

      // Base finished this cycle. Advance and let the next cycle sample at
      // elapsed = 0 in the same frame (or terminate if we're out of cycles).
      state.index += 1;
      state.timeOffset = time;
    }
  }
}
