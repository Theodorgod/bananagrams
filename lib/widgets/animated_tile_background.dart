import 'package:flutter/material.dart';

class AnimatedTileBackground extends StatefulWidget {
  const AnimatedTileBackground({super.key});

  @override
  State<AnimatedTileBackground> createState() =>
      _AnimatedTileBackgroundState();
}

class _AnimatedTileBackgroundState extends State<AnimatedTileBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Stack(
                  children: [
                    for (final tile in _tiles)
                      _MovingTile(
                        letter: tile.letter,
                        top: constraints.maxHeight * tile.top,
                        size: tile.size,
                        angle: tile.angle,
                        left: _tileLeft(
                          _animation.value,
                          tile.phase,
                          constraints.maxWidth,
                          tile.size,
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  static const _tiles = [
    (letter: 'B', top: 0.08, size: 64.0, phase: 0.00, angle: -0.12),
    (letter: 'A', top: 0.24, size: 52.0, phase: 0.18, angle: 0.10),
    (letter: 'N', top: 0.44, size: 72.0, phase: 0.42, angle: -0.08),
    (letter: 'A', top: 0.66, size: 58.0, phase: 0.65, angle: 0.14),
    (letter: 'G', top: 0.84, size: 68.0, phase: 0.82, angle: -0.16),
  ];

  double _tileLeft(double progress, double phase, double width, double size) {
    final cycle = (progress + phase) % 1;
    return (width + size) * cycle - size;
  }
}

class _MovingTile extends StatelessWidget {
  const _MovingTile({
    required this.letter,
    required this.top,
    required this.size,
    required this.angle,
    required this.left,
  });

  final String letter;
  final double top;
  final double size;
  final double angle;
  final double left;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: Transform.rotate(
        angle: angle,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD447).withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF25231F).withValues(alpha: 0.10),
            ),
          ),
          child: Text(
            letter,
            style: TextStyle(
              color: const Color(0xFF25231F).withValues(alpha: 0.22),
              fontSize: size * 0.48,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
