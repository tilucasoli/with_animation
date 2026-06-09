# Keyframe animations

Keyframes let you describe an animation as a list of waypoints. Each waypoint
declares a **target value** and the **duration** of the segment that reaches it.
The segment between two waypoints is driven by an existing `CustomAnimation` —
bezier, spring, or whatever you want — picked via a `Keyframe` factory.

Mirror of SwiftUI's `KeyframeTrack` / `KeyframeAnimator`, adapted to this
package's `VectorArithmetic` model.

## Concepts

- **`Keyframe<T>`** — a single waypoint: `(value, duration, animation)`. You
  never construct one directly; you pick a factory matching the easing you
  want.
- **`KeyframeTrack<T>`** — sequences a list of `Keyframe<T>` along one shared
  timeline. Itself a `CustomAnimation`, so it composes with `.repeatCount(...)`,
  `.speed(...)`, etc.
- **`ParallelKeyframeTracks<A, B>`** — runs two tracks side-by-side on the two
  halves of an `AnimatablePair<A, B>`, enabling independent timelines for
  different `VectorArithmetic` types.

## Keyframe factories

Each factory builds the appropriate `CustomAnimation` for the segment leading
into the keyframe:

| Factory                                          | Backed by              |
|--------------------------------------------------|------------------------|
| `Keyframe.linear(value, duration)`               | `BezierAnimation.linear`     |
| `Keyframe.easeIn(value, duration)`               | `BezierAnimation.easeIn`     |
| `Keyframe.easeOut(value, duration)`              | `BezierAnimation.easeOut`    |
| `Keyframe.easeInOut(value, duration)`            | `BezierAnimation.easeInOut`  |
| `Keyframe.spring(value, duration, bounce: 0.0)`  | `FluidSpringAnimation`        |

`Keyframe.spring`'s `bounce` parameter maps to a damping fraction the same way
SwiftUI's modern spring presets do — `0` is critically damped, positive values
bounce, negative values overdamp.

## Single-property timeline: `KeyframeTrack`

Animate one property through several phases — ease out to the target, spring
past it, then ease back down. The target values are in the same space as the
animation's interval (the start of the animation corresponds to `value.zero`).

```dart
import 'package:with_animation/with_animation.dart';

final spec = AnimationSpec.keyframeTrack<AnimatableDouble>([
  Keyframe.easeOut(AnimatableDouble(1.0), const Duration(milliseconds: 200)),
  Keyframe.spring (AnimatableDouble(1.2), const Duration(milliseconds: 300),
                   bounce: 0.4),
  Keyframe.easeIn (AnimatableDouble(1.0), const Duration(milliseconds: 300)),
]);

// Drive an AnimatableValue widget with the spec:
class _ScaleDemo extends StatefulWidget {
  const _ScaleDemo();
  @override
  State<_ScaleDemo> createState() => _ScaleDemoState();
}

class _ScaleDemoState extends State<_ScaleDemo> {
  AnimatableDouble scale = AnimatableDouble(0);

  void _bump() => withAnimation(
        spec,
        () => setState(() => scale = AnimatableDouble(1)),
      );

  @override
  Widget build(BuildContext context) {
    return AnimatableValue<AnimatableDouble>(
      value: scale,
      builder: (context, animated) =>
          Transform.scale(scale: animated.value, child: const FlutterLogo()),
    );
  }
}
```

Works on any `VectorArithmetic` type — `AnimatableDouble`, `AnimatableOffset`,
`AnimatableColor`, or your own.

```dart
final slideTrack = AnimationSpec.keyframeTrack<AnimatableOffset>([
  Keyframe.easeOut(AnimatableOffset(const Offset(100, 0)),
                   const Duration(milliseconds: 250)),
  Keyframe.easeInOut(AnimatableOffset(const Offset(100, 50)),
                     const Duration(milliseconds: 250)),
]);
```

### Strict timeline

A segment ends exactly at its declared `duration`. If the underlying animation
hasn't finished yet (e.g. a spring is still mid-bounce), the value **snaps to
the keyframe's declared target** at the boundary, and the next segment starts
from there.

