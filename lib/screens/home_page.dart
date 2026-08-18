import 'package:flutter/material.dart';

import '../widgets/animated_tile_background.dart';
import 'game_page.dart';
import 'multiplayer_lobby_page.dart';
import 'settings_page.dart';
import 'stats_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const routeName = '/';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedTileBackground(),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _BananaMark(),
                    const SizedBox(height: 28),
                    Text(
                      'BANANAGRAMS',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: const Color(0xFF25231F),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Build words. Beat the clock.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF6D665B),
                      ),
                    ),
                    const SizedBox(height: 44),
                    _HomeButton(
                      label: 'PLAY',
                      icon: Icons.play_arrow_rounded,
                      onPressed: () => Navigator.pushNamed(
                        context,
                        GamePage.routeName,
                      ),
                    ),
                    const SizedBox(height: 44),
                    _HomeButton(
                      label: 'HOST / JOIN GAME',
                      icon: Icons.wifi_tethering_rounded,
                      onPressed: () => Navigator.pushNamed(
                        context,
                        MultiplayerLobbyPage.routeName,
                      ),
                    ),
                    const SizedBox(height: 44),
                    _HomeButton(
                      label: 'STATS',
                      icon: Icons.bar_chart_rounded,
                      onPressed: () => Navigator.pushNamed(
                        context,
                        StatsPage.routeName,
                      ),
                    ),
                    const SizedBox(height: 44),
                    _HomeButton(
                      label: 'SETTINGS',
                      icon: Icons.settings_rounded,
                      onPressed: () => Navigator.pushNamed(
                        context,
                        SettingsPage.routeName,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  const _HomeButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.25,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF25231F),
          foregroundColor: const Color(0xFFFFD447),
          padding: const EdgeInsets.symmetric(vertical: 18),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}

class _BananaMark extends StatelessWidget {
  const _BananaMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      decoration: const BoxDecoration(
        color: Color(0xFFFFD447),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.bakery_dining,
        size: 64,
        color: Color(0xFF25231F),
      ),
    );
  }
}