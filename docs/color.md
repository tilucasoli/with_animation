# Animating a `Color`

Tap a box to swap its background between two colors with a one-second fade.

## Vanilla Flutter — `AnimationController` + `ColorTween`

```dart
import 'package:flutter/material.dart';

class TapToToggleColor extends StatefulWidget {
  const TapToToggleColor({super.key});

  @override
  State<TapToToggleColor> createState() => _TapToToggleColorState();
}

class _TapToToggleColorState extends State<TapToToggleColor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<Color?> _color;
  bool _on = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _color = ColorTween(begin: Colors.blue, end: Colors.red).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _on = !_on);
    if (_on) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _color,
        builder: (context, _) => Container(
          width: 200,
          height: 200,
          color: _color.value,
        ),
      ),
    );
  }
}
```

Things you have to manage by hand:

1. Controller lifecycle: `vsync`, `dispose`.
2. Direction selection: forward vs reverse, plus the boolean flag that tells
   them apart.
3. `ColorTween` interpolates in **gamma-encoded sRGB**, so transitions
   between saturated colors pass through a muddy mid-band (try
   `red → green`).
4. The curve and duration are wired into the controller, so making one
   particular tap instant or springy means swapping the controller's
   simulation.

## `with_animation` — `AnimatableColor`

```dart
import 'package:flutter/material.dart';
import 'package:with_animation/with_animation.dart';

class TapToToggleColor extends StatefulWidget {
  const TapToToggleColor({super.key});

  @override
  State<TapToToggleColor> createState() => _TapToToggleColorState();
}

class _TapToToggleColorState extends State<TapToToggleColor> {
  bool _on = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        withAnimation(
          .easeInOut(duration: const .new(seconds: 1)),
          () => setState(() { _on = !_on }),
        );
      },
      child: AnimatableValue<AnimatableColor>(
        value: AnimatableColor(_on ? Colors.red : Colors.blue),
        builder: (context, animated) => Container(
          width: 200,
          height: 200,
          color: animated.value,
        ),
      ),
    );
  }
}
```

## What changed

- **No controller, no `vsync`, no `dispose`.** `AnimatableValue` owns its
  ticker and tears it down when the widget unmounts.
- **No `forward`/`reverse` branching.** You assign the value you want; the
  package picks the interval.
- **Linear sRGB interpolation.** `AnimatableColor` stores channels as
  extended-range linear floats, so `red → green` passes through a physically
  correct olive midpoint instead of a dirty brown.
- **The animation is per-`setState`, not per-controller.** If you decide
  later that a particular tap should jump rather than fade, drop the
  `withAnimation` wrapper at that call site:
  ```dart
  setState(() => _color = Colors.red); // jumps
  ```
- **Disable animations selectively** via `withTransaction`:
  ```dart
  withTransaction(
    const Transaction(disablesAnimations: true),
    () => setState(() => _color = Colors.red),
  );
  ```
