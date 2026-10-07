// ignore: depend_on_referenced_packages
import 'package:vector_math/vector_math.dart' as vm;
import 'package:flutter_scene/scene.dart';

import 'models/bullet_data.dart';

/// Pre-allocated pool of 30 bullet instances rendered as a single [InstancedMesh].
///
/// Dead bullets are moved to y=-100000 (off-screen, frustum-culled).
/// One draw call regardless of how many bullets are active.
class BulletPool {
  static const int _poolSize = 30;
  static const double _bulletSpeed = 55.0;
  static const double _bulletTtl = 2.5;

  late final InstancedMesh _mesh;
  final List<BulletData> bullets = [];

  late final Node node;

  /// Must be called after [Scene.initializeStaticResources] completes.
  void init(Scene scene) {
    final geo = SphereGeometry(radius: 0.14, segments: 8, rings: 6);

    // Emissive cyan — blooms nicely with the moody EnvironmentSettings
    final mat = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(0.0, 0.9, 1.0, 1.0)
      ..emissiveFactor = vm.Vector4(0.0, 0.8, 1.0, 1.0)
      ..emissiveStrength = 12.0
      ..roughnessFactor = 0.0
      ..metallicFactor = 0.0;

    _mesh = InstancedMesh(geometry: geo, material: mat, cullInstances: false);

    for (int i = 0; i < _poolSize; i++) {
      _mesh.addInstance(vm.Matrix4.translation(vm.Vector3(0.0, -100000.0, 0.0)));
      bullets.add(BulletData(
        index: i,
        position: vm.Vector3.zero(),
        velocity: vm.Vector3.zero(),
      ));
    }

    node = Node()..addComponent(InstancedMeshComponent(_mesh));
    scene.add(node);
  }

  /// Fires a bullet from [origin] in [direction] (need not be normalised).
  /// Returns false if the pool is full.
  bool fire(vm.Vector3 origin, vm.Vector3 direction) {
    for (final b in bullets) {
      if (!b.alive) {
        b.alive = true;
        b.position = origin.clone();
        b.velocity = direction.normalized() * _bulletSpeed;
        b.ttl = _bulletTtl;
        _mesh.setInstanceTransform(b.index, vm.Matrix4.translation(b.position));
        return true;
      }
    }
    return false; // pool exhausted — silently skip
  }

  /// Called once per frame from [Game.tick].
  void update(double dt) {
    _mesh.updateInstanceTransforms((transforms) {
      for (final b in bullets) {
        if (!b.alive) continue;

        b.position = b.position + b.velocity * dt;
        b.ttl -= dt;

        if (b.ttl <= 0.0) {
          b.alive = false;
          transforms[b.index] =
              vm.Matrix4.translation(vm.Vector3(0.0, -100000.0, 0.0));
        } else {
          transforms[b.index] = vm.Matrix4.translation(b.position);
        }
      }
    });
  }

  /// Kills a specific bullet slot (called by [CollisionSystem] on hit).
  void killBullet(int index) {
    if (index < 0 || index >= bullets.length) return;
    bullets[index].alive = false;
    _mesh.setInstanceTransform(
      index,
      vm.Matrix4.translation(vm.Vector3(0.0, -100000.0, 0.0)),
    );
  }

  /// Kills all bullets — called on game restart.
  void reset() {
    for (final b in bullets) {
      if (b.alive) killBullet(b.index);
      b.alive = false;
    }
  }
}
