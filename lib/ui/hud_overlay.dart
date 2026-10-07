import 'package:flutter/material.dart';
import 'package:bloc_signals_flutter/bloc_signals_flutter.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../game/models/game_state.dart';
import 'joystick_widget.dart';

/// HUD drawn over [SceneView] via a [Stack].
///
/// Uses [BlocSignalSelector] for surgical per-widget rebuilds — the score
/// widget only rebuilds when score changes, lives widget only when lives
/// change. Neither re-renders when the other changes.
///
/// [BlocSignalProvider] is NOT used here — [gameCubit] is passed directly
/// because the Game owns it and GameScreen is the only consumer. Provider
/// scoping is for multi-route / multi-widget trees.
class HudOverlay extends StatelessWidget {
  final GameCubit gameCubit;
  final ValueNotifier<vm.Vector2> joystickDirection;
  final ValueNotifier<bool> firePressed;

  const HudOverlay({
    super.key,
    required this.gameCubit,
    required this.joystickDirection,
    required this.firePressed,
  });

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;

    return Stack(
      children: [
        // ── Score — rebuilds only when score changes ──────────────────────
        Positioned(
          top: padding.top + 16.0,
          left: 0,
          right: 0,
          child: BlocSignalSelector<GameCubit, GameStateRecord, int>(
            bloc: gameCubit,
            selector: (s) => s.score,
            builder: (_, score) => Center(
              child: Text(
                '$score',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28.0,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 6.0,
                ),
              ),
            ),
          ),
        ),

        // ── Lives — rebuilds only when lives count changes ────────────────
        Positioned(
          top: padding.top + 14.0,
          left: 20.0,
          child: BlocSignalSelector<GameCubit, GameStateRecord, int>(
            bloc: gameCubit,
            selector: (s) => s.lives,
            builder: (_, lives) => Row(
              children: List.generate(3, (i) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: Icon(
                    Icons.rocket_launch_rounded,
                    size: 18.0,
                    color: i < lives ? Colors.cyanAccent : Colors.white12,
                  ),
                );
              }),
            ),
          ),
        ),

        // ── Joystick — no cubit dependency, never rebuilds from state ─────
        Positioned(
          bottom: padding.bottom + 24.0,
          left: 24.0,
          child: JoystickWidget(direction: joystickDirection, size: 130.0),
        ),

        // ── Fire button — driven by ValueNotifier<bool>, not game state ───
        Positioned(
          bottom: padding.bottom + 32.0,
          right: 32.0,
          child: ValueListenableBuilder<bool>(
            valueListenable: firePressed,
            builder: (_, pressed, __) => _FireButton(
              pressed: pressed,
              onTapDown: () => firePressed.value = true,
              onRelease: () => firePressed.value = false,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Fire button widget ────────────────────────────────────────────────────────

class _FireButton extends StatelessWidget {
  final bool pressed;
  final VoidCallback onTapDown;
  final VoidCallback onRelease;

  const _FireButton({
    required this.pressed,
    required this.onTapDown,
    required this.onRelease,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => onTapDown(),
      onTapUp: (_) => onRelease(),
      onTapCancel: onRelease,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 76.0,
        height: 76.0,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.cyanAccent.withValues(alpha: pressed ? 0.32 : 0.12),
          border: Border.all(
            color: Colors.cyanAccent.withValues(alpha: pressed ? 1.0 : 0.7),
            width: pressed ? 2.5 : 2.0,
          ),
        ),
        child: Icon(
          Icons.flash_on_rounded,
          color: Colors.cyanAccent.withValues(alpha: pressed ? 1.0 : 0.85),
          size: 32.0,
        ),
      ),
    );
  }
}
