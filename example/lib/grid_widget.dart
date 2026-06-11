// Port of the SwiftUI "GridWidget" sample by Mykola Harmash to Flutter
// using the with_animation package.
//
// Inspired by the YouTube walkthrough "Animating a SwiftUI widget" by
// Mykola Harmash: https://www.youtube.com/watch?v=-Rzu1Ujcz38

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:with_animation/with_animation.dart';

const double _cellSize = 18.0;
const double _cellSpacing = 8.0;
const int _rowCount = 30;
const int _columnCount = 30;
final double _maxGridDistance = sqrt(
  pow(_columnCount, 2) + pow(_rowCount, 2),
).toDouble();

/// Pulse animation driven by a binary phase (`trigger % 2`). Two
/// rectangles are stacked per cell — one is at rest while the other is
/// compressed, swapping on every trigger so the cell visually breathes.
class GridWidgetDemo extends StatefulWidget {
  const GridWidgetDemo({super.key});

  @override
  State<GridWidgetDemo> createState() => _GridWidgetDemoState();
}

class _GridWidgetDemoState extends State<GridWidgetDemo> {
  int _trigger = 0;

  void _onTrigger() => setState(() => _trigger++);

  @override
  Widget build(BuildContext context) {
    // Wave radiates from the center cell of the grid.
    final waveOrigin = Offset(
      (_columnCount / 2).floorToDouble(),
      (_rowCount / 2).floorToDouble(),
    );
    final phase = _trigger % 2;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Spacer(),
          Column(
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
                            waveOrigin: waveOrigin,
                            phase: phase,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              FilledButton(onPressed: _onTrigger, child: const Text('Trigger')),
              const Spacer(),
              Text('$_trigger', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final Offset coordinates;
  final Offset waveOrigin;
  final int phase;

  const _Cell({
    required this.coordinates,
    required this.waveOrigin,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    final originDistance = (coordinates - waveOrigin).distance;
    final waveImpact = 1.0 - originDistance / _maxGridDistance;
    final delay = Duration(milliseconds: (100 * originDistance).round());
    final compressedScaleAdjustment = 0.5 * waveImpact;

    // Mirrors the SwiftUI source: the spec is picked from the *current*
    // phase value, so 0 → 1 uses compress, 1 → 0 uses expand. Both
    // rectangles use the same spec on a given transition; the delay
    // staggers neighbour cells outward from the wave origin.
    final animation = phase == 0
        ? Animations.bouncy(duration: 0.4, extraBounce: 0.4).delay(delay)
        : Animations.smooth(duration: 0.2).delay(delay);

    final scaleA = 1.0 - (phase == 0 ? 0 : compressedScaleAdjustment);
    final scaleB = 1.0 - (phase == 1 ? 0 : compressedScaleAdjustment);

    return SizedBox(
      width: _cellSize,
      height: _cellSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _AnimatedSquare(scale: scaleA, animation: animation),
          _AnimatedSquare(scale: scaleB, animation: animation),
        ],
      ),
    );
  }
}

class _AnimatedSquare extends StatelessWidget {
  final double scale;
  final Animations animation;

  const _AnimatedSquare({required this.scale, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatableValue<AnimatableDouble, AnimatableDouble>(
      value: AnimatableDouble(scale),
      defaultAnimation: animation,
      builder: (context, animatedScale) => Transform.scale(
        scale: animatedScale.value,
        child: Container(
          width: _cellSize,
          height: _cellSize,
          decoration: BoxDecoration(
            color: const Color(0xFF007AFF), // iOS blue
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
