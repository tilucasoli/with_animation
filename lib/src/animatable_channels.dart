import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'animation_spec.dart';
import 'animator_state.dart';
import 'transaction.dart';
import 'animatable/vector_arithmetic.dart';

/// One animatable property inside an [AnimatableChannels]. Carries the current
/// logical value plus the [AnimationSpec] that should drive it. When [spec] is
/// non-null it overrides the ambient `withAnimation` transaction for this
/// channel; when null, the channel falls back to the transaction.
class Channel<T extends VectorArithmetic<T>> {
  final T value;
  final AnimationSpec? spec;
  const Channel({required this.value, this.spec});

  /// Captures `T` at the call site so the widget can hold a driver list
  /// without naming the generic. Internal.
  // ignore: library_private_types_in_public_api
  _ChannelDriver createDriver() => _ChannelDriverImpl<T>(value);
}

/// Multi-channel sibling of [AnimatableValue]. Runs N independent animators on
/// a single shared [Ticker] — one rebuild per frame regardless of how many
/// channels are mid-flight, instead of one rebuild per channel.
///
/// Use this when several properties must animate with **different specs** but
/// share a widget. If all properties share one spec, prefer wrapping them in
/// an [AnimatablePair]/[AnimatableArray] and using a single [AnimatableValue].
class AnimatableChannels extends StatefulWidget {
  /// Per-channel logical values and specs. The channel count is expected to
  /// be stable across rebuilds; per-channel value types must also be stable.
  final List<Channel> channels;

  /// Receives the current animated value for each channel, positionally.
  /// Destructure at the call site: `final [o, c] = values;`.
  final Widget Function(BuildContext context, List<Object> values) builder;

  const AnimatableChannels({
    super.key,
    required this.channels,
    required this.builder,
  });

  @override
  State<AnimatableChannels> createState() => _AnimatableChannelsState();
}

class _AnimatableChannelsState extends State<AnimatableChannels>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late List<_ChannelDriver> _drivers;
  Duration _tickerElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _drivers = [for (final c in widget.channels) c.createDriver()];
    _ticker = createTicker(_onTick);
  }

  @override
  void didUpdateWidget(AnimatableChannels oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(
      widget.channels.length == oldWidget.channels.length,
      'AnimatableChannels: channel count must be stable across rebuilds',
    );

    final txn = currentTransaction();
    final txnAnimation = txn?.animation;
    final disabled = txn?.disablesAnimations ?? false;
    final tickerWasActive = _ticker.isActive;

    var anyAnimating = false;
    for (var i = 0; i < widget.channels.length; i++) {
      final newCh = widget.channels[i];
      final oldCh = oldWidget.channels[i];
      final driver = _drivers[i];

      if (_channelValueEquals(newCh, oldCh)) {
        if (driver.isAnimating) anyAnimating = true;
        continue;
      }

      final spec = disabled ? null : (newCh.spec ?? txnAnimation);
      if (spec == null) {
        driver.jumpTo(newCh);
      } else {
        driver.startOrInterrupt(
          newChannel: newCh,
          oldChannel: oldCh,
          spec: spec,
          tickerElapsed: tickerWasActive ? _tickerElapsed : Duration.zero,
          interrupting: tickerWasActive && driver.isAnimating,
        );
        anyAnimating = true;
      }
    }

    if (anyAnimating) {
      if (!_ticker.isActive) {
        _tickerElapsed = Duration.zero;
        _ticker.start();
      }
    } else if (_ticker.isActive) {
      _ticker.stop();
      _tickerElapsed = Duration.zero;
    }
  }

  void _onTick(Duration elapsed) {
    _tickerElapsed = elapsed;
    var anyAnimating = false;
    for (var i = 0; i < _drivers.length; i++) {
      final driver = _drivers[i];
      if (!driver.isAnimating) continue;
      driver.tick(elapsed, widget.channels[i]);
      if (driver.isAnimating) anyAnimating = true;
    }
    setState(() {});
    if (!anyAnimating) {
      _ticker.stop();
      _tickerElapsed = Duration.zero;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(
    context,
    [for (final d in _drivers) d.displayed],
  );

  static bool _channelValueEquals(Channel a, Channel b) => a.value == b.value;
}

/// Existential wrapper that lets [_AnimatableChannelsState] hold a list of
/// per-channel drivers without naming the channel's generic parameter.
abstract class _ChannelDriver {
  Object get displayed;
  bool get isAnimating;
  void jumpTo(Channel channel);
  void startOrInterrupt({
    required Channel newChannel,
    required Channel oldChannel,
    required AnimationSpec spec,
    required Duration tickerElapsed,
    required bool interrupting,
  });
  void tick(Duration elapsed, Channel currentChannel);
}

class _ChannelDriverImpl<T extends VectorArithmetic<T>>
    implements _ChannelDriver {
  T _previous;
  T _displayed;
  AnimatorState<T>? _animator;

  _ChannelDriverImpl(T initial)
    : _previous = initial,
      _displayed = initial;

  @override
  Object get displayed => _displayed as Object;

  @override
  bool get isAnimating => _animator != null;

  @override
  void jumpTo(Channel channel) {
    final value = channel.value as T;
    _displayed = value;
    _previous = value;
    _animator = null;
  }

  @override
  void startOrInterrupt({
    required Channel newChannel,
    required Channel oldChannel,
    required AnimationSpec spec,
    required Duration tickerElapsed,
    required bool interrupting,
  }) {
    final newValue = newChannel.value as T;
    final oldValue = oldChannel.value as T;
    _previous = interrupting ? _displayed : oldValue;
    final interval = newValue - _previous;
    _animator = AnimatorState<T>(
      animation: spec,
      interval: interval,
      beginTime: tickerElapsed,
    );
  }

  @override
  void tick(Duration elapsed, Channel currentChannel) {
    final a = _animator;
    if (a == null) return;
    final target = currentChannel.value as T;
    final delta = a.sample(elapsed);
    if (delta == null) {
      _displayed = target;
      _previous = target;
      _animator = null;
      return;
    }
    _displayed = (target + delta) - a.interval;
  }
}
