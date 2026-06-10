# Naming review — `with_animation`

A review of the public API names exported from `lib/with_animation.dart`, looking
at each name in isolation **and** at how the names work together as an
ecosystem.

---

## Macro: what's pulling on the names

Three forces are fighting:

1. **SwiftUI parity** — the package's whole pitch ("SwiftUI-style declarative
   animation"). You *want* a SwiftUI reader to recognise `Animation`,
   `Animatable`, `VectorArithmetic`, `AnimatablePair` immediately.
2. **Flutter coexistence** — `Animation<T>` and `AnimationController` already
   exist in `package:flutter`, so the obvious SwiftUI names collide.
3. **Internal coherence** — the package's own vocabulary should be small and
   consistent.

The current API has tried to thread the needle but used **four different
disambiguation strategies in four places**:

| Concept | SwiftUI | Here | Strategy |
| --- | --- | --- | --- |
| Animation curve type | `Animation` | `AnimationSpec` | suffix |
| Vector protocol | `VectorArithmetic` | `CustomVectorArithmetic` | prefix `Custom` |
| Animatable protocol | `Animatable` | `AnimatableData` | renamed to match its property |
| Custom-animation protocol | `CustomAnimation` | `CustomAnimation` | unchanged |

That inconsistency *is* the macro smell — there's no rule a new contributor can
follow to pick the next name. Recommendation: **pick a single rule and apply it
everywhere.** The rule that costs least is:

- **`Animation*`** = configurable behaviour over time (specs, drivers, runtime
  state).
- **`Animatable*`** = "this value can be projected into the animation pipeline"
  (protocols + their containers + the widget that drives them).
- **Drop `Custom` as a disambiguator.** It reads like "the weird/optional
  variant," but it *is* the canonical thing in this package. Reserve `Custom`
  for actual extension points (`CustomAnimation` is fine — it's a hook for
  users to write their own).
- **Never reuse one word as both a protocol and a property.** `AnimatableData`
  is currently the protocol *and* the getter on it *and* the projection it
  returns. Rename the protocol *or* the projection.

---

## Per-type review

### `CustomVectorArithmetic<Self>` → `VectorArithmetic<Self>`

The `Custom` prefix exists only because the type-erased handle (line 125 of
`vector_arithmetic.dart`) took the unprefixed name first. That handle barely
earns its keep — it's a thin wrapper with four static factories, never used in
any other public signature. Two cleaner options:

- **Drop the handle** and move its factories to a `Vectors` namespace or to the
  concrete classes (`DoubleVectorArithmetic.of(1.0)`, `AnimatablePair.of(a, b)`).
  Then `VectorArithmetic` is free.
- **Keep the handle, rename it `AnyVector`** (echoes Swift's `Any*` erasure
  idiom). Same as above for the protocol name.

Either way, `Custom` goes away from the most-frequently-typed name in the
package.

### `AnimatableData<V>` → `Animatable<V>` (protocol) + `vector` (property)

This is the worst offender for the macro coherence story. Today:

```dart
abstract class AnimatableData<V extends CustomVectorArithmetic<V>> {
  V get animatableData;
  set animatableData(V value);
  AnimatableData<V> clone();
}
```

The word `animatableData` carries three meanings inside one ten-line
declaration. SwiftUI calls the protocol `Animatable` and the property
`animatableData`; here it's flipped. I'd flip it back, *and* take the chance to
rename the property to something descriptive of its role:

```dart
abstract class Animatable<V extends VectorArithmetic<V>> {
  V get vector;             // or `projection`
  set vector(V value);
  Animatable<V> clone();
}
```

Then `AnimatableOffset extends Animatable<...>` and
`AnimatableColor extends Animatable<...>` read naturally, and the *name* of the
file (`animatable.dart`) finally matches the *name* of the type. Pick `vector`
if you want plumbing language; `projection` if you want the SwiftUI doc-comment
language ("a projection used by the animation pipeline").

### `DoubleVectorArithmetic` / `IntVectorArithmetic` → `AnimatableDouble` / `AnimatableInt`

Currently these are named after the protocol they conform to, not the role they
play. But:

- `AnimatableColor` is a `Color` wrapped as an `Animatable`. ✓
- `DoubleVectorArithmetic` is a `double` wrapped as an `Animatable`. ✗
  (name disagrees)

There's a hint in the file: `DoubleVectorArithmetic.toString()` already returns
`'AnimatableDouble($value)'` (line 45). The `toString` is telling you what the
class wishes it were called. Rename to `AnimatableDouble` and `AnimatableInt`,
and the ecosystem becomes:

```
Animatable<V>          // protocol
AnimatableDouble       // primitive impl
AnimatableInt          // primitive impl
AnimatableOffset       // composite impl
AnimatableColor        // composite impl
AnimatablePair<A,B>    // composite combinator
AnimatableArray<E>     // composite combinator
AnimatableValue<T,V>   // the widget that drives one
EmptyAnimatable        // placeholder
```

That's a tight, learnable family. Today, `DoubleVectorArithmetic` and
`AnimatableColor` look like they live in different libraries — they don't.

