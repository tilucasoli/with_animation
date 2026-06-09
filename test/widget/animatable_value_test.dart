import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:with_animation/with_animation.dart'
    show
        AnimatableColor,
        AnimatableDouble,
        AnimatableOffset,
        AnimatableValue,
        AnimationSpec,
        BezierAnimation,
        SpringAnimation,
        Transaction,
        VectorArithmetic,
        withAnimation,
        withTransaction;

/// Test harness: rebuilds an [AnimatableValue] whose current `value` and
/// `defaultAnimation` come from a host [_Driver].
class _Host<T extends VectorArithmetic<T>> extends StatefulWidget {
  final T initial;
  final AnimationSpec? defaultAnimation;
  final void Function(_DriverState<T> driver) onReady;
  final void Function(T animated) onBuild;

  const _Host({
    required this.initial,
    required this.onReady,
    required this.onBuild,
    this.defaultAnimation,
  });

  @override
  State<_Host<T>> createState() => _DriverState<T>();
}

class _DriverState<T extends VectorArithmetic<T>> extends State<_Host<T>> {
  late T _value = widget.initial;

  void update(T newValue, {AnimationSpec? animation, bool disabled = false}) {
    final body = () => setState(() => _value = newValue);
    if (disabled) {
      withTransaction(const Transaction(disablesAnimations: true), body);
    } else if (animation != null) {
      withAnimation(animation, body);
    } else {
      body();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onReady(this));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatableValue<T>(
      value: _value,
      defaultAnimation: widget.defaultAnimation,
      builder: (context, animated) {
        widget.onBuild(animated);
        return const SizedBox.shrink();
      },
    );
  }
}

