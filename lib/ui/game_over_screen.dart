import 'package:flutter/material.dart';
import 'package:kaisel/kaisel.dart';

import '../routing/app_router.dart';

/// Dedicated game-over screen — navigated to by [GameScreen] via kaisel
/// when [GameCubit] emits [GamePhase.gameOver].
///
/// Receives [finalScore] as a typed route parameter from [GameOverRoute].
class GameOverScreen extends StatelessWidget {
  final int finalScore;
  const GameOverScreen({super.key, required this.finalScore});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Faint red vignette — visual death cue
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.9,
                colors: [
                  Colors.transparent,
                  Colors.red.withValues(alpha: 0.18),
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
                    fontSize: 38.0,
                    fontWeight: FontWeight.w100,
                    letterSpacing: 10.0,
                  ),
                ),

                const SizedBox(height: 32.0),

                // Score display
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
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11.0,
                    letterSpacing: 6.0,
                  ),
                ),

                const Spacer(flex: 3),

                // Play again — pushes PlayingRoute (replaces current top so
                // back button doesn't return to game-over)
                _ActionButton(
                  label: 'PLAY AGAIN',
                  color: Colors.cyanAccent,
                  onTap: () => context.pushOrReplaceTop(const PlayingRoute()),
                ),

                const SizedBox(height: 16.0),

                // Main menu — pop back to MenuRoute
                _ActionButton(
                  label: 'MAIN MENU',
                  color: Colors.white38,
                  onTap: () => context.push(const MenuRoute()),
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
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 1.0),
        ),
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
