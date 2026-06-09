import 'package:flutter/scheduler.dart';

import 'animation.dart';

class Transaction {
  final Animation? animation;
  final bool disablesAnimations;

  const Transaction({this.animation, this.disablesAnimations = false});
}

class _TransactionStack {
  /// The transaction installed by the innermost `withAnimation`.
  /// Cleared on the next post-frame callback so any [AnimatableValue] that
  /// rebuilds later in the same frame still sees it.
  static Transaction? pending;
  static bool _clearingScheduled = false;
}

/// Run [body] with [animation] as the active animation for any state changes
/// it triggers. Use synchronously inside `setState` callbacks for the same
/// idiom as SwiftUI's `withAnimation`.
T withAnimation<T>(Animation animation, T Function() body) =>
    _withTransaction(Transaction(animation: animation), body);

T withTransaction<T>(Transaction transaction, T Function() body) =>
    _withTransaction(transaction, body);

T _withTransaction<T>(Transaction t, T Function() body) {
  final previous = _TransactionStack.pending;
  _TransactionStack.pending = t;

  if (!_TransactionStack._clearingScheduled) {
    _TransactionStack._clearingScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _TransactionStack.pending = null;
      _TransactionStack._clearingScheduled = false;
    });
  }

  try {
    return body();
  } finally {
    // Restore the previous stack frame only if it was non-null — we want the
    // *outermost* transaction to outlive `withAnimation` for the rest of the
    // frame so widgets that rebuild after `setState` returns can still read it.
    if (previous != null) _TransactionStack.pending = previous;
  }
}

/// Internal: how [AnimatableValue] reads the current transaction.
Transaction? currentTransaction() => _TransactionStack.pending;
