import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'animation.dart' as sa;
import 'animator_state.dart';
import 'transaction.dart';
import 'vector_arithmetic.dart';

/// Wraps a logical value of type [T] and animates changes to it.
///
/// On every change to `value`, reads the current [Transaction] (set by
/// `withAnimation`) and spins up an animator that produces a sequence of
/// interpolated values delivered to `builder`.
///
/// Unlike `AnimatedFoo` widgets, this is value-typed and delta-based: the
/// state does not own a Tween. It owns a `T interval` and a current
/// [AnimatorState] that produces scaled deltas added on top of the previous
/// value. The user's `widget.value` source of truth flows through unchanged.
class AnimatableValue<T extends VectorArithmetic<T>> extends StatefulWidget {
  final T value;

  /// Animation to use if no transaction is active. Usually `null`.
  final sa.Animation? defaultAnimation;

  final Widget Function(BuildContext context, T animatedValue) builder;

  const AnimatableValue({
    super.key,
    required this.value,
    required this.builder,
    this.defaultAnimation,
  });

  @override
  State<AnimatableValue<T>> createState() => _AnimatableValueState<T>();
}

class _AnimatableValueState<T extends VectorArithmetic<T>>
    extends State<AnimatableValue<T>> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  AnimatorState<T>? _animator;
  late T _previous; // start of the current animator's interval
  late T _displayed; // what we paint this frame
  Duration _tickerElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _previous = widget.value;
    _displayed = widget.value;
    _ticker = createTicker(_onTick);
  }

  @override
  void didUpdateWidget(AnimatableValue<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) return;

    final txn = currentTransaction();
    final animation = txn?.animation ?? widget.defaultAnimation;
    final disabled = txn?.disablesAnimations ?? false;

    if (animation == null || disabled) {
      _animator = null;
      _previous = widget.value;
      _displayed = widget.value;
      if (_ticker.isActive) _ticker.stop();
      _tickerElapsed = Duration.zero;
      return;
    }

    // Pivot point: from the currently displayed value when interrupting an
    // animation in flight; from the previous logical value when starting fresh.
    if (_ticker.isActive) {
      _previous = _displayed;
    } else {
      _previous = oldWidget.value;
      _tickerElapsed = Duration.zero; // Ticker resets `elapsed` on start.
    }

    final interval = widget.value - _previous;
    _animator = AnimatorState<T>(
      animation: animation,
      interval: interval,
      beginTime: _tickerElapsed,
    );
    if (!_ticker.isActive) _ticker.start();
  }

  void _onTick(Duration elapsed) {
    _tickerElapsed = elapsed;
    final a = _animator;
    if (a == null) return;

    final delta = a.sample(elapsed);
    if (delta == null) {
      setState(() {
        _displayed = widget.value;
        _previous = widget.value;
        _animator = null;
      });
      _ticker.stop();
      _tickerElapsed = Duration.zero;
      return;
    }
    // The SwiftUI output transform, ported:
    //   displayed = target + scaledInterval - fullInterval
    // Early in the animation, scaledInterval ≈ 0, so displayed ≈ previous.
    // Late in the animation, scaledInterval ≈ interval, so displayed ≈ target.
    setState(() {
      _displayed = (widget.value + delta) - a.interval;
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _displayed);
}
