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
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Starfield background — simple CustomPaint ──────────────────
          const _StarfieldBackground(),

          // ── Menu content ───────────────────────────────────────────────
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Title
                const Text(
                  'ASTEROID\nMINER',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 48.0,
                    fontWeight: FontWeight.w100,
                    letterSpacing: 12.0,
                    height: 1.15,
                  ),
                ),

                const SizedBox(height: 8.0),

                // Subtitle
                Text(
                  'flutter_scene',
                  style: TextStyle(
                    color: Colors.cyanAccent.withValues(alpha: 0.6),
                    fontSize: 11.0,
                    letterSpacing: 6.0,
                    fontWeight: FontWeight.w300,
                  ),
                ),

                const Spacer(flex: 3),

                // Play button
                _MenuButton(
                  label: 'LAUNCH',
                  onTap: () => context.push(const PlayingRoute()),
                ),

                const SizedBox(height: 20.0),

                // How-to-play hint
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Text(
                    'JOYSTICK  ·  AIM & THRUST\nFIRE BUTTON  ·  SHOOT',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.28),
                      fontSize: 10.0,
                      letterSpacing: 3.0,
                      height: 2.0,
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
        builder: (_, _) => Container(
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
