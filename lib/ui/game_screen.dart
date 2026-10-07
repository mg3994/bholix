import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:vector_math/vector_math.dart' as vm;
import 'package:flutter_scene/scene.dart';

import '../game/game.dart';
import '../game/models/game_state.dart';
import 'hud_overlay.dart';

/// Thin widget layer over [Game].
///
/// Responsibilities:
/// - Creates [Game] and awaits [Game.load].
/// - Forwards joystick / fire input into [Game] before every tick.
/// - Renders [SceneView] with no [camera:] — the [CameraComponent] inside
///   the scene is already active (set by [CameraComponent.activateOnMount]).
/// - Stacks the HUD over the scene.
/// - Shows a loading screen while the scene initialises.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final Game _game = Game();
  bool _ready = false;

  // Input notifiers — owned here so the HUD widgets can bind to them,
  // and we can read them synchronously in onTick without setState.
  final ValueNotifier<vm.Vector2> _joystickDir =
      ValueNotifier(vm.Vector2.zero());
  final ValueNotifier<bool> _firePressed = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _game.load().then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    _joystickDir.dispose();
    _firePressed.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed, double dt) {
    // Push input into the game every frame before the scene ticks.
    _game.setShipInput(_joystickDir.value);
    _game.setFiring(_firePressed.value);
    _game.tick(dt);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return _LoadingScreen();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── 3D scene ────────────────────────────────────────────────────
          // No camera: — the CameraComponent inside the scene is active.
          SceneView(
            _game.scene,
            onTick: _onTick,
          ),

          // ── HUD + game-over overlay ──────────────────────────────────────
          ValueListenableBuilder<GameState>(
            valueListenable: _game.state,
            builder: (context, gameState, _) {
              return Stack(
                children: [
                  // HUD always visible while playing
                  if (gameState.phase == GamePhase.playing)
                    HudOverlay(
                      gameState: gameState,
                      joystickDirection: _joystickDir,
                      firePressed: _firePressed,
                    ),

                  // Game-over overlay
                  if (gameState.phase == GamePhase.gameOver)
                    _GameOverOverlay(
                      score: gameState.score,
                      onRestart: () {
                        _game.reset();
                      },
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Loading screen ────────────────────────────────────────────────────────────

class _LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Colors.cyanAccent,
              strokeWidth: 1.5,
            ),
            SizedBox(height: 20.0),
            Text(
              'INITIALISING ENGINES',
              style: TextStyle(
                color: Colors.cyanAccent,
                fontSize: 12.0,
                letterSpacing: 5.0,
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Game-over overlay ─────────────────────────────────────────────────────────

class _GameOverOverlay extends StatelessWidget {
  final int score;
  final VoidCallback onRestart;

  const _GameOverOverlay({required this.score, required this.onRestart});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.72),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'GAME OVER',
              style: TextStyle(
                color: Colors.cyanAccent,
                fontSize: 36.0,
                fontWeight: FontWeight.bold,
                letterSpacing: 8.0,
              ),
            ),
            const SizedBox(height: 14.0),
            Text(
              'SCORE  $score',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 20.0,
                letterSpacing: 3.0,
              ),
            ),
            const SizedBox(height: 32.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32.0,
                  vertical: 14.0,
                ),
                textStyle: const TextStyle(
                  fontSize: 14.0,
                  letterSpacing: 3.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: onRestart,
              child: const Text('PLAY AGAIN'),
            ),
          ],
        ),
      ),
    );
  }
}
