import 'package:flutter/widgets.dart' hide Animatable;
import 'package:flutter_test/flutter_test.dart';
import 'package:with_animation/with_animation.dart'
    show
        AnimatableDouble,
        AnimatableValue,
        Animations,
        BezierAnimation,
        PhaseAnimator;

/// Host that owns a trigger value so tests can advance phase sequences in
/// triggered mode.
class _TriggerHost extends StatefulWidget {
  final List<double> phases;
  final Animations? Function(double phase)? animation;
  final void Function(_TriggerHostState driver) onReady;
  final void Function(double phase) onPhase;

  const _TriggerHost({
    required this.phases,
    required this.onReady,
    required this.onPhase,
    this.animation,
  });

  @override
  State<_TriggerHost> createState() => _TriggerHostState();
}

class _TriggerHostState extends State<_TriggerHost> {
  int _trigger = 0;

  void fire() => setState(() => _trigger++);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onReady(this));
  }

  @override
  Widget build(BuildContext context) {
    return PhaseAnimator<double>(
      phases: widget.phases,
      trigger: _trigger,
      animation: widget.animation,
      builder: (context, phase) {
        widget.onPhase(phase);
        return AnimatableValue<AnimatableDouble, AnimatableDouble>(
          value: AnimatableDouble(phase),
          builder: (context, animated) => const SizedBox.shrink(),
        );
      },
    );
  }
}

void main() {
  testWidgets(
    'continuous mode auto-advances through every phase and wraps to 0',
    (tester) async {
      final phaseSeen = <double>[];
      final spec = Animations(
        BezierAnimation.linear(const Duration(milliseconds: 200)),
      );

      await tester.pumpWidget(
        PhaseAnimator<double>(
          phases: const [0.0, 1.0, 2.0],
          animation: (_) => spec,
          builder: (context, phase) {
            phaseSeen.add(phase);
            return const SizedBox.shrink();
          },
        ),
      );
      await tester.pump();
      expect(phaseSeen.last, 0.0);

      // Let the first transition (0 -> 1) finish.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(phaseSeen, contains(1.0));

      // Second transition (1 -> 2).
      await tester.pump(const Duration(milliseconds: 250));
      expect(phaseSeen, contains(2.0));

      // Third transition wraps back to 0.
      await tester.pump(const Duration(milliseconds: 250));
      expect(phaseSeen.last, 0.0);

      // Stop the ticker by unmounting so the test runner doesn't hang.
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'triggered mode cycles through every phase and ends back on phase[0]',
    (tester) async {
      final phaseSeen = <double>[];
      late _TriggerHostState host;
      final spec = Animations(
        BezierAnimation.linear(const Duration(milliseconds: 200)),
      );

      await tester.pumpWidget(
        _TriggerHost(
          phases: const [0.0, 10.0, 20.0],
          animation: (_) => spec,
          onReady: (h) => host = h,
          onPhase: phaseSeen.add,
        ),
      );
      await tester.pump();
      expect(phaseSeen.last, 0.0);

      // Fire the trigger once: should animate 0 -> 10 -> 20 -> 0.
      host.fire();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(phaseSeen, contains(10.0));
      await tester.pump(const Duration(milliseconds: 250));
      expect(phaseSeen, contains(20.0));
      await tester.pump(const Duration(milliseconds: 250));
      expect(phaseSeen.last, 0.0);

      // Parked on phase[0] — no further rebuilds.
      final countAfterFirstRun = phaseSeen.length;
      await tester.pump(const Duration(milliseconds: 500));
      expect(phaseSeen.length, countAfterFirstRun);

      // Firing again runs another full cycle.
      host.fire();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(phaseSeen, contains(10.0));
      await tester.pump(const Duration(milliseconds: 250));
      expect(phaseSeen, contains(20.0));
      await tester.pump(const Duration(milliseconds: 250));
      expect(phaseSeen.last, 0.0);
    },
  );

  testWidgets('animation callback receives the destination phase', (
    tester,
  ) async {
    final seenDestinations = <double>[];
    final spec = Animations(
      BezierAnimation.linear(const Duration(milliseconds: 150)),
    );

    await tester.pumpWidget(
      PhaseAnimator<double>(
        phases: const [0.0, 5.0, 10.0],
        animation: (phase) {
          seenDestinations.add(phase);
          return spec;
        },
        builder: (context, phase) => const SizedBox.shrink(),
      ),
    );

    // Run through one full cycle: should ask for animations targeting
    // 5.0, then 10.0, then back to 0.0.
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    expect(seenDestinations.take(3), [5.0, 10.0, 0.0]);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('null animation per-phase falls back to defaultAnimation', (
    tester,
  ) async {
    final phaseSeen = <double>[];
    final fallback = Animations(
      BezierAnimation.linear(const Duration(milliseconds: 150)),
    );

    await tester.pumpWidget(
      PhaseAnimator<double>(
        phases: const [0.0, 1.0],
        animation: (_) => null,
        defaultAnimation: fallback,
        builder: (context, phase) {
          phaseSeen.add(phase);
          return const SizedBox.shrink();
        },
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(phaseSeen, contains(1.0));

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('dispose mid-cycle does not throw', (tester) async {
    final spec = Animations(
      BezierAnimation.linear(const Duration(milliseconds: 300)),
    );

    await tester.pumpWidget(
      PhaseAnimator<double>(
        phases: const [0.0, 1.0, 2.0],
        animation: (_) => spec,
        builder: (context, phase) => const SizedBox.shrink(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });

  testWidgets('single-phase list stays put and never starts the ticker', (
    tester,
  ) async {
    final phaseSeen = <double>[];

    await tester.pumpWidget(
      PhaseAnimator<double>(
        phases: const [7.0],
        animation: (_) => Animations(
          BezierAnimation.linear(const Duration(milliseconds: 100)),
        ),
        builder: (context, phase) {
          phaseSeen.add(phase);
          return const SizedBox.shrink();
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(phaseSeen.every((p) => p == 7.0), isTrue);
  });
}
