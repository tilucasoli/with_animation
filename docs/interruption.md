# Interruption mid-animation

What happens when the target changes while an animation is still running.

## The setup

Tap a button to grow a circle from `40px` to `120px`. Tap again before the
animation finishes — what should the second animation start from?

## Vanilla Flutter — `AnimationController` + `Tween`

```dart
import 'package:flutter/material.dart';

class _Interrupt extends StatefulWidget {
  const _Interrupt();
  @override
  State<_Interrupt> createState() => _InterruptState();
}

class _InterruptState extends State<_Interrupt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _size;
  double _begin = 40;
  double _target = 40;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _size = Tween<double>(begin: _begin, end: _target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    final next = _target == 40.0 ? 120.0 : 40.0;
    // Snapshot the displayed value so we don't snap back.
    final displayed = _size.value;
    _begin = displayed;
    _target = next;
    _size = Tween<double>(begin: _begin, end: _target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _size,
        builder: (context, _) => Container(
          width: _size.value,
          height: _size.value,
          decoration: const BoxDecoration(
            color: Colors.teal,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
```

The interruption is the developer's problem. The `AnimationController` only
knows about its `0..1` parameter; if you swap the target without rebasing
the `Tween.begin` to the currently displayed value, the next tap snaps
backward before animating forward. You also have to remember to `reset()`
before `forward()`, otherwise the new tween starts mid-curve and the
animation feels wrong.

Each of those is a small thing. Together they're the reason most apps end
up with one bespoke "interruptible animation" helper per screen.

## `with_animation`

```dart
import 'package:flutter/material.dart';
import 'package:with_animation/with_animation.dart';

class _Interrupt extends StatefulWidget {
  const _Interrupt();
  @override
  State<_Interrupt> createState() => _InterruptState();
}

class _InterruptState extends State<_Interrupt> {
  double _size = 40;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        withAnimation(
          AnimationSpec.easeInOut(duration: const Duration(seconds: 1)),
          () => setState(() => _size = _size == 40 ? 120 : 40),
        );
      },
      child: AnimatableValue<AnimatableDouble>(
        value: AnimatableDouble(_size),
        builder: (context, animated) => Container(
          width: animated.value,
          height: animated.value,
          decoration: const BoxDecoration(
            color: Colors.teal,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
```

The interruption rule is built into `AnimatableValue`: when a new value
arrives mid-flight, the next animator starts from the **currently displayed
value**, not from the previous logical target. So if you tap during the
grow, the shrink begins from whatever size is on screen — never a snap,
and you didn't have to think about it.

Verified by the widget test in
`test/widget/animatable_value_test.dart` — _"interrupting mid-animation
pivots from the displayed value"_.

## Why this matters

The difference is small for one circle and large for a real UI. A picker
where each tap re-targets the highlight, a card stack where drag-then-fling
re-targets the rest position, a search bar where keystrokes re-target the
layout — these are the cases where vanilla Flutter forces you to think
about "where is the animation right now and how do I rebase it" and where
`AnimatableValue` makes that thinking go away.
