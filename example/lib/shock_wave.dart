// Port of the SwiftUI "ShockWaveAnimation" sample by Mykola Harmash to
// Flutter using the with_animation package.
//
// Inspired by the YouTube walkthrough "Animating a SwiftUI widget" by
// Mykola Harmash: https://www.youtube.com/watch?v=-Rzu1Ujcz38

import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:with_animation/with_animation.dart';

enum CellAnimationPhase {
  identity,
  compress,
  expand;

  double get scaleAdjustment => switch (this) {
    CellAnimationPhase.identity => 0.0,
    CellAnimationPhase.compress => -0.25,
    CellAnimationPhase.expand => 0.2,
  };

  double get brightnessAdjustment => switch (this) {
    CellAnimationPhase.identity => 0.0,
    CellAnimationPhase.compress => 0.0,
    CellAnimationPhase.expand => -0.2,
  };
}

const double _cellSize = 18.0;
const double _cellSpacing = 8.0;
const int _columnCount = 30;
const int _rowCount = 30;
final double _maxGridDistance = sqrt(
  pow(_columnCount - 1, 2) + pow(_rowCount - 1, 2),
).toDouble();

class ShockWaveDemo extends StatefulWidget {
  const ShockWaveDemo({super.key});

  @override
  State<ShockWaveDemo> createState() => _ShockWaveDemoState();
}

class _ShockWaveDemoState extends State<ShockWaveDemo> {
  int _trigger = 0;
  Offset _waveOrigin = Offset.zero;

  void _handleTap(Offset cellCoordinates) {
    setState(() {
      _waveOrigin = cellCoordinates;
      _trigger++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int row = 0; row < _rowCount; row++)
            Padding(
              padding: EdgeInsets.only(
                bottom: row == _rowCount - 1 ? 0 : _cellSpacing,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int col = 0; col < _columnCount; col++)
                    Padding(
                      padding: EdgeInsets.only(
                        right: col == _columnCount - 1 ? 0 : _cellSpacing,
                      ),
                      child: _Cell(
                        coordinates: Offset(col.toDouble(), row.toDouble()),
                        waveOrigin: _waveOrigin,
                        trigger: _trigger,
                        onTap: _handleTap,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final Offset coordinates;
  final Offset waveOrigin;
  final int trigger;
  final void Function(Offset) onTap;

  const _Cell({
    required this.coordinates,
    required this.waveOrigin,
    required this.trigger,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final originDistance = (coordinates - waveOrigin).distance;
    // Mirrors the SwiftUI source verbatim: `pow(1 - normalized, 0)` is
    // always 1.0, so every cell shares the same amplitude. Change the
    // exponent to e.g. `2` to introduce distance-based falloff.
    final waveImpact = pow(
      1.0 - originDistance / _maxGridDistance,
      0,
    ).toDouble();

    return GestureDetector(
      onTap: () => onTap(coordinates),
      behavior: HitTestBehavior.opaque,
      child: PhaseAnimator<CellAnimationPhase>(
        phases: CellAnimationPhase.values,
        trigger: trigger,
        animation: (phase) => switch (phase) {
          .identity => .bouncy(duration: 0.4, extraBounce: 0.35),
          .compress => .smooth(
            duration: 0.2,
          ).delay(Duration(milliseconds: (75 * originDistance).round())),
          .expand => .smooth(duration: 0.1),
        },
        builder: (context, phase) {
          print(phase);
          final scale = 1.0 + phase.scaleAdjustment * waveImpact;
          final brightness = phase.brightnessAdjustment * waveImpact;

          return AnimatableValue(
            value: AnimatableDouble(scale),
            builder: (context, animatedScale) {
              return AnimatableValue(
                value: AnimatableDouble(brightness),
                builder: (context, animatedBrightness) {
                  return Transform.scale(
                    scale: animatedScale.value,
                    child: Container(
                      width: _cellSize,
                      height: _cellSize,
                      decoration: BoxDecoration(
                        color: _adjustBrightness(
                          const Color(0xFF007AFF), // iOS blue
                          animatedBrightness.value,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // SwiftUI's `.brightness(_:)` adds the value to each RGB channel and
  // clamps. We do the same on the modern `Color` API.
  Color _adjustBrightness(Color base, double b) => Color.from(
    alpha: base.a,
    red: (base.r + b).clamp(0.0, 1.0),
    green: (base.g + b).clamp(0.0, 1.0),
    blue: (base.b + b).clamp(0.0, 1.0),
  );
}
