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

/// Owns the [Scene], all game objects, and the per-frame tick.
///
/// Pure Dart — no Flutter/Widget imports. The widget layer ([GameScreen])
/// awaits [load], then forwards input + ticks. State is managed by
/// [GameCubit] (CubitSignal) — synchronous, signal-speed, zero-microtask-delay.
class Game {
  final Scene scene = Scene();

  /// Reactive state — use [gameCubit.stateValue] to read, subscribe via
  /// [BlocSignalBuilder] / [BlocSignalSelector] on the Flutter side.
  final GameCubit gameCubit = GameCubit();

  // ── sub-systems ────────────────────────────────────────────────────────────
  final AsteroidField _asteroidField = AsteroidField();
  final BulletPool _bulletPool = BulletPool();

  // ── scene nodes ────────────────────────────────────────────────────────────
  late final Node _shipNode;
  late final Node _leftEngineNode;
  late final Node _rightEngineNode;
  late final Node _cameraNode;

  // ── components ─────────────────────────────────────────────────────────────
  late final ShipController _shipController;
  late final CameraShake _cameraShake;

  // ── public input API ───────────────────────────────────────────────────────
  void setShipInput(vm.Vector2 dir) => _shipController.setInput(dir);
  void setFiring(bool v) => _shipController.setFiring(v);

  // ── camera trauma ─────────────────────────────────────────────────────────
  void addCameraTrauma(double amount) => _cameraShake.addTrauma(amount);

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
    if (gameCubit.stateValue.isGameOver) return;

    // Fire bullets from the ship nose
    if (_shipController.canFire) {
      final origin =
          _shipController.worldPosition +
          _shipController.forward * 1.8 +
          vm.Vector3(0.0, 0.1, 0.0);
      _bulletPool.fire(origin, _shipController.forward);
      _shipController.consumeFire();
    }

    _asteroidField.update(dt);
    _bulletPool.update(dt);

    // Camera shake — SpringArm sets base transform; shake compounds on top
    final shakeOffset = _cameraShake.update(dt);
    _cameraNode.mutateLocalTransform(
      (m) => m.multiply(shakeOffset.toMatrix4()),
    );
  }

  // ── reset ──────────────────────────────────────────────────────────────────

  void reset() {
    _asteroidField.reset();
    _bulletPool.reset();
    _shipNode.position = vm.Vector3.zero();
    _shipController.velocity = vm.Vector3.zero();
    gameCubit.reset();
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

    // CameraComponent(activateOnMount: true) → SceneView needs no camera: arg
    // Camera node must carry no scale (trap #28)
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
