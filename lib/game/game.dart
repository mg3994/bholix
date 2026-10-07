import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:vector_math/vector_math.dart' as vm;
import 'package:flutter_scene/scene.dart';
import 'package:flutter_scene/kit.dart';

import 'asteroid_field.dart';
import 'bullet_pool.dart';
import 'components/ship_controller.dart';
import 'components/collision_system.dart';
import 'models/game_state.dart';

/// Owns the [Scene], sub-systems, and per-frame tick.
///
/// Pure Dart — no Flutter/Widget imports. The widget layer ([GameScreen])
/// awaits [load], then forwards input + ticks each frame.
///
/// State management: [GameCubit] (CubitSignal) — synchronous emit,
/// zero-microtask-delay, signal-speed reactive widgets.
class Game {
  final Scene scene = Scene();
  final GameCubit gameCubit = GameCubit();

  // ── sub-systems ────────────────────────────────────────────────────────────
  final AsteroidField _asteroidField = AsteroidField();
  final BulletPool _bulletPool = BulletPool();

  // ── scene nodes ─── (declared at class level, initialised in _buildShip) ──
  late final Node _shipNode;
  late final Node _leftEngineNode;
  late final Node _rightEngineNode;
  late final Node _cameraNode;

  // ── components ─────────────────────────────────────────────────────────────
  late final ShipController _shipController;
  late final CameraShake _cameraShake;

  // ── ship visibility for invincibility flash ────────────────────────────────
  double _flashTimer = 0.0;
  bool _shipVisible = true;

  // ── public input API ───────────────────────────────────────────────────────
  void setJoystickInput(vm.Vector2 dir) =>
      _shipController.setJoystickInput(dir);
  void setFiring(bool v) => _shipController.setFiring(v);
  void setKeyLeft(bool v) => _shipController.setKeyLeft(v);
  void setKeyRight(bool v) => _shipController.setKeyRight(v);
  void setKeyThrust(bool v) => _shipController.setKeyThrust(v);
  void setKeyBrake(bool v) => _shipController.setKeyBrake(v);

  void addCameraTrauma(double amount) => _cameraShake.addTrauma(amount);
  void togglePause() => gameCubit.togglePause();
  void resumeGame() => gameCubit.resume();

  // ── load ───────────────────────────────────────────────────────────────────

  Future<void> load() async {
    await Scene.initializeStaticResources();
    await Scene.preload(physicalMaterials: true);

    _setupEnvironment();
    _buildShip();
    _setupCamera();
    _asteroidField.init(scene);
    _bulletPool.init(scene);
    _registerCollisionSystem();
    _applyPlatformQuality();

    assert(() {
      Future<void>.microtask(() async {
        final report = await scene.probeDepthConflicts();
        if (report.conflicts.isNotEmpty) {
          // ignore: avoid_print
          print('⚠️  Depth conflicts:\n${report.describe()}');
        } else {
          // ignore: avoid_print
          print('✅  No depth conflicts');
        }
      });
      return true;
    }());
  }

  // ── tick ───────────────────────────────────────────────────────────────────

  void tick(double dt) {
    final state = gameCubit.stateValue;

    // Paused or game over — don't update game objects
    if (state.isPaused || state.isGameOver) return;

    // ── fire bullets ───────────────────────────────────────────────────────
    if (_shipController.canFire) {
      final origin =
          _shipController.worldPosition +
          _shipController.forward * 2.0 +
          vm.Vector3(0.0, 0.1, 0.0);
      _bulletPool.fire(origin, _shipController.forward);
      _shipController.consumeFire();
    }

    _asteroidField.update(dt);
    _bulletPool.update(dt);

    // ── invincibility flash ────────────────────────────────────────────────
    _updateInvincibilityFlash(dt, state);

    // ── wave completion check ──────────────────────────────────────────────
    if (_asteroidField.aliveCount == 0) {
      gameCubit.nextWave();
      final nextWave = gameCubit.stateValue.wave;
      _asteroidField.spawnWave(
        waveNumber: nextWave,
        shipPosition: _shipController.worldPosition,
      );
    }

    // ── camera shake ───────────────────────────────────────────────────────
    // SpringArmComponent writes the camera's base transform each frame.
    // We apply shake as an ADDITIVE translation offset only, not a matrix
    // multiply (which would compound indefinitely).
    final shakeOffset = _cameraShake.update(dt);
    final translation = shakeOffset.toMatrix4().getTranslation();
    if (translation.length > 0.001) {
      _cameraNode.mutateLocalTransform((m) {
        m.translateByVector3(translation);
      });
    }
  }

  void _updateInvincibilityFlash(double dt, GameStateRecord state) {
    if (!state.isInvincible) {
      if (!_shipVisible) {
        _shipNode.visible = true;
        _shipVisible = true;
      }
      _flashTimer = 0.0;
      return;
    }
    _flashTimer += dt;
    // Flash at 8 Hz (0.125s period)
    final shouldBeVisible = (_flashTimer % 0.125) < 0.0625;
    if (shouldBeVisible != _shipVisible) {
      _shipNode.visible = shouldBeVisible;
      _shipVisible = shouldBeVisible;
    }
  }

  // ── reset ──────────────────────────────────────────────────────────────────

  void reset() {
    _bulletPool.reset();
    _shipNode.position = vm.Vector3.zero();
    _shipNode.visible = true;
    _shipVisible = true;
    _flashTimer = 0.0;
    _shipController.reset();
    gameCubit.reset();
    _asteroidField.reset(shipPosition: vm.Vector3.zero());
  }

  // ── dispose ────────────────────────────────────────────────────────────────

  void dispose() => gameCubit.close();

