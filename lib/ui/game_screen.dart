import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bloc_signals_flutter/bloc_signals_flutter.dart';
import 'package:kaisel/kaisel.dart';
import 'package:vector_math/vector_math.dart' as vm;
import 'package:flutter_scene/scene.dart';

import '../game/game.dart';
import '../game/models/game_state.dart';
import '../routing/app_router.dart';
import 'hud_overlay.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  final Game _game = Game();
  bool _ready = false;

  final ValueNotifier<vm.Vector2> _joystickDir = ValueNotifier(
    vm.Vector2.zero(),
  );
  final ValueNotifier<bool> _firePressed = ValueNotifier(false);

  // Keyboard — held key set, processed each tick
  final Set<LogicalKeyboardKey> _heldKeys = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _game.load().then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _joystickDir.dispose();
    _firePressed.dispose();
    _game.dispose();
    super.dispose();
  }

  // ── AppLifecycle — auto-pause when app backgrounds ────────────────────────
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_ready) return;
    if (state != AppLifecycleState.resumed) {
      // Background / inactive — pause the game
      if (_game.gameCubit.stateValue.isPlaying) {
        _game.togglePause();
      }
    }
  }

  // ── Keyboard ──────────────────────────────────────────────────────────────
  KeyEventResult _handleKey(FocusNode _, KeyEvent event) {
    final key = event.logicalKey;
    final isDown = event is KeyDownEvent || event is KeyRepeatEvent;
    final isUp = event is KeyUpEvent;

    if (isDown) _heldKeys.add(key);
    if (isUp) _heldKeys.remove(key);

    // Escape / P → toggle pause
    if (isDown &&
        (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.keyP)) {
      _game.togglePause();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _syncKeyboardToGame() {
    _game.setKeyLeft(
      _heldKeys.contains(LogicalKeyboardKey.arrowLeft) ||
          _heldKeys.contains(LogicalKeyboardKey.keyA),
    );
    _game.setKeyRight(
      _heldKeys.contains(LogicalKeyboardKey.arrowRight) ||
          _heldKeys.contains(LogicalKeyboardKey.keyD),
    );
    _game.setKeyThrust(
      _heldKeys.contains(LogicalKeyboardKey.arrowUp) ||
          _heldKeys.contains(LogicalKeyboardKey.keyW),
    );
    _game.setKeyBrake(
      _heldKeys.contains(LogicalKeyboardKey.arrowDown) ||
          _heldKeys.contains(LogicalKeyboardKey.keyS),
    );

    final spaceFire = _heldKeys.contains(LogicalKeyboardKey.space);
    // Merge with touch fire button
    if (spaceFire && !_firePressed.value) {
      _game.setFiring(true);
    } else if (!spaceFire) {
      _game.setFiring(_firePressed.value);
    }
  }

  void _onTick(Duration _, double dt) {
    _syncKeyboardToGame();
    _game.setJoystickInput(_joystickDir.value);
    _game.tick(dt);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const _LoadingScreen();

    return BlocSignalListener<GameCubit, GameStateRecord>(
      bloc: _game.gameCubit,
      listenWhen: (prev, curr) => prev.phase != curr.phase && curr.isGameOver,
      listener: (context, state) {
        context.pushOrReplaceTop(
          GameOverRoute(finalScore: state.score, wavesReached: state.wave),
        );
      },
      child: Focus(
        autofocus: true,
        onKeyEvent: _handleKey,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // 3D scene
              SceneView(_game.scene, onTick: _onTick),

              // HUD
              HudOverlay(
                gameCubit: _game.gameCubit,
                joystickDirection: _joystickDir,
                firePressed: _firePressed,
                asteroidField: _game.asteroidField,
                shipPosition: _game.shipPosition,
                onPause: _game.togglePause,
                onResume: _game.resumeGame,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Loading ───────────────────────────────────────────────────────────────────

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
