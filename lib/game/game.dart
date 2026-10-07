import 'package:flutter/foundation.dart'
    show ValueNotifier, defaultTargetPlatform, TargetPlatform;
// ignore: depend_on_referenced_packages
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
/// Architecture: pure Dart class — no Flutter imports, no Widget.
/// The widget layer ([GameScreen]) calls [load], then forwards ticks via
/// [SceneView.onTick]. Game state is exposed as a [ValueNotifier] so the
/// HUD rebuilds reactively without polling.
class Game {
  final Scene scene = Scene();
  final ValueNotifier<GameState> state = ValueNotifier(const GameState());

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

  // ── public API ─────────────────────────────────────────────────────────────

  /// World position of the ship — used by [CollisionSystem].
  vm.Vector3 get shipPosition => _shipController.worldPosition;

  /// Forward vector of the ship — used by [Game.tick] to fire bullets.
  vm.Vector3 get shipForward => _shipController.forward;

  bool get canFire => _shipController.canFire;
  void consumeFire() => _shipController.consumeFire();

  /// Pass joystick input from the UI each frame before [tick].
  void setShipInput(vm.Vector2 dir) => _shipController.setInput(dir);
  void setFiring(bool v) => _shipController.setFiring(v);

  void addScore(int points) {
    state.value = state.value.copyWith(score: state.value.score + points);
  }

  void loseLife() {
    final newLives = state.value.lives - 1;
    state.value = state.value.copyWith(
      lives: newLives,
      phase: newLives <= 0 ? GamePhase.gameOver : GamePhase.playing,
    );
  }

  void addCameraTrauma(double amount) => _cameraShake.addTrauma(amount);

  // ── load ───────────────────────────────────────────────────────────────────

  Future<void> load() async {
    // Must complete before touching any geometry or materials (idioms skill).
    await Scene.initializeStaticResources();

    // Pre-warm PBR extension shaders so the first frame doesn't hitch.
    await Scene.preload(physicalMaterials: true);

    _setupEnvironment();
    _buildShip();
    _setupCamera();
    _asteroidField.init(scene);
    _bulletPool.init(scene);
    _registerCollisionSystem();
    _applyPlatformQuality();

    // Debug-only depth conflict check — no-op in release.
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
    if (state.value.phase == GamePhase.gameOver) return;

    // Fire bullets from the ship nose
    if (_shipController.canFire) {
      final origin = _shipController.worldPosition +
          _shipController.forward * 1.8 +
          vm.Vector3(0.0, 0.1, 0.0);
      _bulletPool.fire(origin, _shipController.forward);
      _shipController.consumeFire();
    }

    // Update InstancedMesh transform batches — components tick themselves
    // via the scene loop, but these are plain Dart objects not Components.
    _asteroidField.update(dt);
    _bulletPool.update(dt);

    // Apply camera shake to the camera node offset.
    // SpringArmComponent drives the base transform; shake adds on top.
    final shakeOffset = _cameraShake.update(dt);
    // shakeOffset is a small Matrix4 displacement — compose with the
    // camera node's current transform.
    _cameraNode.mutateLocalTransform(
      (m) => m.multiply(shakeOffset.toMatrix4()),
    );
  }

  // ── reset ──────────────────────────────────────────────────────────────────

  void reset() {
    _asteroidField.reset();
    _bulletPool.reset();
    // Return ship to origin
    _shipNode.position = vm.Vector3.zero();
    _shipController.velocity = vm.Vector3.zero();
    state.value = const GameState();
  }

  // ── private setup ──────────────────────────────────────────────────────────

