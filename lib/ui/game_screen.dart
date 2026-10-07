import 'package:flutter/material.dart';
import 'package:bloc_signals_flutter/bloc_signals_flutter.dart';
import 'package:kaisel/kaisel.dart';
import 'package:vector_math/vector_math.dart' as vm;
import 'package:flutter_scene/scene.dart';

import '../game/game.dart';
import '../game/models/game_state.dart';
import '../routing/app_router.dart';
import 'hud_overlay.dart';

/// Thin widget layer over [Game].
///
/// - Creates [Game], awaits [Game.load].
/// - Forwards joystick + fire input synchronously each tick via [onTick].
/// - Renders [SceneView] with no [camera:] — [CameraComponent] is active.
/// - Stacks [HudOverlay] (BlocSignalSelector-driven) over the scene.
/// - Listens for [GamePhase.gameOver] via [BlocSignalListener] and navigates
///   to [GameOverRoute] via kaisel — navigation is a side-effect, not a rebuild.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final Game _game = Game();
  bool _ready = false;

  final ValueNotifier<vm.Vector2> _joystickDir = ValueNotifier(
    vm.Vector2.zero(),
  );
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
    _game.dispose();
    super.dispose();
  }

  void _onTick(Duration _, double dt) {
    _game.setShipInput(_joystickDir.value);
    _game.setFiring(_firePressed.value);
    _game.tick(dt);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const _LoadingScreen();

    // BlocSignalListener — side-effect only (navigation), zero rebuilds.
    // Listens for game-over and navigates with the final score as a typed
    // route parameter. kaisel pushOrReplaceTop avoids stacking game screens.
    return BlocSignalListener<GameCubit, GameStateRecord>(
      bloc: _game.gameCubit,
      listenWhen: (prev, curr) => prev.phase != curr.phase && curr.isGameOver,
      listener: (context, state) {
        context.pushOrReplaceTop(GameOverRoute(finalScore: state.score));
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // 3D scene — no camera: arg, CameraComponent is active
            SceneView(_game.scene, onTick: _onTick),

            // HUD — BlocSignalSelector inside, surgical per-widget rebuilds
            HudOverlay(
              gameCubit: _game.gameCubit,
              joystickDirection: _joystickDir,
              firePressed: _firePressed,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Loading screen ────────────────────────────────────────────────────────────

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

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
                fontSize: 11.0,
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
