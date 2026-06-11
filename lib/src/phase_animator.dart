import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart' hide Animatable, Animation;

import 'animatable/animatable.dart';
import 'animation_driver.dart';
import 'animations.dart';
import 'transaction.dart';

/// Cycles through a sequence of [phases] and rebuilds [builder] with the
/// active phase, wrapping each transition in `withAnimation` so any
/// [AnimatableValue] inside [builder] animates from one phase to the next.
///
/// Modelled after SwiftUI's `PhaseAnimator`. Two modes:
///
/// * **Continuous** ([trigger] is `null`): on mount, the widget steps through
///   the phases forever — `phases[0] → phases[1] → … → phases[n-1] →
///   phases[0] → …`.
/// * **Triggered** ([trigger] non-null): each change to [trigger] (by `==`)
///   runs `n` transitions, cycling through every phase and back to
///   `phases[0]` — `phases[0] → phases[1] → … → phases[n-1] → phases[0]`.
///   This matches SwiftUI's behaviour: the animation associated with
///   `phases[0]` plays on the return-to-rest step.
///
/// The [animation] callback is consulted with the *destination* phase, so
/// each step can use its own spec. If it returns `null` (or is omitted) the
/// widget falls back to [defaultAnimation]; if both are `null` the step is
/// instantaneous.
///
/// Completion of each step is detected by sampling an internal unit
/// [AnimationDriver] against the same spec — this works uniformly for fixed
/// duration curves and for springs (which signal completion by settling).
class PhaseAnimator<Phase> extends StatefulWidget {
  final List<Phase> phases;
  final Object? trigger;
  final Widget Function(BuildContext context, Phase phase) builder;
  final Animations? Function(Phase phase)? animation;
  final Animations? defaultAnimation;

  const PhaseAnimator({
    super.key,
    required this.phases,
    required this.builder,
    this.trigger,
    this.animation,
    this.defaultAnimation,
  });

  @override
  State<PhaseAnimator<Phase>> createState() => _PhaseAnimatorState<Phase>();
}

class _PhaseAnimatorState<Phase> extends State<PhaseAnimator<Phase>>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  int _phaseIndex = 0;
  int _stepsRemaining = 0; // triggered mode: transitions left in current run
  AnimationDriver<AnimatableDouble>? _timer;
  Duration _tickerElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    assert(widget.phases.isNotEmpty, 'PhaseAnimator.phases must be non-empty');
    _ticker = createTicker(_onTick);
    // Continuous mode: start the cycle after the first frame so children
    // mount on phases[0] before we begin animating to phases[1].
    if (widget.trigger == null && widget.phases.length > 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _advance();
      });
    }
  }

  @override
  void didUpdateWidget(PhaseAnimator<Phase> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_phaseIndex >= widget.phases.length) _phaseIndex = 0;
    if (widget.trigger != oldWidget.trigger && widget.trigger != null) {
      // Each trigger change runs `n` transitions, cycling through every
      // phase and ending back on phases[0]. A retrigger while a previous
      // run is still in flight resets the step counter, extending the cycle
      // — the in-flight animation pivots from the displayed value via
      // [AnimatableValue]'s interrupt rule.
      _stepsRemaining = widget.phases.length;
      _advance();
    }
  }

  /// Step to the next phase. Wraps in continuous mode; counts down
  /// `_stepsRemaining` in triggered mode.
  void _advance() {
    if (widget.trigger != null) {
      if (_stepsRemaining <= 0) {
        _stopTimer();
        return;
      }
      _stepsRemaining--;
    }
    _animateTo((_phaseIndex + 1) % widget.phases.length);
  }

  void _animateTo(int next) {
    final destination = widget.phases[next];
    final spec = widget.animation?.call(destination) ?? widget.defaultAnimation;

    if (spec == null) {
      // No animation for this step: snap, then schedule the next step in
      // continuous mode. The post-frame defer prevents a same-frame
      // recursion when an entire phase list has null animations.
      setState(() => _phaseIndex = next);
      if (widget.trigger == null && widget.phases.length > 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _advance();
        });
      }
      return;
    }

    withAnimation(spec, () => setState(() => _phaseIndex = next));

    // Pivot the timer: if the ticker is already running, beginTime is the
    // current elapsed (so the next sample returns deltas relative to now);
    // otherwise reset elapsed and start the ticker fresh.
    if (_ticker.isActive) {
      _timer = AnimationDriver<AnimatableDouble>(
        animation: spec,
        interval: AnimatableDouble(1.0),
        beginTime: _tickerElapsed,
      );
    } else {
      _tickerElapsed = Duration.zero;
      _timer = AnimationDriver<AnimatableDouble>(
        animation: spec,
        interval: AnimatableDouble(1.0),
        beginTime: Duration.zero,
      );
      _ticker.start();
    }
  }

  void _stopTimer() {
    _timer = null;
    if (_ticker.isActive) _ticker.stop();
    _tickerElapsed = Duration.zero;
  }

  void _onTick(Duration elapsed) {
    _tickerElapsed = elapsed;
    final t = _timer;
    if (t == null) return;
    if (t.sample(elapsed) == null) {
      _timer = null;
      _advance();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, widget.phases[_phaseIndex]);
}