Caveat: `AnimatableDouble` *is* both an `Animatable` and a `VectorArithmetic`
(its own projection). The current name advertises the second role; the proposed
name advertises the first. Since users encounter the `Animatable` role first
(it's what `AnimatableValue` consumes), that's the right side to name after.

### `EmptyAnimatableData` → `EmptyAnimatable` / `NoAnimation`

Same rename as the protocol. Also worth asking whether this is the right
*concept name*: it's used when a type "has no animatable properties." SwiftUI's
`EmptyAnimatableData` is fine because it's the literal return type of
`Animatable.animatableData` for unanimatable views. In Dart, you'd more often
write `Animatable<EmptyAnimatable>`, which reads oddly. `NoAnimation` or
`Unanimated` might communicate intent better at use sites — but if SwiftUI
parity is a priority, keep `EmptyAnimatable`.

### `AnimationSpec` → keep, but `Animation.foo()` factory access is awkward

`AnimationSpec` is the rare name where the disambiguation suffix actually adds
meaning ("spec" = recipe, not the runtime animation object). Keep it. The pain
is the call site: in SwiftUI you write `.spring()`; here you write
`AnimationSpec.spring()`. Consider a top-level `Animations` (plural) namespace
class so users can write `Animations.spring(...)` — half a syllable shorter and
avoids the noun "spec" appearing in user code.

### `AnimatorState` → `AnimationDriver` (or `RunningAnimation`)

Two issues:

1. There's already an `AnimationState` class in this package. `AnimatorState`
   and `AnimationState` are unrelated but autocomplete will show them together
   forever.
2. The class is not really "state of the animator" — it's the thing that
   *drives* a single in-flight animation. The SwiftUI source it ports calls it
   `AnimatorState` too, but SwiftUI doesn't have the same neighbouring name
   collision.

`AnimationDriver` or `RunningAnimation` both read better and don't shadow
`AnimationState`.

### `AnimationContext` / `AnimationState` → keep, but consider merging

These are two small classes that always travel together (`AnimationContext`
*contains* an `AnimationState`). Inside `CustomAnimation.animate`, the only
thing you do with `ctx.state` is `ctx.state.get<...>` / `ctx.state.set<...>`.
The split mirrors SwiftUI's `AnimationContext` + `AnimationStateKey` machinery,
but in Dart with `Type` keys the indirection adds nothing — you could fold the
storage into `AnimationContext` itself and remove `AnimationState` from the
public API. Bonus: removes the `AnimationState`/`AnimatorState` name clash
flagged above.

### `Transaction` / `withTransaction` → keep, but consider scoping

`Transaction` is a very generic name and will collide in any codebase that also
uses Firestore, sqflite, or any DB SDK. SwiftUI gets away with it because Swift
is single-namespace; Dart isn't. Two cheap options:

- Make `Transaction` *internal* (it already isn't documented heavily) and keep
  `withAnimation` as the only public entry — most users don't need to
  construct `Transaction` directly.
- If it stays public, rename to `AnimationTransaction` (consistent with the
  `Animation*` family rule). At call sites it's almost always written as
  `withTransaction(Transaction(...))`, which is verbose anyway; lengthening it
  to `withAnimationTransaction(AnimationTransaction(...))` is honest about
  what you're doing.

I'd lean toward "make it internal" — `withAnimation` covers the 95% case.

### `CustomAnimation` → keep

This is the one place `Custom` *means* "user-extensible". Stays.

### `BezierAnimation` / `SpringAnimation` / `FluidSpringAnimation` / `RepeatAnimation` / `SpeedAnimation` → keep, but consider hiding

These five concrete `CustomAnimation` subclasses are all reachable as
`AnimationSpec.easeInOut()`, `.spring()`, `.repeatCount()` etc. — the user
never names them. They're exported (lines 13–18 of `with_animation.dart`) but
I'd consider making them library-private. If they stay public, they're fine
as-is — they're internally consistent and the names are self-explanatory.

One nit: `BezierAnimation` is the implementation behind `easeInOut`, `easeIn`,
`easeOut`, *and* `linear`. The class name privileges one of those (bezier
curves), not the user-facing concept (timing curve). `CurveAnimation` or
`TimingCurveAnimation` would say what it is. If it stays internal, the
question is moot.

---

## Suggested end-state (compact view)

```
// Vector layer
VectorArithmetic<Self>              (was CustomVectorArithmetic)
AnyVector                           (was VectorArithmetic, the handle) — or delete
AnimatableDouble                    (was DoubleVectorArithmetic)
AnimatableInt                       (was IntVectorArithmetic)
AnimatablePair<A,B>                 (unchanged)
AnimatableArray<E>                  (unchanged)
EmptyAnimatable                     (was EmptyAnimatableData)

// Domain wrappers
Animatable<V>                       (was AnimatableData — protocol)
  .vector / .projection             (was .animatableData — property)
AnimatableOffset                    (unchanged)
AnimatableColor                     (unchanged)

// Widget + driver
AnimatableValue<T,V>                (unchanged)
AnimationDriver<V>                  (was AnimatorState)

// Spec / runtime
AnimationSpec                       (unchanged)
Animations                          (optional namespace for factory presets)
CustomAnimation                     (unchanged — it really is a customisation hook)
AnimationContext<T>                 (unchanged; absorbs AnimationState)

// Transaction
withAnimation(...)                  (unchanged)
AnimationTransaction                (was Transaction — or make internal)
```

The win is that the *rule* is now stable: anything that wraps a domain value
starts with `Animatable`, anything about behaviour over time starts with
`Animation`, and no name is doing double duty as both a protocol and a
property.

---

## Highest-leverage changes if you only do three

1. **`AnimatableData` → `Animatable` + rename its property** — kills the
   triple-meaning of one word inside the protocol declaration.
2. **`DoubleVectorArithmetic` / `IntVectorArithmetic` → `AnimatableDouble` /
   `AnimatableInt`** — aligns the primitive wrappers with the
   `AnimatableColor` / `AnimatableOffset` family.
3. **Drop `Custom` from `CustomVectorArithmetic`** — the most-typed type in the
   package shouldn't read like an apology.

Everything else is polish.
