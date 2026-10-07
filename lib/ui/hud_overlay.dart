import 'package:flutter/material.dart';
import 'package:bloc_signals_flutter/bloc_signals_flutter.dart';
import 'package:vector_math/vector_math.dart' as vm;

import '../game/models/game_state.dart';
import 'joystick_widget.dart';

/// HUD overlaid on [SceneView] via a [Stack].
///
/// Uses [BlocSignalSelector] for surgical per-widget rebuilds:
/// - Score widget rebuilds only when score changes.
/// - Lives widget rebuilds only when lives change.
/// - Wave/combo rebuilds only when those change.
/// - Pause overlay rebuilds only when phase changes.
class HudOverlay extends StatelessWidget {
  final GameCubit gameCubit;
  final ValueNotifier<vm.Vector2> joystickDirection;
  final ValueNotifier<bool> firePressed;
  final VoidCallback onPause;
  final VoidCallback onResume;

  const HudOverlay({
    super.key,
    required this.gameCubit,
    required this.joystickDirection,
    required this.firePressed,
    required this.onPause,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;

    return Stack(
      children: [
        // ── Pause overlay — only shown when paused ────────────────────────
        BlocSignalSelector<GameCubit, GameStateRecord, GamePhase>(
          bloc: gameCubit,
          selector: (s) => s.phase,
          builder: (_, phase) => phase == GamePhase.paused
              ? _PauseOverlay(onResume: onResume)
              : const SizedBox.shrink(),
        ),

        // ── Score — top center ────────────────────────────────────────────
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

        // ── Lives — top left ──────────────────────────────────────────────
        Positioned(
          top: padding.top + 14.0,
          left: 20.0,
          child: BlocSignalSelector<GameCubit, GameStateRecord, int>(
            bloc: gameCubit,
            selector: (s) => s.lives,
            builder: (_, lives) => Row(
              children: List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.only(right: 6.0),
                  child: Icon(
                    Icons.rocket_launch_rounded,
                    size: 18.0,
                    color: i < lives ? Colors.cyanAccent : Colors.white12,
                  ),
                ),
              ),
            ),
          ),
        ),

        // ── Wave — top right ──────────────────────────────────────────────
        Positioned(
          top: padding.top + 14.0,
          right: 20.0,
          child: BlocSignalSelector<GameCubit, GameStateRecord, int>(
            bloc: gameCubit,
            selector: (s) => s.wave,
            builder: (_, wave) => Text(
              'WAVE  $wave',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 11.0,
                letterSpacing: 4.0,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        ),

        // ── Combo indicator — centre top (only when combo > 1) ────────────
        Positioned(
          top: padding.top + 52.0,
          left: 0,
          right: 0,
          child:
              BlocSignalSelector<
                GameCubit,
                GameStateRecord,
                ({int combo, double timer})
              >(
                bloc: gameCubit,
                selector: (s) => (combo: s.combo, timer: s.comboTimer),
                builder: (_, v) {
                  if (v.combo < 2) return const SizedBox.shrink();
                  return Center(
                    child: _ComboIndicator(
                      combo: v.combo,
                      timerFraction: v.timer / 1.5,
                    ),
                  );
                },
              ),
        ),

        // ── Pause button — top right below wave ───────────────────────────
        Positioned(
          top: padding.top + 38.0,
          right: 20.0,
          child: GestureDetector(
            onTap: onPause,
            child: Icon(
              Icons.pause_circle_outline_rounded,
              color: Colors.white.withValues(alpha: 0.35),
              size: 22.0,
            ),
          ),
        ),

        // ── Joystick — bottom left ────────────────────────────────────────
        Positioned(
          bottom: padding.bottom + 24.0,
          left: 24.0,
          child: JoystickWidget(direction: joystickDirection, size: 130.0),
        ),

        // ── Fire button — bottom right ────────────────────────────────────
        Positioned(
          bottom: padding.bottom + 32.0,
          right: 32.0,
          child: ValueListenableBuilder<bool>(
            valueListenable: firePressed,
            builder: (_, pressed, _) => _FireButton(
              pressed: pressed,
              onTapDown: () => firePressed.value = true,
              onRelease: () => firePressed.value = false,
            ),
          ),
        ),

        // ── Keyboard hint — bottom centre (desktop only) ──────────────────
        Positioned(
          bottom: padding.bottom + 8.0,
          left: 0,
          right: 0,
          child: Center(
            child: Text(
              'WASD · SPACE · ESC/P',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.15),
                fontSize: 9.0,
                letterSpacing: 3.0,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Combo indicator ───────────────────────────────────────────────────────────

class _ComboIndicator extends StatelessWidget {
  final int combo;
  final double timerFraction; // 0..1 (1 = full, 0 = expired)

  const _ComboIndicator({required this.combo, required this.timerFraction});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '×$combo  COMBO',
          style: const TextStyle(
            color: Colors.amberAccent,
            fontSize: 13.0,
            fontWeight: FontWeight.bold,
            letterSpacing: 4.0,
          ),
        ),
        const SizedBox(height: 4.0),
        SizedBox(
          width: 80.0,
          height: 2.0,
          child: LinearProgressIndicator(
            value: timerFraction.clamp(0.0, 1.0),
            backgroundColor: Colors.white12,
            color: Colors.amberAccent,
          ),
        ),
      ],
    );
  }
}

// ── Pause overlay ─────────────────────────────────────────────────────────────

class _PauseOverlay extends StatelessWidget {
  final VoidCallback onResume;
  const _PauseOverlay({required this.onResume});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.65),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'PAUSED',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32.0,
                fontWeight: FontWeight.w100,
                letterSpacing: 10.0,
              ),
            ),
            const SizedBox(height: 32.0),
            GestureDetector(
              onTap: onResume,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40.0,
                  vertical: 14.0,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.cyanAccent.withValues(alpha: 0.7),
                  ),
                ),
                child: const Text(
                  'RESUME',
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 13.0,
                    letterSpacing: 6.0,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12.0),
            Text(
              'ESC or P to toggle',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.25),
                fontSize: 10.0,
                letterSpacing: 3.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fire button ───────────────────────────────────────────────────────────────

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
        duration: const Duration(milliseconds: 70),
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
