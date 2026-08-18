import 'package:flutter/material.dart';

import '../widgets/animated_tile_background.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  static const routeName = '/stats';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedTileBackground(),
          Center(
            child: Text(
              'Statistics page content goes here.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}