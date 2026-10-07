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
      backgroundColor: const Color(0xFF030712),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Red alert ambient glow
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.0,
                colors: [
                  Colors.redAccent.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.95),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Critical warning badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                  ),
                  child: const Text(
                    'SHIP DESTROYED · MISSION FAILED',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 11.0,
                      letterSpacing: 4.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 24.0),

                Text(
                  'GAME OVER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 10.0,
                    shadows: [
                      BoxShadow(
                        color: Colors.redAccent.withValues(alpha: 0.8),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 36.0),

                // Glassmorphic score card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 36.0),
                  padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 32.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'FINAL SCORE',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 10.0,
                          letterSpacing: 5.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        '$finalScore',
                        style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 56.0,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4.0,
                          shadows: [
                            BoxShadow(color: Colors.cyanAccent, blurRadius: 16),
                          ],
                        ),
                      ),
                      const Divider(height: 28.0, color: Colors.white10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.military_tech_rounded,
                            color: Colors.amberAccent.withValues(alpha: 0.8),
                            size: 20.0,
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            'WAVES SURVIVED: $wavesReached',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12.0,
                              letterSpacing: 4.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(flex: 3),

                _ActionButton(
                  label: 'REDEPLOY SHIP',
                  color: Colors.cyanAccent,
                  onTap: () => context.pushOrReplaceTop(const PlayingRoute()),
                ),

                const SizedBox(height: 16.0),

                _ActionButton(
                  label: 'RETURN TO COMMAND',
                  color: Colors.white54,
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
