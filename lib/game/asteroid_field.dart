import 'dart:math' as math;

import 'package:vector_math/vector_math.dart' as vm;
import 'package:flutter_scene/scene.dart';

import 'models/asteroid_data.dart';

/// Manages the entire asteroid field as a single [InstancedMesh].
///
/// Rules:
/// - Uniform scale only — non-uniform scale breaks PBR lighting (trap #4).
/// - Dead instances hidden at y=−100000 (frustum-culled, not per-instance visible=false).
/// - All transforms batch-updated via [updateInstanceTransforms] once per frame.
class AsteroidField {
  static const int _maxSlots = 120; // increased from 80 for later waves
  static const double _fieldRadius = 90.0;

  late final InstancedMesh _mesh;
  final List<AsteroidData> asteroids = [];
  final _rng = math.Random(42);

  late final Node node;

  /// Material refs — three tiers differ by color for visual size distinction.
  // (Kept for future use when separate meshes are used per tier)

  int get aliveCount => asteroids.where((a) => a.alive).length;

  void init(Scene scene) {
    // Single shared geometry — all asteroids same shape, different scale
    final geo = IcosphereGeometry(radius: 1.0, subdivisions: 2);

    // Use one material on the InstancedMesh but apply per-instance color
    // via addInstance's optional color parameter to differentiate size tiers.
    final mat = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(0.38, 0.32, 0.28, 1.0)
      ..roughnessFactor = 0.92
      ..metallicFactor = 0.08;

    _mesh = InstancedMesh(geometry: geo, material: mat, cullInstances: false);

    // Pre-allocate all slots hidden
    for (int i = 0; i < _maxSlots; i++) {
      _mesh.addInstance(
        vm.Matrix4.translation(vm.Vector3(0.0, -100000.0, 0.0)),
        color: vm.Vector4(1.0, 1.0, 1.0, 1.0),
      );
    }

    // Spawn initial wave (wave 1 = 60 asteroids)
    spawnWave(waveNumber: 1, shipPosition: vm.Vector3.zero());

    node = Node()..addComponent(InstancedMeshComponent(_mesh));
    scene.add(node);
  }

  /// Spawns a new wave. [waveNumber] controls count and speed multiplier.
  /// [shipPosition] ensures nothing spawns too close to the player.
  void spawnWave({required int waveNumber, required vm.Vector3 shipPosition}) {
    // Kill all alive asteroids first
    for (final a in asteroids) {
      if (a.alive) {
        a.alive = false;
        _mesh.setInstanceTransform(
          a.index,
          vm.Matrix4.translation(vm.Vector3(0.0, -100000.0, 0.0)),
        );
      }
    }

    // Count for this wave: 60 + (wave-1)*8, capped at _maxSlots
    final count = (60 + (waveNumber - 1) * 8).clamp(60, _maxSlots);
    // Speed multiplier grows each wave
    final speedMult = 1.0 + (waveNumber - 1) * 0.12;

    for (int i = 0; i < count; i++) {
      _spawnIntoSlot(i, shipPosition: shipPosition, speedMultiplier: speedMult);
    }
    // Ensure remaining slots are dead
    for (int i = count; i < _maxSlots; i++) {
      if (i < asteroids.length) {
        asteroids[i].alive = false;
      }
    }
  }

  void _spawnIntoSlot(
    int slotIndex, {
    vm.Vector3? position,
    double? radius,
    vm.Vector3? shipPosition,
    double speedMultiplier = 1.0,
  }) {
    final r = radius ?? (1.5 + _rng.nextDouble() * 4.5);
    final pos =
        position ?? _safeSpawnPosition(shipPosition ?? vm.Vector3.zero());

    final vel = vm.Vector3(
      (_rng.nextDouble() - 0.5) * 4.0 * speedMultiplier,
      (_rng.nextDouble() - 0.5) * 1.0,
      (_rng.nextDouble() - 0.5) * 4.0 * speedMultiplier,
    );

    final axis = vm.Vector3(
      _rng.nextDouble() - 0.5,
      _rng.nextDouble() - 0.5,
      _rng.nextDouble() - 0.5,
    )..normalize();

    final data = AsteroidData(
      index: slotIndex,
      position: pos,
      velocity: vel,
      angularAxis: axis,
      angularSpeed: 0.3 + _rng.nextDouble() * 1.2,
      radius: r,
      alive: true,
    );

    if (slotIndex < asteroids.length) {
      asteroids[slotIndex] = data;
    } else {
      asteroids.add(data);
    }

    _uploadTransform(data);
  }

