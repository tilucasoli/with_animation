/// SwiftUI-style declarative animation primitives for Flutter.
///
/// See ../../Implementing-in-Flutter.md for the design walkthrough.
library;

export 'src/animatable/animatable_color.dart';
export 'src/animatable/animatable_double.dart';
export 'src/animatable/animatable_offset.dart';
export 'src/animatable/empty_animatable_data.dart';
export 'src/animatable_value.dart';
export 'src/animation_spec.dart';
export 'src/animation_context.dart';
export 'src/animator_state.dart';
export 'src/custom_animation/bezier_animation.dart';
export 'src/custom_animation/custom_animation.dart';
export 'src/custom_animation/fluid_spring_animation.dart';
export 'src/custom_animation/keyframe_track.dart'
    show Keyframe, KeyframeTrack, ParallelKeyframeTracks;
export 'src/custom_animation/repeat_animation.dart';
export 'src/custom_animation/speed_animation.dart';
export 'src/custom_animation/spring_animation.dart';
export 'src/transaction.dart' hide currentTransaction;
export 'src/animatable/vector_arithmetic.dart';
