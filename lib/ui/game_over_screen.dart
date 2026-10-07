import 'package:flutter/material.dart';
import 'package:kaisel/kaisel.dart';

import '../routing/app_router.dart';

/// Game-over screen — receives [finalScore] and [wavesReached] as typed
/// route parameters from [GameOverRoute].
class GameOverScreen extends StatelessWidget {
  final int finalScore;
  final int wavesReached;

  const GameOverScreen({
    super.key,
    required this.finalScore,
    required this.wavesReached,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Faint red vignette
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.9,
                colors: [
                  Colors.transparent,
                  Colors.red.withValues(alpha: 0.16),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                const Text(
                  'GAME OVER',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 36.0,
                    fontWeight: FontWeight.w100,
                    letterSpacing: 10.0,
                  ),
                ),

                const SizedBox(height: 40.0),

                // Score
                Text(
                  '$finalScore',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 64.0,
                    fontWeight: FontWeight.w100,
                    letterSpacing: 4.0,
                  ),
                ),
                Text(
                  'POINTS',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 10.0,
                    letterSpacing: 6.0,
                  ),
                ),

                const SizedBox(height: 16.0),

                // Wave reached
                Text(
                  'WAVE  $wavesReached',
                  style: TextStyle(
                    color: Colors.cyanAccent.withValues(alpha: 0.55),
                    fontSize: 13.0,
                    letterSpacing: 5.0,
                    fontWeight: FontWeight.w300,
                  ),
                ),

                const Spacer(flex: 3),

                _ActionButton(
                  label: 'PLAY AGAIN',
                  color: Colors.cyanAccent,
                  onTap: () => context.pushOrReplaceTop(const PlayingRoute()),
                ),

                const SizedBox(height: 14.0),

                _ActionButton(
                  label: 'MAIN MENU',
                  color: Colors.white38,
                  // set([MenuRoute()]) replaces the whole stack — no back button
                  // returns to game-over after going to menu.
                  onTap: () => context.set([const MenuRoute()]),
                ),

                const Spacer(flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 48.0),
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        decoration: BoxDecoration(border: Border.all(color: color, width: 1.0)),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12.0,
              letterSpacing: 6.0,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
      ),
    );
  }
}