void main() {
  testWidgets('no transaction, no defaultAnimation: jumps immediately', (
    tester,
  ) async {
    final builds = <double>[];
    late _DriverState<AnimatableDouble> driver;

    await tester.pumpWidget(
      _Host<AnimatableDouble>(
        initial: AnimatableDouble(0.0),
        onReady: (d) => driver = d,
        onBuild: (v) => builds.add(v.value),
      ),
    );
    await tester.pump();
    builds.clear();

    driver.update(AnimatableDouble(1.0));
    await tester.pump();
    expect(builds.last, 1.0);

    // No ticker activity expected.
    await tester.pump(const Duration(milliseconds: 100));
    expect(builds.where((b) => b != 1.0), isEmpty);
  });

  testWidgets('disablesAnimations jumps even with a defaultAnimation', (
    tester,
  ) async {
    final builds = <double>[];
    late _DriverState<AnimatableDouble> driver;

    await tester.pumpWidget(
      _Host<AnimatableDouble>(
        initial: AnimatableDouble(0.0),
        defaultAnimation: AnimationSpec(
          BezierAnimation.linear(const Duration(seconds: 1)),
        ),
        onReady: (d) => driver = d,
        onBuild: (v) => builds.add(v.value),
      ),
    );
    await tester.pump();
    builds.clear();

    driver.update(AnimatableDouble(1.0), disabled: true);
    await tester.pump();
    expect(builds.last, 1.0);
  });

  testWidgets(
    'linear bezier interpolates over duration and settles at target',
    (tester) async {
      final builds = <double>[];
      late _DriverState<AnimatableDouble> driver;

      await tester.pumpWidget(
        _Host<AnimatableDouble>(
          initial: AnimatableDouble(0.0),
          onReady: (d) => driver = d,
          onBuild: (v) => builds.add(v.value),
        ),
      );
      await tester.pump();

      driver.update(
        AnimatableDouble(1.0),
        animation: AnimationSpec(
          BezierAnimation.linear(const Duration(seconds: 1)),
        ),
      );

      // Kick the ticker and advance ~halfway.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final mid = builds.last;
      expect(mid, closeTo(0.5, 0.1));

      // Past the end: should clamp to target.
      await tester.pump(const Duration(milliseconds: 700));
      expect(builds.last, closeTo(1.0, 1e-9));
    },
  );

  testWidgets('defaultAnimation is used when no transaction is active', (
    tester,
  ) async {
    final builds = <double>[];
    late _DriverState<AnimatableDouble> driver;

    await tester.pumpWidget(
      _Host<AnimatableDouble>(
        initial: AnimatableDouble(0.0),
        defaultAnimation: AnimationSpec(
          BezierAnimation.linear(const Duration(seconds: 1)),
        ),
        onReady: (d) => driver = d,
        onBuild: (v) => builds.add(v.value),
      ),
    );
    await tester.pump();

    driver.update(AnimatableDouble(1.0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(builds.last, closeTo(0.5, 0.1));

    await tester.pump(const Duration(milliseconds: 700));
    expect(builds.last, closeTo(1.0, 1e-9));
  });

  testWidgets('interrupting mid-animation pivots from the displayed value', (
    tester,
  ) async {
    final builds = <double>[];
    late _DriverState<AnimatableDouble> driver;

    await tester.pumpWidget(
      _Host<AnimatableDouble>(
        initial: AnimatableDouble(0.0),
        onReady: (d) => driver = d,
        onBuild: (v) => builds.add(v.value),
      ),
    );
    await tester.pump();

    driver.update(
      AnimatableDouble(1.0),
      animation: AnimationSpec(
        BezierAnimation.linear(const Duration(seconds: 1)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final beforeInterrupt = builds.last;
    expect(beforeInterrupt, closeTo(0.5, 0.1));

    // Interrupt with a new target. The next visible frame should be close to
    // `beforeInterrupt`, not snap back toward 0.
    driver.update(
      AnimatableDouble(0.0),
      animation: AnimationSpec(
        BezierAnimation.linear(const Duration(seconds: 1)),
      ),
    );
    await tester.pump();
    expect(builds.last, closeTo(beforeInterrupt, 0.1));
  });

  testWidgets('spring eventually settles and stops the ticker', (tester) async {
    final builds = <double>[];
    late _DriverState<AnimatableDouble> driver;

    await tester.pumpWidget(
      _Host<AnimatableDouble>(
        initial: AnimatableDouble(0.0),
        onReady: (d) => driver = d,
        onBuild: (v) => builds.add(v.value),
      ),
    );
    await tester.pump();

    driver.update(
      AnimatableDouble(1.0),
      animation: AnimationSpec(
        SpringAnimation(mass: 1, stiffness: 100, damping: 10),
      ),
    );

    // Let the spring run.
    for (int i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(builds.last, closeTo(1.0, 1e-3));

    // After settling, no further rebuilds should occur.
    final settledCount = builds.length;
    await tester.pump(const Duration(milliseconds: 200));
    expect(builds.length, settledCount);
  });

  testWidgets('equal value update is a no-op (no ticker activity)', (
    tester,
  ) async {
    final builds = <double>[];
    late _DriverState<AnimatableDouble> driver;

    await tester.pumpWidget(
      _Host<AnimatableDouble>(
        initial: AnimatableDouble(0.0),
        onReady: (d) => driver = d,
        onBuild: (v) => builds.add(v.value),
      ),
    );
    await tester.pump();
    final before = builds.length;

    driver.update(
      AnimatableDouble(0.0),
      animation: AnimationSpec(
        BezierAnimation.linear(const Duration(seconds: 1)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // The widget can build once due to setState, but no animation samples
    // should follow — the last value stays exactly 0.0.
    expect(builds.skip(before).every((v) => v == 0.0), isTrue);
  });

  testWidgets('AnimatableOffset animates over an offset interval', (
    tester,
  ) async {
    final builds = <AnimatableOffset>[];
    late _DriverState<AnimatableOffset> driver;

    await tester.pumpWidget(
      _Host<AnimatableOffset>(
        initial: AnimatableOffset(Offset.zero),
        onReady: (d) => driver = d,
        onBuild: (v) => builds.add(v),
      ),
    );
    await tester.pump();

    driver.update(
      AnimatableOffset(const Offset(100, 200)),
      animation: AnimationSpec(
        BezierAnimation.linear(const Duration(seconds: 1)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(builds.last.value.dx, closeTo(50, 10));
    expect(builds.last.value.dy, closeTo(100, 20));

    await tester.pump(const Duration(milliseconds: 700));
    expect(builds.last.value.dx, closeTo(100, 1e-9));
    expect(builds.last.value.dy, closeTo(200, 1e-9));
  });

  testWidgets('AnimatableColor animates component-wise in linear sRGB', (
    tester,
  ) async {
    final builds = <AnimatableColor>[];
    late _DriverState<AnimatableColor> driver;

    // Animate opaque black → opaque mid-grey (in linear sRGB). All four
    // channels are stored as 0..1 floats; we read them directly.
    await tester.pumpWidget(
      _Host<AnimatableColor>(
        initial: AnimatableColor(
          const Color.from(alpha: 1, red: 0, green: 0, blue: 0),
        ),
        onReady: (d) => driver = d,
        onBuild: (v) => builds.add(v),
      ),
    );
    await tester.pump();

    driver.update(
      AnimatableColor(
        const Color.from(alpha: 1, red: 0.5, green: 0.5, blue: 0.5),
      ),
      animation: AnimationSpec(
        BezierAnimation.linear(const Duration(seconds: 1)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    expect(builds.last.value.r, closeTo(0.5, 1e-6));
    expect(builds.last.value.g, closeTo(0.5, 1e-6));
    expect(builds.last.value.b, closeTo(0.5, 1e-6));
    expect(builds.last.value.a, closeTo(1.0, 1e-6));
  });

  testWidgets('dispose mid-flight does not throw late callbacks', (
    tester,
  ) async {
    late _DriverState<AnimatableDouble> driver;

    await tester.pumpWidget(
      _Host<AnimatableDouble>(
        initial: AnimatableDouble(0.0),
        onReady: (d) => driver = d,
        onBuild: (_) {},
      ),
    );
    await tester.pump();

    driver.update(
      AnimatableDouble(1.0),
      animation: AnimationSpec(
        BezierAnimation.linear(const Duration(seconds: 1)),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Remove the widget while the ticker is still active.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 200));
    // No exceptions = success. `tester.takeException()` would surface any.
    expect(tester.takeException(), isNull);
  });
}