This matches SwiftUI's `KeyframeAnimator` semantics: durations are
authoritative, the spring just has to fit. Keep a spring's segment duration
roughly aligned with its perceptual response if you want the snap to be
invisible.

## Multiple properties in parallel: `ParallelKeyframeTracks`

To animate two properties on independent timelines, wrap each in its own
`KeyframeTrack`, then combine them. The combined animation operates on an
`AnimatablePair`:

```dart
final scaleTrack = KeyframeTrack<AnimatableDouble>([
  Keyframe.spring(AnimatableDouble(1.2), const Duration(milliseconds: 300),
                  bounce: 0.4),
  Keyframe.easeIn(AnimatableDouble(1.0), const Duration(milliseconds: 200)),
]);

final offsetTrack = KeyframeTrack<AnimatableOffset>([
  Keyframe.linear(AnimatableOffset(const Offset(100, 0)),
                  const Duration(milliseconds: 500)),
]);

final spec = AnimationSpec.parallelKeyframeTracks<
  AnimatableDouble, AnimatableOffset
>(scaleTrack, offsetTrack);
```

The animated value is an `AnimatablePair`. Drive it the same way as any other
`AnimatableValue`, then read each half from `animated.first` / `animated.second`
inside the builder:

```dart
AnimatableValue<AnimatablePair<AnimatableDouble, AnimatableOffset>>(
  value: AnimatablePair(scale, offset),
  builder: (context, animated) => Transform.translate(
    offset: animated.second.value,
    child: Transform.scale(
      scale: animated.first.value,
      child: child,
    ),
  ),
);

// Trigger an animated update:
withAnimation(spec, () => setState(() {
  scale  = AnimatableDouble(1.0);
  offset = AnimatableOffset(const Offset(100, 0));
}));
```

### Independent completion

Each track ends when its own keyframes run out. While a shorter track is
finished, its half is **held at its declared target value** while the longer
track continues. The composite returns `null` (completes) only when both
children have completed.

### Three or more tracks

For more than two properties, nest pairs the same way the rest of this package
does:

```dart
ParallelKeyframeTracks<
  AnimatableDouble,
  AnimatablePair<AnimatableOffset, AnimatableColor>
>(
  scaleTrack,
  ParallelKeyframeTracks<AnimatableOffset, AnimatableColor>(
    offsetTrack,
    colorTrack,
  ),
);
```

The value type follows the same nesting:
`AnimatablePair<AnimatableDouble, AnimatablePair<AnimatableOffset, AnimatableColor>>`.

## Composing with other modifiers

Because `KeyframeTrack` is just another `CustomAnimation`, every existing
`AnimationSpec` modifier still works:

```dart
// Repeat a keyframe sequence three times, ping-pong.
AnimationSpec
    .keyframeTrack<AnimatableDouble>([
      Keyframe.easeInOut(AnimatableDouble(1.0),
                         const Duration(milliseconds: 300)),
    ])
    .repeatCount(3, autoreverses: true);

// Play a sequence at half speed.
AnimationSpec
    .keyframeTrack<AnimatableDouble>([
      Keyframe.linear(AnimatableDouble(1.0),
                      const Duration(milliseconds: 200)),
      Keyframe.linear(AnimatableDouble(0.0),
                      const Duration(milliseconds: 200)),
    ])
    .speed(0.5);
```

## Cheat sheet

| Need                                            | API                                                |
|-------------------------------------------------|----------------------------------------------------|
| Multi-stage animation of one property           | `AnimationSpec.keyframeTrack<T>([…])`              |
| Two properties on separate timelines            | `AnimationSpec.parallelKeyframeTracks<A, B>(…)`    |
| Three or more properties                        | Nested `ParallelKeyframeTracks`                    |
| Loop or ping-pong a keyframe sequence           | `.repeatCount(n, autoreverses: true)`              |
| Slow down or speed up a keyframe sequence       | `.speed(factor)`                                   |