  // ── private setup ──────────────────────────────────────────────────────────

  void _setupEnvironment() {
    final skySource = PhysicalSkySource(
      sunDirection: (vm.Vector3(-0.4, -0.6, 0.7)..normalize()),
      turbidity: 2.0,
      energy: 0.55,
    );
    scene.skybox = Skybox(skySource, intensity: 0.35);

    scene.directionalLight = DirectionalLight(
      direction: (vm.Vector3(-0.4, -0.6, 0.7)..normalize()),
      color: vm.Vector3(0.9, 0.85, 0.7),
      intensity: 2.5,
      castsShadow: true,
      shadowMaxDistance: 80.0,
      shadowMapResolution: 512,
    );

    scene.environmentSettings = EnvironmentSettings(
      toneMapping: ToneMappingMode.aces,
      exposure: 0.8,
      colorGradingEnabled: true,
      contrast: 1.15,
      saturation: 0.85,
      temperature: -0.15,
      fogEnabled: true,
      fogMode: FogMode.exponential,
      fogColor: vm.Vector3(0.01, 0.01, 0.04),
      fogDensity: 0.008,
      ambientOcclusionEnabled: true,
      ambientOcclusionMethod: AmbientOcclusionMethod.groundTruth,
      ambientOcclusionHalfResolution: true,
      ambientOcclusionIntensity: 1.0,
      vignetteEnabled: true,
      vignetteIntensity: 0.55,
      vignetteRadius: 0.65,
      bloomEnabled: true,
      bloomThreshold: 0.85,
      bloomIntensity: 0.35,
      bloomScatter: 0.75,
      lensFlareEnabled: true,
      lensFlareIntensity: 0.6,
      filmGrainEnabled: true,
      filmGrainIntensity: 0.18,
      chromaticAberrationEnabled: true,
      chromaticAberrationIntensity: 0.08,
      godRaysEnabled: true,
      godRaysIntensity: 0.8,
      godRaysDensity: 0.5,
      godRaysColor: vm.Vector3(0.9, 0.85, 0.7),
    );
  }

  void _buildShip() {
    final bodyMat = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(0.25, 0.35, 0.55, 1.0)
      ..metallicFactor = 0.8
      ..roughnessFactor = 0.3
      ..emissiveFactor = vm.Vector4(0.05, 0.1, 0.25, 1.0)
      ..emissiveStrength = 2.0;

    final bodyNode = Node(
      mesh: Mesh(WedgeGeometry(vm.Vector3(1.2, 0.4, 2.8)), bodyMat),
    );

    final engineMat = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(0.15, 0.15, 0.2, 1.0)
      ..metallicFactor = 0.9
      ..roughnessFactor = 0.2
      ..emissiveFactor = vm.Vector4(0.4, 0.6, 1.0, 1.0)
      ..emissiveStrength = 6.0;

    _leftEngineNode = Node(
      mesh: Mesh(
        CylinderGeometry(bottomRadius: 0.18, topRadius: 0.12, height: 1.0),
        engineMat,
      ),
    )..position = vm.Vector3(-0.55, -0.05, 0.8);

    _rightEngineNode = Node(
      mesh: Mesh(
        CylinderGeometry(bottomRadius: 0.18, topRadius: 0.12, height: 1.0),
        engineMat,
      ),
    )..position = vm.Vector3(0.55, -0.05, 0.8);

    _leftEngineNode
      ..addComponent(
        PointLightComponent(
          PointLight(
            color: vm.Vector3(0.4, 0.6, 1.0),
            intensity: 3.0,
            range: 4.0,
          ),
        ),
      )
      ..addComponent(
        TrailComponent(
          width: 0.18,
          lifetime: 0.5,
          minVertexDistance: 0.04,
          maxPoints: 40,
        ),
      );

    _rightEngineNode
      ..addComponent(
        PointLightComponent(
          PointLight(
            color: vm.Vector3(0.4, 0.6, 1.0),
            intensity: 3.0,
            range: 4.0,
          ),
        ),
      )
      ..addComponent(
        TrailComponent(
          width: 0.18,
          lifetime: 0.5,
          minVertexDistance: 0.04,
          maxPoints: 40,
        ),
      );

    _shipNode = Node();
    _shipController = ShipController();
    _shipNode
      ..addComponent(_shipController)
      ..add(bodyNode)
      ..add(_leftEngineNode)
      ..add(_rightEngineNode);

    scene.add(_shipNode);
  }

  void _setupCamera() {
    _cameraShake = CameraShake(decayRate: 1.5, frequency: 28.0);

    // Camera node must carry no scale (trap #28).
    _cameraNode = Node()..addComponent(CameraComponent(activateOnMount: true));

    _shipNode.addComponent(
      SpringArmComponent(
        targetLength: 9.0,
        targetOffset: vm.Vector3(0.0, 1.8, 0.0),
        socketOffset: vm.Vector3(0.3, 0.0, 0.0),
        enablePositionLag: true,
        positionLagSpeed: 7.0,
        cameraNode: _cameraNode,
      ),
    );

    scene.add(_cameraNode);
  }

  void _registerCollisionSystem() {
    scene.addTickListener(
      CollisionSystem(
        asteroidField: _asteroidField,
        bulletPool: _bulletPool,
        gameCubit: gameCubit,
        addCameraTrauma: addCameraTrauma,
        getShipPosition: () => _shipController.worldPosition,
      ),
    );
  }

  void _applyPlatformQuality() {
    final isMobile =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (isMobile) {
      scene.renderScale = 0.85;
      scene.antiAliasingMode = AntiAliasingMode.fxaa;
    } else {
      scene.antiAliasingMode = AntiAliasingMode.smaa;
    }
  }
}