  void _setupEnvironment() {
    // Physical sky — analytic Rayleigh/Mie scattering; auto-bakes IBL.
    final skySource = PhysicalSkySource(
      sunDirection: (vm.Vector3(-0.4, -0.6, 0.7)..normalize()),
      turbidity: 2.0,
      energy: 0.55,
    );
    scene.skybox = Skybox(skySource, intensity: 0.35);

    // Directional light — castsShadow: true is required for god rays.
    scene.directionalLight = DirectionalLight(
      direction: (vm.Vector3(-0.4, -0.6, 0.7)..normalize()),
      color: vm.Vector3(0.9, 0.85, 0.7),
      intensity: 2.5,
      castsShadow: true,
      shadowMaxDistance: 80.0,
      shadowMapResolution: 512,
    );

    // Moody cinematic look — from flutter-scene-looks skill.
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
    // Body — WedgeGeometry (triangular prism, forward along +Z by convention)
    final bodyMat = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(0.25, 0.35, 0.55, 1.0)
      ..metallicFactor = 0.8
      ..roughnessFactor = 0.3
      ..emissiveFactor = vm.Vector4(0.05, 0.1, 0.25, 1.0)
      ..emissiveStrength = 2.0;

    final bodyNode = Node(
      mesh: Mesh(WedgeGeometry(vm.Vector3(1.2, 0.4, 2.8)), bodyMat),
    );

    // Engine materials — emissive blue-white for bloom and lens flares
    final engineMat = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(0.15, 0.15, 0.2, 1.0)
      ..metallicFactor = 0.9
      ..roughnessFactor = 0.2
      ..emissiveFactor = vm.Vector4(0.4, 0.6, 1.0, 1.0)
      ..emissiveStrength = 6.0;

    // Left engine
    _leftEngineNode = Node(
      mesh: Mesh(
        CylinderGeometry(bottomRadius: 0.18, topRadius: 0.12, height: 1.0),
        engineMat,
      ),
    )..position = vm.Vector3(-0.55, -0.05, 0.8);

    // Right engine
    _rightEngineNode = Node(
      mesh: Mesh(
        CylinderGeometry(bottomRadius: 0.18, topRadius: 0.12, height: 1.0),
        engineMat,
      ),
    )..position = vm.Vector3(0.55, -0.05, 0.8);

    // Engine glow — PointLight on each engine nozzle drives lens flares
    final leftGlow = PointLight(
      color: vm.Vector3(0.4, 0.6, 1.0),
      intensity: 3.0,
      range: 4.0,
    );
    _leftEngineNode.addComponent(PointLightComponent(leftGlow));

    final rightGlow = PointLight(
      color: vm.Vector3(0.4, 0.6, 1.0),
      intensity: 3.0,
      range: 4.0,
    );
    _rightEngineNode.addComponent(PointLightComponent(rightGlow));

    // Exhaust trails
    _leftEngineNode.addComponent(
      TrailComponent(
        width: 0.18,
        lifetime: 0.5,
        minVertexDistance: 0.04,
        maxPoints: 40,
      ),
    );
    _rightEngineNode.addComponent(
      TrailComponent(
        width: 0.18,
        lifetime: 0.5,
        minVertexDistance: 0.04,
        maxPoints: 40,
      ),
    );

    // Root ship node carries ShipController
    _shipNode = Node();
    _shipController = ShipController();
    _shipNode.addComponent(_shipController);
    _shipNode.add(bodyNode);
    _shipNode.add(_leftEngineNode);
    _shipNode.add(_rightEngineNode);

    scene.add(_shipNode);
  }

  void _setupCamera() {
    _cameraShake = CameraShake(decayRate: 1.5, frequency: 28.0);

    // Camera node — MUST carry no scale (trap #28).
    // CameraComponent(activateOnMount: true) makes this the active camera,
    // so SceneView needs no camera: argument.
    _cameraNode = Node()
      ..addComponent(CameraComponent(activateOnMount: true));

    // SpringArmComponent on the ship root: camera follows with lag and
    // pulls in automatically when geometry clips the arm.
    final arm = SpringArmComponent(
      targetLength: 9.0,
      targetOffset: vm.Vector3(0.0, 1.8, 0.0),
      socketOffset: vm.Vector3(0.3, 0.0, 0.0),
      enablePositionLag: true,
      positionLagSpeed: 7.0,
      cameraNode: _cameraNode,
    );
    _shipNode.addComponent(arm);

    scene.add(_cameraNode);
  }

  void _registerCollisionSystem() {
    scene.addTickListener(CollisionSystem(
      asteroidField: _asteroidField,
      bulletPool: _bulletPool,
      getState: () => state.value,
      addScore: addScore,
      loseLife: loseLife,
      addCameraTrauma: addCameraTrauma,
      getShipPosition: () => shipPosition,
    ));
  }

  void _applyPlatformQuality() {
    final isMobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;

    if (isMobile) {
      // Reduce render scale on mobile to hit frame budget
      scene.renderScale = 0.85;
      scene.antiAliasingMode = AntiAliasingMode.fxaa;
    } else {
      scene.antiAliasingMode = AntiAliasingMode.smaa;
    }
  }
}
