import 'vector_arithmetic.dart';

/// Typed scratch storage that survives across `animate` calls within a single
/// animation instance. Mirror of SwiftUI's `AnimationState` +
/// `AnimationStateKey`.
class AnimationState {
  final Map<Type, Object?> _storage = {};

  T get<T>(T defaultValue) => (_storage[T] as T?) ?? defaultValue;
  void set<T>(T value) => _storage[T] = value;
}

/// Context passed to [CustomAnimation.animate] / `shouldMerge`.
class AnimationContext<T extends VectorArithmetic<T>> {
  AnimationState state;
  bool isLogicallyComplete;

  AnimationContext({AnimationState? state, this.isLogicallyComplete = false})
      : state = state ?? AnimationState();
}
