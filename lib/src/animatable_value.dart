import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'animation_spec.dart';
import 'animator_state.dart';
import 'transaction.dart';
import 'animatable/animatable_data.dart';
import 'animatable/vector_arithmetic.dart';

/// Wraps a logical [AnimatableData] of type [T] and animates changes to it.
///
/// On every change to `value`, reads the current [Transaction] (set by
/// `withAnimation`) and spins up an animator that produces a sequence of
/// interpolated projection values delivered to `builder`.
///
/// Unlike `AnimatedFoo` widgets, this is value-typed and delta-based: state
/// does not own a Tween. It owns a `V interval` and a current [AnimatorState]
/// that produces scaled deltas added on top of the previous projection. The
/// user's `widget.value` is treated as the target wrapper; the widget keeps a
/// frame-local clone that it mutates via [AnimatableData.animatableData] so
/// the user's instance is never scribbled over.
class AnimatableValue<
  T extends AnimatableData<V>,
  V extends CustomVectorArithmetic<V>
>
    extends StatefulWidget {
  final T value;

  /// Animation to use if no transaction is active. Usually `null`.
  final AnimationSpec? defaultAnimation;

  final Widget Function(BuildContext context, T animatedValue) builder;

  const AnimatableValue({
    super.key,
    required this.value,
    required this.builder,
    this.defaultAnimation,
  });

  @override
  State<AnimatableValue<T, V>> createState() => _AnimatableValueState<T, V>();
}

class _AnimatableValueState<
  T extends AnimatableData<V>,
  V extends CustomVectorArithmetic<V>
>
    extends State<AnimatableValue<T, V>>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  AnimatorState<V>? _animator;
  late V _previous; // projection at the start of the current animator's interval
  late T _displayed; // mutable, frame-local clone of the wrapper
  Duration _tickerElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _previous = widget.value.animatableData;
    _displayed = widget.value.clone() as T;
    _ticker = createTicker(_onTick);
  }

  @override
  void didUpdateWidget(AnimatableValue<T, V> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldData = oldWidget.value.animatableData;
    final target = widget.value.animatableData;
    if (oldData == target) return;

    final txn = currentTransaction();
    final animation = txn?.animation ?? widget.defaultAnimation;
    final disabled = txn?.disablesAnimations ?? false;

    if (animation == null || disabled) {
      _animator = null;
      _previous = target;
      _displayed.animatableData = target;
      if (_ticker.isActive) _ticker.stop();
      _tickerElapsed = Duration.zero;
      return;
    }

    // Pivot point: from the currently displayed projection when interrupting
    // an animation in flight; from the previous logical value when starting
    // fresh.
    if (_ticker.isActive) {
      _previous = _displayed.animatableData;
    } else {
      _previous = oldData;
      _tickerElapsed = Duration.zero; // Ticker resets `elapsed` on start.
    }

    final interval = target - _previous;
    _animator = AnimatorState<V>(
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
      final target = widget.value.animatableData;
      setState(() {
        _displayed.animatableData = target;
        _previous = target;
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
      _displayed.animatableData =
          (widget.value.animatableData + delta) - a.interval;
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
