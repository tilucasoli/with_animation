# Comparing vanilla Flutter to `with_animation`

This folder shows the same animations written two ways: with Flutter's
explicit-animation toolkit (`AnimationController` + `Tween` +
`AnimatedBuilder`) and with this package's SwiftUI-style API
(`AnimatableValue` + `withAnimation`).

Implicit widgets like `AnimatedContainer` are deliberately excluded — they
hide too much to make the comparison fair. The interesting question is what
`with_animation` looks like next to the code you'd write today when you
need real control over an animation.

The point of `with_animation` is not to do things Flutter can't — it's to let
you describe state and let the framework figure out the animation. You change
a value inside `withAnimation(spec, () { ... })`; any `AnimatableValue` that
sees a new input animates from its current displayed value to the new one,
even if it was already mid-flight.

## Mental model

| Flutter                                    | `with_animation`                            |
| ------------------------------------------ | ------------------------------------------- |
| You drive the animation (`controller.forward`) | You change state; the animation follows |
| State is the `Animation<T>` object         | State is the logical value (a `double`, `Color`, etc.) |
| Interruption = curve restart from 0        | Interruption = pivot from current displayed value |
| Spring physics needs `AnimationController` + custom simulation | `AnimationSpec.spring(...)` is a first-class spec |
| `vsync`, `dispose`, controller lifecycle is yours | `AnimatableValue` owns its `Ticker` |

## Index

- [scale.md](scale.md) — animating a `double` (tap-to-scale button)
- [color.md](color.md) — animating a `Color` (tap-to-change background)
- [spring.md](spring.md) — spring physics
- [interruption.md](interruption.md) — what happens when state changes mid-animation
