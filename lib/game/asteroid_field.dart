import 'dart:math' as math;

// ignore: depend_on_referenced_packages
import 'package:vector_math/vector_math.dart' as vm;
import 'package:flutter_scene/scene.dart';

import 'models/asteroid_data.dart';

/// Manages the entire asteroid field as a single [InstancedMesh].
///
/// One draw call for all 80 asteroids. Each asteroid's transform is updated
/// via [updateInstanceTransforms] for a single GPU upload per frame.
///
/// Rules followed:
/// - Uniform scale only on every instance (trap #4 — non-uniform scale breaks lighting).
/// - Dead instances hidden at y=-100000 (not visible=false, which doesn't work per-instance).
/// - Transform assignment uses whole-value [vm.Matrix4.compose], never in-place mutation.
class AsteroidField {
  static const int _maxSlots = 80;
  static const double _fieldRadius = 85.0;

  late final InstancedMesh _mesh;
  final List<AsteroidData> asteroids = [];
  final _rng = math.Random(42);

  late final Node node;

  /// Initialises the instanced mesh and spawns the initial field.
  /// Must be called after [Scene.initializeStaticResources] completes.
  void init(Scene scene) {
    final geo = IcosphereGeometry(radius: 1.0, subdivisions: 2);
    final mat = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(0.38, 0.32, 0.28, 1.0)
      ..roughnessFactor = 0.92
      ..metallicFactor = 0.08;

    _mesh = InstancedMesh(geometry: geo, material: mat, cullInstances: false);

    // Pre-allocate all slots hidden below the visible world
    for (int i = 0; i < _maxSlots; i++) {
      _mesh.addInstance(vm.Matrix4.translation(vm.Vector3(0.0, -100000.0, 0.0)));
    }

    // Spawn initial asteroids into all slots
    for (int i = 0; i < _maxSlots; i++) {
      _spawnIntoSlot(i);
    }

    node = Node()..addComponent(InstancedMeshComponent(_mesh));
    scene.add(node);
  }

  void _spawnIntoSlot(
    int slotIndex, {
    vm.Vector3? position,
    double? radius,
  }) {
    final r = radius ?? (1.5 + _rng.nextDouble() * 4.5);
    final pos = position ?? _randomSpawnPosition();

    final vel = vm.Vector3(
      (_rng.nextDouble() - 0.5) * 4.0,
      (_rng.nextDouble() - 0.5) * 1.0,
      (_rng.nextDouble() - 0.5) * 4.0,
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

    // Replace or append
    if (slotIndex < asteroids.length) {
      asteroids[slotIndex] = data;
    } else {
      asteroids.add(data);
    }

    _uploadTransform(data);
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
    // vm.Vector3.all(radius) — uniform scale only (trap #4)
    _mesh.setInstanceTransform(
      a.index,
      vm.Matrix4.compose(
        a.position,
        vm.Quaternion.axisAngle(a.angularAxis, a.angle),
        vm.Vector3.all(a.radius),
      ),
    );
  }

  /// Called once per frame from [Game.tick]. Updates all asteroid
  /// positions/rotations in a single [updateInstanceTransforms] batch.
  void update(double dt) {
    _mesh.updateInstanceTransforms((transforms) {
      for (final a in asteroids) {
        if (!a.alive) continue;

        // Move — assign whole value
        a.position = a.position + a.velocity * dt;
        a.angle += a.angularSpeed * dt;

        _wrapPosition(a);

        transforms[a.index] = vm.Matrix4.compose(
          a.position,
          vm.Quaternion.axisAngle(a.angularAxis, a.angle),
          vm.Vector3.all(a.radius), // uniform scale only
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

  /// Kills asteroid at [index]. If [split] is true and the asteroid is large
  /// enough, spawns two smaller children from free slots.
  void destroy(int index, {required bool split}) {
    if (index < 0 || index >= asteroids.length) return;
    final a = asteroids[index];
    if (!a.alive) return;

    a.alive = false;
    _mesh.setInstanceTransform(
      index,
      vm.Matrix4.translation(vm.Vector3(0.0, -100000.0, 0.0)),
    );

    if (!split || a.radius <= 2.5) return;

    // Find up to two dead (free) slots to reuse
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
      _spawnIntoSlot(slot, position: a.position + offset, radius: childRadius);
    }
  }

  /// Score value based on asteroid size.
  int scoreFor(int index) {
    if (index < 0 || index >= asteroids.length) return 0;
    final r = asteroids[index].radius;
    if (r > 4.0) return 25;
    if (r > 2.5) return 50;
    return 100;
  }

  /// Resets the entire field — called on game restart.
  void reset() {
    for (int i = 0; i < _maxSlots; i++) {
      _spawnIntoSlot(i);
    }
  }
}
