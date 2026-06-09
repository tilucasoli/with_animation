# Animating a `double` — tap-to-scale

A button that scales from `1.0` to `1.2` when tapped, then back when released.

## Vanilla Flutter — `AnimationController` + `Tween`

```dart
import 'package:flutter/material.dart';

class TapToScale extends StatefulWidget {
  const TapToScale({super.key});

  @override
  State<TapToScale> createState() => _TapToScaleState();
}

class _TapToScaleState extends State<TapToScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: const FlutterLogo(size: 96),
      ),
    );
  }
}
```

You manage the controller's lifecycle, pick `forward`/`reverse` per gesture,
and the animation's "state" is the controller's position — not the scale value
itself.

## `with_animation` — `AnimatableValue` + `withAnimation`

```dart
import 'package:flutter/material.dart';
import 'package:with_animation/with_animation.dart';

class TapToScale extends StatefulWidget {
  const TapToScale({super.key});

  @override
  State<TapToScale> createState() => _TapToScaleState();
}

class _TapToScaleState extends State<TapToScale> {
  double _scale = 1.0;

  void _setScale(double next) {
    withAnimation(
      AnimationSpec.easeInOut(duration: const Duration(milliseconds: 250)),
      () => setState(() => _scale = next),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setScale(1.2),
      onTapUp: (_) => _setScale(1.0),
      onTapCancel: () => _setScale(1.0),
      child: AnimatableValue<AnimatableDouble>(
        value: AnimatableDouble(_scale),
        builder: (context, animated) => Transform.scale(
          scale: animated.value,
          child: const FlutterLogo(size: 96),
        ),
      ),
    );
  }
}
```

The state is the logical scale (`double`). You don't have a controller, you
don't call `forward`/`reverse`, and you don't decide whether to animate at
the call site of the widget — you decide it at the call site of `setState`.

## What changed

- **No `vsync`, no `dispose`.** `AnimatableValue` owns its `Ticker`.
- **No `Tween`.** You assign the target; the package computes the interval.
- **One code path for both directions.** `forward`/`reverse` disappear — you
  just set the value you want.
- **State = the value.** If you want to know the current logical scale, read
  `_scale`. With `AnimationController`, the value is `Tween.evaluate(...)`.
