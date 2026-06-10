# with_animation

SwiftUI-style declarative animation primitives for Flutter.

> [!WARNING]
> **Work in progress.** This package is in early development and not yet ready for production use. APIs may change without notice.

Change a value inside `withAnimation(...)` and any `AnimatableValue` watching it
animates from its currently displayed value to the new one — no
`AnimationController`, no `Tween`, no `vsync`, no `dispose`. Interruptions pivot
from the displayed value automatically.

```dart
double _scale = 1.0;

void _grow() => withAnimation(
  Animations.spring(),
  () => setState(() => _scale = 1.2),
);

@override
Widget build(BuildContext context) {
  return AnimatableValue<AnimatableDouble>(
    value: AnimatableDouble(_scale),
    builder: (context, animated) => Transform.scale(
      scale: animated.value,
      child: const FlutterLogo(size: 96),
    ),
  );
}
```

## Features

- **State-driven.** You change the logical value; the package computes the
  animation. No `forward`/`reverse` branching, no controller lifecycle.
- **Interruption-safe.** Mid-flight target changes pivot from the displayed
  value, so re-targeting never snaps.
- **Spring physics as a first-class spec.** `Animations.spring(...)`,
  `smooth()`, `snappy()`, `bouncy()`, `interactiveSpring()`, plus a
  perceptual `fluidSpring(response:, dampingFraction:)`.
- **Color in linear sRGB.** `AnimatableColor` interpolates in extended-range
  linear floats, so `red → green` passes through a physically correct olive
  midpoint instead of muddy brown.
- **No boilerplate.** `AnimatableValue` owns its `Ticker` and tears it down on
  unmount.
- **Composable.** `.speed(...)`, `.repeatCount(...)`, `.repeatForever()` on any
  spec; `AnimatablePair` and `AnimatableArray` for custom vector types.

## Mental model

| Flutter                                                       | `with_animation`                                       |
| ------------------------------------------------------------- | ------------------------------------------------------ |
| You drive the animation (`controller.forward`)                | You change state; the animation follows                |
| State is the `Animation<T>` object                            | State is the logical value (a `double`, `Color`, etc.) |
| Interruption = curve restart from 0                           | Interruption = pivot from current displayed value      |
| Spring physics needs `AnimationController` + custom simulation | `Animations.spring(...)` is a first-class spec        |
| `vsync`, `dispose`, controller lifecycle is yours             | `AnimatableValue` owns its `Ticker`                    |

## Getting started

Add the package to `pubspec.yaml`:

```yaml
dependencies:
  with_animation:
    git:
      url: https://github.com/tilucasoli/with_animation
```

Import it:

```dart
import 'package:with_animation/with_animation.dart';
```

> [!NOTE]
> Requires Dart `^3.11.0` and Flutter `>=3.0.0`.

## Usage

### Animate a `double`

```dart
class TapToScale extends StatefulWidget {
  const TapToScale({super.key});
  @override
  State<TapToScale> createState() => _TapToScaleState();
}

class _TapToScaleState extends State<TapToScale> {
  double _scale = 1.0;

  void _setScale(double next) => withAnimation(
    Animations.easeInOut(duration: const Duration(milliseconds: 250)),
    () => setState(() => _scale = next),
  );

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

### Animate a `Color`

```dart
withAnimation(
  Animations.easeInOut(duration: const Duration(seconds: 1)),
  () => setState(() => _on = !_on),
);

// ...
AnimatableValue<AnimatableColor>(
  value: AnimatableColor(_on ? Colors.red : Colors.blue),
  builder: (context, animated) => Container(
    width: 200, height: 200, color: animated.value,
  ),
);
```

### Animate an `Offset` with spring physics

```dart
GestureDetector(
  onPanUpdate: (d) => setState(() => _offset += d.delta), // tracks finger 1:1
  onPanEnd: (_) => withAnimation(
    Animations.spring(mass: 1, stiffness: 100, damping: 10),
    () => setState(() => _offset = Offset.zero),
  ),
  child: AnimatableValue<AnimatableOffset>(
    value: AnimatableOffset(_offset),
    builder: (context, animated) => Transform.translate(
      offset: animated.value,
      child: Container(width: 80, height: 80, color: Colors.indigo),
    ),
  ),
);
```

### Disable animations selectively

Skip the `withAnimation` wrapper to jump instantly, or use a transaction to
disable explicitly:

```dart
setState(() => _color = Colors.red); // jumps

withTransaction(
  const Transaction(disablesAnimations: true),
  () => setState(() => _color = Colors.red),
);
```

## Animation specs

All specs are constructed through the `Animations` namespace:

| Spec                              | Use                                                  |
| --------------------------------- | ---------------------------------------------------- |
| `Animations.linear(duration:)`    | Constant-rate timing curve                           |
| `Animations.easeIn(duration:)`    | Eases into the target                                |
| `Animations.easeOut(duration:)`   | Eases out of the start                               |
| `Animations.easeInOut(duration:)` | Symmetric ease                                       |
| `Animations.spring(mass:, stiffness:, damping:)` | Classic mass-spring-damper system     |
| `Animations.fluidSpring(response:, dampingFraction:, blendDuration:)` | Perceptually parameterised spring |
| `Animations.smooth(duration:)`    | Non-bouncy spring preset                             |
| `Animations.snappy(duration:)`    | Slightly bouncy spring preset                        |
| `Animations.bouncy(duration:)`    | Noticeably bouncy spring preset                      |
| `Animations.interactiveSpring()`  | Short, responsive spring for driving gestures        |

Modifiers:

```dart
Animations.easeInOut().speed(2.0);              // 2× faster
Animations.spring().repeatCount(3);             // play 3 times, auto-reverse
Animations.linear().repeatForever();            // forever, auto-reverse
```

## Built-in `Animatable` types

| Type                | Wraps           |
| ------------------- | --------------- |
| `AnimatableDouble`  | `double`        |
| `AnimatableInt`     | `int`           |
| `AnimatableOffset`  | `Offset`        |
| `AnimatableColor`   | `Color` (linear sRGB) |

Build composites with `AnimatablePair` and `AnimatableArray`, or implement
`Animatable<V>` directly for your own domain types.

## Documentation

In-depth comparisons with vanilla Flutter, side by side:

- [`docs/scale.md`](docs/scale.md) — animating a `double` (tap-to-scale button)
- [`docs/color.md`](docs/color.md) — animating a `Color` (tap-to-change background)
- [`docs/spring.md`](docs/spring.md) — spring physics
- [`docs/interruption.md`](docs/interruption.md) — what happens when state changes mid-animation

## Acknowledgements

This package would not exist without the work of [SwiftUI](https://developer.apple.com/xcode/swiftui/)
and [OpenSwiftUI](https://github.com/OpenSwiftUIProject/OpenSwiftUI). The API
shape, the mental model, and most of the underlying animation algorithms
(`AnimatableValue`, `withAnimation`, spring physics, the projection-based
interruption rule) are direct ports of ideas pioneered there. All credit for
the design goes to those projects — this package is simply an attempt to bring
that ergonomics to Flutter.
