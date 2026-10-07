import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:vector_math/vector_math.dart' as vm;

import '../game/models/game_state.dart';
import 'joystick_widget.dart';

/// Flutter HUD drawn on top of [SceneView] via a [Stack].
///
/// This is a pure Flutter widget layer — not a [WidgetComponent] in 3D space.
/// Score and lives update reactively via [GameState] passed from
/// [ValueListenableBuilder] in [GameScreen].
class HudOverlay extends StatelessWidget {
  final GameState gameState;
  final ValueNotifier<vm.Vector2> joystickDirection;
  final ValueNotifier<bool> firePressed;

  const HudOverlay({
    super.key,
    required this.gameState,
    required this.joystickDirection,
    required this.firePressed,
  });

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;

    return Stack(
      children: [
        // ── Score — top center ───────────────────────────────────────────
        Positioned(
          top: padding.top + 16.0,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              '${gameState.score}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28.0,
                fontWeight: FontWeight.w200,
                letterSpacing: 6.0,
              ),
            ),
          ),
        ),

        // ── Lives — top left ─────────────────────────────────────────────
        Positioned(
          top: padding.top + 14.0,
          left: 20.0,
          child: Row(
            children: List.generate(3, (i) {
              return Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: Icon(
                  Icons.rocket_launch_rounded,
                  size: 18.0,
                  color: i < gameState.lives
                      ? Colors.cyanAccent
                      : Colors.white12,
                ),
              );
            }),
          ),
        ),

        // ── Joystick — bottom left ───────────────────────────────────────
        Positioned(
          bottom: padding.bottom + 24.0,
          left: 24.0,
          child: JoystickWidget(
            direction: joystickDirection,
            size: 130.0,
          ),
        ),

        // ── Fire button — bottom right ───────────────────────────────────
        Positioned(
          bottom: padding.bottom + 32.0,
          right: 32.0,
          child: ValueListenableBuilder<bool>(
            valueListenable: firePressed,
            builder: (_, pressed, __) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) => firePressed.value = true,
              onTapUp: (_) => firePressed.value = false,
              onTapCancel: () => firePressed.value = false,
              child: Container(
                width: 76.0,
                height: 76.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.cyanAccent
                      .withOpacity(pressed ? 0.30 : 0.12),
                  border: Border.all(
                    color: Colors.cyanAccent.withOpacity(0.7),
                    width: 2.0,
                  ),
                ),
                child: const Icon(
                  Icons.flash_on_rounded,
                  color: Colors.cyanAccent,
                  size: 32.0,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
