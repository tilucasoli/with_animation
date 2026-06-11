import 'package:flutter/material.dart';

import 'grid_widget.dart';
import 'shock_wave.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'with_animation examples',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFEFEFF4),
        useMaterial3: true,
      ),
      home: const _DemoMenu(),
    );
  }
}

class _DemoMenu extends StatelessWidget {
  const _DemoMenu();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('with_animation examples')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Shock wave'),
            subtitle: const Text('PhaseAnimator with per-cell delay'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Shock wave')),
                  body: const SafeArea(child: ShockWaveDemo()),
                ),
              ),
            ),
          ),
          ListTile(
            title: const Text('Grid widget pulse'),
            subtitle: const Text(
              'Binary phase with AnimatableValue.defaultAnimation',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Grid widget pulse')),
                  body: const SafeArea(child: GridWidgetDemo()),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
