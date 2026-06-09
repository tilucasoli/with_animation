import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:with_animation/with_animation.dart'
    show
        AnimationSpec,
        BezierAnimation,
        Transaction,
        currentTransaction,
        withAnimation,
        withTransaction;

// The transaction stack is a process-wide static. Each test pumps a frame
// before exercising it so any post-frame callback scheduled by a prior test
// fires first and resets the stack to a clean state.
Future<void> _drain(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
  // Belt-and-braces: pop any residual pending by entering and exiting an
  // inner withAnimation, then pumping again.
  final transaction = currentTransaction();
  if (transaction != null) {
    await tester.pump();
  }
}

void main() {
  testWidgets('currentTransaction is null outside withAnimation', (
    tester,
  ) async {
    await _drain(tester);
    expect(currentTransaction(), isNull);
  });

  testWidgets('currentTransaction is set inside the body', (tester) async {
    await _drain(tester);
    final anim = AnimationSpec.linear(duration: const Duration(seconds: 1));
    bool sawIt = false;
    withAnimation(anim, () {
      sawIt = identical(currentTransaction()?.animation, anim);
    });
    expect(sawIt, isTrue);
    await tester.pump();
  });

  testWidgets(
    'transaction persists synchronously after body returns (intentional)',
    (tester) async {
      await _drain(tester);
      final anim = AnimationSpec(
        BezierAnimation.linear(const Duration(seconds: 1)),
      );
      withAnimation(anim, () {});
      // Per the doc in transaction.dart, the outermost transaction outlives
      // the synchronous body so widgets that rebuild later in the same frame
      // still see it.
      expect(currentTransaction()?.animation, same(anim));
      await tester.pump();
    },
  );

  testWidgets('post-frame callback clears the transaction', (tester) async {
    await _drain(tester);
    final anim = AnimationSpec.linear(duration: const Duration(seconds: 1));
    withAnimation(anim, () {});
    expect(currentTransaction(), isNotNull);
    // `withAnimation` adds a post-frame callback but does not request a frame,
    // so we must force a real frame by changing the widget tree. The next
    // post-frame callback nils `_TransactionStack.pending`.
    await tester.pumpWidget(Container(key: UniqueKey()));
    await tester.pump();
    expect(currentTransaction(), isNull);
  });

  testWidgets('nested withAnimation: inner is current, outer restored after', (
    tester,
  ) async {
    await _drain(tester);
    final outer = AnimationSpec(
      BezierAnimation.linear(const Duration(seconds: 1)),
    );
    final inner = AnimationSpec(
      BezierAnimation.easeIn(const Duration(seconds: 1)),
    );

    AnimationSpec? insideInner;
    AnimationSpec? afterInner;

    withAnimation(outer, () {
      withAnimation(inner, () {
        insideInner = currentTransaction()?.animation;
      });
      afterInner = currentTransaction()?.animation;
    });

    expect(insideInner, same(inner));
    expect(afterInner, same(outer));
    await tester.pump();
  });

  testWidgets('withTransaction exposes disablesAnimations', (tester) async {
    await _drain(tester);
    bool? seen;
    withTransaction(const Transaction(disablesAnimations: true), () {
      seen = currentTransaction()?.disablesAnimations;
    });
    expect(seen, isTrue);
    await tester.pump();
  });
}
