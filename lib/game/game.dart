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
import 'space_dust.dart';

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
  final SpaceDustField _spaceDust = SpaceDustField();

  AsteroidField get asteroidField => _asteroidField;
  vm.Vector3 get shipPosition => _shipController.worldPosition;

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
    _spaceDust.init(scene);
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
    _spaceDust.update(_shipController.worldPosition);

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
      sunDirection: (vm.Vector3(-0.5, -0.4, 0.77)..normalize()),
      turbidity: 1.5,
      energy: 0.3,
    );
    scene.skybox = Skybox(skySource, intensity: 0.25);

    scene.directionalLight = DirectionalLight(
      direction: (vm.Vector3(-0.5, -0.6, 0.6)..normalize()),
      color: vm.Vector3(0.7, 0.85, 1.0), // Deep blue-cyan cosmic star light
      intensity: 3.0,
      castsShadow: true,
      shadowMaxDistance: 80.0,
      shadowMapResolution: 512, // Reduced from 1024 to 512 for high FPS
    );

    // Optimized EnvironmentSettings to eliminate frame drops across web/desktop/mobile
    scene.environmentSettings = EnvironmentSettings(
      toneMapping: ToneMappingMode.aces,
      exposure: 1.0,
      colorGradingEnabled: false,
      fogEnabled: true,
      fogMode: FogMode.exponential,
      fogColor: vm.Vector3(0.01, 0.02, 0.06),
      fogDensity: 0.005,
      ambientOcclusionEnabled: false, // Disabling GTAO pass eliminates heavy GPU overhead
      vignetteEnabled: true,
      vignetteIntensity: 0.5,
      vignetteRadius: 0.6,
      bloomEnabled: true,
      bloomThreshold: 0.7,
      bloomIntensity: 0.5,
      bloomScatter: 0.7,
      lensFlareEnabled: false,
      filmGrainEnabled: false,
      chromaticAberrationEnabled: true,
      chromaticAberrationIntensity: 0.06,
      godRaysEnabled: false, // Disabling god rays pass prevents frame drops
    );
  }

  void _buildShip() {
    // Futuristic multi-part Starfighter mesh

    // 1. Sleek metallic Fuselage
    final bodyMat = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(0.08, 0.12, 0.2, 1.0)
      ..metallicFactor = 0.95
      ..roughnessFactor = 0.15
      ..emissiveFactor = vm.Vector4(0.0, 0.3, 0.6, 1.0)
      ..emissiveStrength = 3.0;

    final bodyNode = Node(
      mesh: Mesh(WedgeGeometry(vm.Vector3(1.1, 0.45, 3.2)), bodyMat),
    );

    // 2. Glowing Sci-Fi Canopy / Cockpit
    final cockpitMat = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(0.0, 0.8, 1.0, 0.8)
      ..metallicFactor = 0.1
      ..roughnessFactor = 0.05
      ..emissiveFactor = vm.Vector4(0.0, 0.9, 1.0, 1.0)
      ..emissiveStrength = 10.0;

    final cockpitNode = Node(
      mesh: Mesh(CapsuleGeometry(radius: 0.32, height: 0.9), cockpitMat),
    )..position = vm.Vector3(0.0, 0.22, -0.3);

    // 3. Swept-Back Wings
    final wingMat = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(0.12, 0.16, 0.25, 1.0)
      ..metallicFactor = 0.9
      ..roughnessFactor = 0.25;

    final leftWing = Node(
      mesh: Mesh(WedgeGeometry(vm.Vector3(1.8, 0.08, 1.6)), wingMat),
    )..position = vm.Vector3(-1.1, 0.0, 0.3);

    final rightWing = Node(
      mesh: Mesh(WedgeGeometry(vm.Vector3(1.8, 0.08, 1.6)), wingMat),
    )..position = vm.Vector3(1.1, 0.0, 0.3);

    // Wingtip glowing plasma emitters
    final wingtipGlowMat = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(0.0, 1.0, 0.8, 1.0)
      ..emissiveFactor = vm.Vector4(0.0, 1.0, 0.8, 1.0)
      ..emissiveStrength = 15.0;

    leftWing.add(
      Node(mesh: Mesh(SphereGeometry(radius: 0.12), wingtipGlowMat))
        ..position = vm.Vector3(-0.9, 0.0, 0.6),
    );
    rightWing.add(
      Node(mesh: Mesh(SphereGeometry(radius: 0.12), wingtipGlowMat))
        ..position = vm.Vector3(0.9, 0.0, 0.6),
    );

    // 4. Dual Plasma Engines with dynamic lights & trails
    final engineMat = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(0.1, 0.1, 0.15, 1.0)
      ..metallicFactor = 0.95
      ..roughnessFactor = 0.1
      ..emissiveFactor = vm.Vector4(0.0, 0.7, 1.0, 1.0)
      ..emissiveStrength = 18.0;

    _leftEngineNode = Node(
      mesh: Mesh(
        CylinderGeometry(bottomRadius: 0.22, topRadius: 0.12, height: 1.2),
        engineMat,
      ),
    )..position = vm.Vector3(-0.6, -0.02, 1.1);

    _rightEngineNode = Node(
      mesh: Mesh(
        CylinderGeometry(bottomRadius: 0.22, topRadius: 0.12, height: 1.2),
        engineMat,
      ),
    )..position = vm.Vector3(0.6, -0.02, 1.1);

    _leftEngineNode
      ..addComponent(
        PointLightComponent(
          PointLight(
            color: vm.Vector3(0.0, 0.8, 1.0),
            intensity: 8.0,
            range: 6.0,
          ),
        ),
      )
      ..addComponent(
        TrailComponent(
          width: 0.28,
          lifetime: 0.6,
          minVertexDistance: 0.03,
          maxPoints: 60,
        ),
      );

    _rightEngineNode
      ..addComponent(
        PointLightComponent(
          PointLight(
            color: vm.Vector3(0.0, 0.8, 1.0),
            intensity: 8.0,
            range: 6.0,
          ),
        ),
      )
      ..addComponent(
        TrailComponent(
          width: 0.28,
          lifetime: 0.6,
          minVertexDistance: 0.03,
          maxPoints: 60,
        ),
      );

    _shipNode = Node();
    _shipController = ShipController();
    _shipNode
      ..addComponent(_shipController)
      ..add(bodyNode)
      ..add(cockpitNode)
      ..add(leftWing)
      ..add(rightWing)
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