  /// Returns a spawn position at least 20 units from [shipPosition].
  vm.Vector3 _safeSpawnPosition(vm.Vector3 shipPosition) {
    for (int attempt = 0; attempt < 10; attempt++) {
      final pos = _randomSpawnPosition();
      if ((pos - shipPosition).length > 20.0) return pos;
    }
    // Fallback: force distance by placing on opposite side
    final angle = _rng.nextDouble() * math.pi * 2.0;
    const dist = 30.0;
    return vm.Vector3(
      shipPosition.x + math.cos(angle) * dist,
      (_rng.nextDouble() - 0.5) * 30.0,
      shipPosition.z + math.sin(angle) * dist,
    );
  }

  vm.Vector3 _randomSpawnPosition() {
    final angle = _rng.nextDouble() * math.pi * 2.0;
    final dist = 15.0 + _rng.nextDouble() * _fieldRadius;
    return vm.Vector3(
      math.cos(angle) * dist,
      (_rng.nextDouble() - 0.5) * 30.0,
      math.sin(angle) * dist,
    );
  }

  void _uploadTransform(AsteroidData a) {
    if (!a.alive) {
      _mesh.setInstanceTransform(
        a.index,
        vm.Matrix4.translation(vm.Vector3(0.0, -100000.0, 0.0)),
      );
      return;
    }
    // Uniform scale only — non-uniform breaks lighting (trap #4)
    _mesh.setInstanceTransform(
      a.index,
      vm.Matrix4.compose(
        a.position,
        vm.Quaternion.axisAngle(a.angularAxis, a.angle),
        vm.Vector3.all(a.radius),
      ),
    );
    // Per-instance color: large=warm grey, medium=brown-orange, small=light
    final color = _colorForRadius(a.radius);
    _mesh.setInstanceColor(a.index, color);
  }

  vm.Vector4 _colorForRadius(double r) {
    if (r > 4.0) return vm.Vector4(0.55, 0.50, 0.45, 1.0); // large: warm grey
    if (r > 2.5) return vm.Vector4(0.65, 0.45, 0.32, 1.0); // medium: brown
    return vm.Vector4(0.80, 0.72, 0.60, 1.0); // small: bright
  }

  void update(double dt) {
    _mesh.updateInstanceTransforms((transforms) {
      for (final a in asteroids) {
        if (!a.alive) continue;

        a.position = a.position + a.velocity * dt;
        a.angle += a.angularSpeed * dt;
        _wrapPosition(a);

        transforms[a.index] = vm.Matrix4.compose(
          a.position,
          vm.Quaternion.axisAngle(a.angularAxis, a.angle),
          vm.Vector3.all(a.radius),
        );
      }
    });
  }

  void _wrapPosition(AsteroidData a) {
    const b = 95.0;
    var p = a.position;
    if (p.x > b) p = vm.Vector3(-b + 1.0, p.y, p.z);
    if (p.x < -b) p = vm.Vector3(b - 1.0, p.y, p.z);
    if (p.z > b) p = vm.Vector3(p.x, p.y, -b + 1.0);
    if (p.z < -b) p = vm.Vector3(p.x, p.y, b - 1.0);
    if (p.y > 50.0) p = vm.Vector3(p.x, -50.0, p.z);
    if (p.y < -50.0) p = vm.Vector3(p.x, 50.0, p.z);
    a.position = p;
  }

  /// Kills asteroid at [index]. Optionally splits large ones.
  /// Returns score value of the destroyed asteroid.
  int destroy(int index, {required bool split, vm.Vector3? shipPosition}) {
    if (index < 0 || index >= asteroids.length) return 0;
    final a = asteroids[index];
    if (!a.alive) return 0;

    final pts = scoreFor(index);
    a.alive = false;
    _mesh.setInstanceTransform(
      index,
      vm.Matrix4.translation(vm.Vector3(0.0, -100000.0, 0.0)),
    );

    if (split && a.radius > 2.5) {
      final freeSlots = <int>[];
      for (int i = 0; i < asteroids.length && freeSlots.length < 2; i++) {
        if (!asteroids[i].alive) freeSlots.add(i);
      }
      final childRadius = a.radius * 0.52;
      for (final slot in freeSlots) {
        final offset = vm.Vector3(
          (_rng.nextDouble() - 0.5) * a.radius,
          (_rng.nextDouble() - 0.5) * a.radius,
          (_rng.nextDouble() - 0.5) * a.radius,
        );
        _spawnIntoSlot(
          slot,
          position: a.position + offset,
          radius: childRadius,
          shipPosition: shipPosition ?? vm.Vector3.zero(),
        );
      }
    }

    return pts;
  }

  int scoreFor(int index) {
    if (index < 0 || index >= asteroids.length) return 0;
    final r = asteroids[index].radius;
    if (r > 4.0) return 25;
    if (r > 2.5) return 50;
    return 100;
  }

  /// Full reset — called when game restarts.
  void reset({required vm.Vector3 shipPosition}) {
    spawnWave(waveNumber: 1, shipPosition: shipPosition);
  }
}
