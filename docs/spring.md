# Spring physics

A draggable square that springs back to centre when released.

## Vanilla Flutter — `AnimationController` + `SpringSimulation`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

class SpringBack extends StatefulWidget {
  const SpringBack({super.key});

  @override
  State<SpringBack> createState() => _SpringBackState();
}

class _SpringBackState extends State<SpringBack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Offset _offset = Offset.zero;
  Offset _start = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController.unbounded(vsync: this)
      ..addListener(() {
        setState(() {
          _offset = Offset.lerp(_start, Offset.zero, _controller.value)!;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _release() {
    _start = _offset;
    _controller
      ..value = 0
      ..animateWith(SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 100, damping: 10),
        0,
        1,
        0, // initial velocity
      ));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (d) => setState(() => _offset += d.delta),
      onPanEnd: (_) => _release(),
      child: Transform.translate(
        offset: _offset,
        child: Container(width: 80, height: 80, color: Colors.indigo),
      ),
    );
  }
}
```

Three things make this awkward:

1. `SpringSimulation` produces a `0..1` parameter that you have to lerp
   manually between the captured start and the target.
2. You snapshot `_start` and reset `_controller.value` to 0 each release —
   if the user re-grabs mid-spring, you have to re-snapshot.
3. The "physics" and the "drag input" share the same `_offset` field, and
   you have to remember not to fight the controller while it's animating.

## `with_animation` — `AnimationSpec.spring`

```dart
import 'package:flutter/material.dart';
import 'package:with_animation/with_animation.dart';

class SpringBack extends StatefulWidget {
  const SpringBack({super.key});

  @override
  State<SpringBack> createState() => _SpringBackState();
}

class _SpringBackState extends State<SpringBack> {
  Offset _offset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (d) {
        // No animation — track the finger 1:1.
        setState(() => _offset += d.delta);
      },
      onPanEnd: (_) {
        withAnimation(
          AnimationSpec.spring(mass: 1, stiffness: 100, damping: 10),
          () => setState(() => _offset = Offset.zero),
        );
      },
      child: AnimatableValue<AnimatableOffset>(
        value: AnimatableOffset(_offset),
        builder: (context, animated) => Transform.translate(
          offset: animated.value,
          child: Container(width: 80, height: 80, color: Colors.indigo),
        ),
      ),
    );
  }
}
```

## What changed

- **One field of truth.** `_offset` is the logical position. During the drag
  it tracks the finger; on release you set it to `Offset.zero` and the spring
  carries it home.
- **The spring is a spec, not a controller.** You hand `withAnimation` a
  `spring(...)` and the animator does the integration.
- **SwiftUI's modern spring presets** are available too:
  ```dart
  AnimationSpec.smooth();   // non-bouncy
  AnimationSpec.snappy();   // slightly bouncy
  AnimationSpec.bouncy();   // noticeably bouncy
  AnimationSpec.fluidSpring(response: 0.5, dampingFraction: 0.825);
  ```
