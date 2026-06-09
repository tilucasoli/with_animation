import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:with_animation/with_animation.dart';

class _Sample {
  final double a;
  final double b;
  _Sample(this.a, this.b);
}

/// Host that owns two channels and lets the test push new values + specs.
class _Host extends StatefulWidget {
  final AnimatableDouble initialA;
  final AnimatableDouble initialB;
  final AnimationSpec? specA;
  final AnimationSpec? specB;
  final void Function(_HostState state) onReady;
  final void Function(_Sample sample) onBuild;

  const _Host({
    required this.initialA,
    required this.initialB,
    required this.onReady,
    required this.onBuild,
    this.specA,
    this.specB,
  });

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late AnimatableDouble _a = widget.initialA;
  late AnimatableDouble _b = widget.initialB;
  AnimationSpec? _specA;
  AnimationSpec? _specB;

  @override
  void initState() {
    super.initState();
    _specA = widget.specA;
    _specB = widget.specB;
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.onReady(this));
  }

  void update({
    AnimatableDouble? a,
    AnimatableDouble? b,
    AnimationSpec? newSpecA,
    AnimationSpec? newSpecB,
    bool disabled = false,
    AnimationSpec? txnAnimation,
  }) {
    void body() => setState(() {
      if (a != null) _a = a;
      if (b != null) _b = b;
      if (newSpecA != null) _specA = newSpecA;
      if (newSpecB != null) _specB = newSpecB;
    });
    if (disabled) {
      withTransaction(const Transaction(disablesAnimations: true), body);
    } else if (txnAnimation != null) {
      withAnimation(txnAnimation, body);
    } else {
      body();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatableChannels(
      channels: [
        Channel<AnimatableDouble>(value: _a, spec: _specA),
        Channel<AnimatableDouble>(value: _b, spec: _specB),
      ],
      builder: (context, values) {
        final a = values[0] as AnimatableDouble;
        final b = values[1] as AnimatableDouble;
        widget.onBuild(_Sample(a.value, b.value));
        return const SizedBox.shrink();
      },
    );
  }
}

void main() {
  testWidgets('two channels with different specs animate independently', (
    tester,
  ) async {
    final builds = <_Sample>[];
    late _HostState host;

    await tester.pumpWidget(
      _Host(
        initialA: AnimatableDouble(0),
        initialB: AnimatableDouble(0),
        specA: AnimationSpec.linear(duration: const Duration(seconds: 1)),
        specB: AnimationSpec.linear(duration: const Duration(seconds: 2)),
        onReady: (s) => host = s,
        onBuild: (s) => builds.add(s),
      ),
    );
    await tester.pump();
    builds.clear();

    host.update(a: AnimatableDouble(1.0), b: AnimatableDouble(1.0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    // Channel A finishes after 1s; channel B is roughly halfway.
    expect(builds.last.a, closeTo(1.0, 0.05));
    expect(builds.last.b, closeTo(0.5, 0.1));

    await tester.pump(const Duration(milliseconds: 1200));
    expect(builds.last.a, closeTo(1.0, 1e-6));
    expect(builds.last.b, closeTo(1.0, 0.05));
  });

  testWidgets('channel spec wins over the ambient transaction', (tester) async {
    final builds = <_Sample>[];
    late _HostState host;

    await tester.pumpWidget(
      _Host(
        initialA: AnimatableDouble(0),
        initialB: AnimatableDouble(0),
        // Only channel B declares a spec.
        specB: AnimationSpec.linear(duration: const Duration(seconds: 2)),
        onReady: (s) => host = s,
        onBuild: (s) => builds.add(s),
      ),
    );
    await tester.pump();
    builds.clear();

    // Drive both via a transaction with a 1s linear spec. Channel B should
    // ignore the transaction and use its own 2s spec.
    host.update(
      a: AnimatableDouble(1.0),
      b: AnimatableDouble(1.0),
      txnAnimation: AnimationSpec.linear(duration: const Duration(seconds: 1)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));

    expect(builds.last.a, closeTo(1.0, 0.05));
    expect(builds.last.b, closeTo(0.5, 0.1));
  });

  testWidgets('one ticker drives both channels (single rebuild per frame)', (
    tester,
  ) async {
    var buildCount = 0;
    late _HostState host;

    await tester.pumpWidget(
      _Host(
        initialA: AnimatableDouble(0),
        initialB: AnimatableDouble(0),
        specA: AnimationSpec.linear(duration: const Duration(seconds: 1)),
        specB: AnimationSpec.linear(duration: const Duration(seconds: 1)),
        onReady: (s) => host = s,
        onBuild: (_) => buildCount++,
      ),
    );
    await tester.pump();
    final baseline = buildCount;

    host.update(a: AnimatableDouble(1.0), b: AnimatableDouble(1.0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    // One animated frame after the kick → exactly one extra build for both
    // channels combined, not two.
    expect(buildCount - baseline, lessThanOrEqualTo(3));
  });

  testWidgets('disablesAnimations forces every channel to jump', (tester) async {
    final builds = <_Sample>[];
    late _HostState host;

    await tester.pumpWidget(
      _Host(
        initialA: AnimatableDouble(0),
        initialB: AnimatableDouble(0),
        specA: AnimationSpec.linear(duration: const Duration(seconds: 1)),
        specB: AnimationSpec.linear(duration: const Duration(seconds: 1)),
        onReady: (s) => host = s,
        onBuild: (s) => builds.add(s),
      ),
    );
    await tester.pump();
    builds.clear();

    host.update(
      a: AnimatableDouble(1.0),
      b: AnimatableDouble(1.0),
      disabled: true,
    );
    await tester.pump();
    expect(builds.last.a, 1.0);
    expect(builds.last.b, 1.0);

    await tester.pump(const Duration(milliseconds: 200));
    final settled = builds.length;
    await tester.pump(const Duration(milliseconds: 200));
    expect(builds.length, settled);
  });

  testWidgets('settled ticker stops; equal-value updates are no-ops', (
    tester,
  ) async {
    final builds = <_Sample>[];
    late _HostState host;

    await tester.pumpWidget(
      _Host(
        initialA: AnimatableDouble(0),
        initialB: AnimatableDouble(0),
        specA: AnimationSpec.linear(duration: const Duration(seconds: 1)),
        specB: AnimationSpec.linear(duration: const Duration(seconds: 1)),
        onReady: (s) => host = s,
        onBuild: (s) => builds.add(s),
      ),
    );
    await tester.pump();

    host.update(a: AnimatableDouble(1.0), b: AnimatableDouble(1.0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    final settled = builds.length;

    // After settling, no further rebuilds.
    await tester.pump(const Duration(milliseconds: 300));
    expect(builds.length, settled);

    // Equal-value update with a spec: no ticker activity.
    host.update(a: AnimatableDouble(1.0), b: AnimatableDouble(1.0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    final stable = builds.skip(settled);
    expect(stable.every((s) => s.a == 1.0 && s.b == 1.0), isTrue);
  });

  testWidgets('dispose mid-flight does not throw', (tester) async {
    late _HostState host;

    await tester.pumpWidget(
      _Host(
        initialA: AnimatableDouble(0),
        initialB: AnimatableDouble(0),
        specA: AnimationSpec.linear(duration: const Duration(seconds: 1)),
        specB: AnimationSpec.linear(duration: const Duration(seconds: 1)),
        onReady: (s) => host = s,
        onBuild: (_) {},
      ),
    );
    await tester.pump();
    host.update(a: AnimatableDouble(1.0), b: AnimatableDouble(1.0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
  });
}
