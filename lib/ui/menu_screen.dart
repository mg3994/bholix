import 'package:flutter/material.dart';
import 'package:kaisel/kaisel.dart';

import '../routing/app_router.dart';

/// Main menu — entry point of the app.
///
/// Uses [context.push] (kaisel typed navigation) to start the game.
/// No game objects are created here; [GameScreen] owns the [Game] instance.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030712),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Dynamic starfield
          const _StarfieldBackground(),

          // Sci-fi grid vignette glow
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.1,
                colors: [
                  Colors.transparent,
                  Colors.cyanAccent.withValues(alpha: 0.05),
                  Colors.black.withValues(alpha: 0.85),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Glowing Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    color: Colors.cyanAccent.withValues(alpha: 0.12),
                    border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.cyanAccent,
                          boxShadow: [
                            BoxShadow(color: Colors.cyanAccent, blurRadius: 6),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'FLUTTER SCENE 3D ENGINE',
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 10.0,
                          letterSpacing: 3.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20.0),

                // Main Title with glow
                Text(
                  'ASTEROID\nMINER',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 52.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 10.0,
                    height: 1.05,
                    shadows: [
                      BoxShadow(
                        color: Colors.cyanAccent.withValues(alpha: 0.8),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12.0),

                Text(
                  'DEEP SPACE SURVIVAL COMMAND',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11.0,
                    letterSpacing: 6.0,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const Spacer(flex: 3),

                // Game Selection Cards
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _MenuButton(
                      label: 'ASTEROID MINER 3D',
                      onTap: () => context.push(const PlayingRoute()),
                    ),
                    const SizedBox(width: 16.0),
                    _MenuButton(
                      label: 'SPACE SURFER 3D',
                      onTap: () => context.push(const RunnerRoute()),
                    ),
                  ],
                ),

                const SizedBox(height: 28.0),

                // Controls hint panel
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Text(
                    'JOYSTICK / WASD  ·  FLIGHT CONTROL\nFIRE BUTTON / SPACE  ·  PLASMA CANNON',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.cyanAccent.withValues(alpha: 0.7),
                      fontSize: 10.0,
                      letterSpacing: 2.5,
                      height: 1.8,
                    ),
                  ),
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

// ── Animated play button ──────────────────────────────────────────────────────

class _MenuButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _MenuButton({required this.label, required this.onTap});

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _pulse = Tween<double>(
    begin: 0.5,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 16.0),
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.cyanAccent.withValues(alpha: _pulse.value),
              width: 1.5,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: Colors.cyanAccent.withValues(alpha: _pulse.value),
              fontSize: 14.0,
              letterSpacing: 8.0,
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Simple starfield background ───────────────────────────────────────────────

class _StarfieldBackground extends StatelessWidget {
  const _StarfieldBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _StarsPainter());
  }
}

class _StarsPainter extends CustomPainter {
  // Deterministic star positions derived from index — no Random needed
  static const int _count = 120;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < _count; i++) {
      // Pseudo-random but deterministic from i
      final t = (i * 2654435761) & 0xFFFFFFFF;
      final x = (t % 10000) / 10000.0 * size.width;
      final y = ((t >> 8) % 10000) / 10000.0 * size.height;
      final r = 0.5 + ((t >> 16) % 10) / 10.0 * 1.2;
      final brightness = 0.3 + ((t >> 20) % 10) / 10.0 * 0.7;
      paint.color = Colors.white.withValues(alpha: brightness);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_StarsPainter _) => false;
}
