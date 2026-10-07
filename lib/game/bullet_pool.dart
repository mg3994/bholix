import 'package:vector_math/vector_math.dart' as vm;
import 'package:flutter_scene/scene.dart';

import 'models/bullet_data.dart';

/// Pre-allocated pool of 30 bullets rendered as a single [InstancedMesh].
///
/// Each bullet is elongated along its velocity direction via non-uniform Z
/// scale — visually looks like a bolt/tracer. Dead bullets move to y=−100000.
class BulletPool {
  static const int _poolSize = 30;
  static const double _bulletSpeed = 55.0;
  static const double _bulletTtl = 2.5;
  static const double _bulletRadiusXY = 0.12;
  static const double _bulletLengthZ = 0.55; // elongated along direction

  late final InstancedMesh _mesh;
  final List<BulletData> bullets = [];

  late final Node node;

  void init(Scene scene) {
    // Capsule elongated along Z — visually a tracer bolt
    final geo = CapsuleGeometry(
      radius: _bulletRadiusXY * 1.2,
      height: _bulletLengthZ * 1.5,
    );

    final mat = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(0.0, 1.0, 0.9, 1.0)
      ..emissiveFactor = vm.Vector4(0.0, 1.0, 0.9, 1.0)
      ..emissiveStrength = 28.0
      ..roughnessFactor = 0.0
      ..metallicFactor = 0.0;

    _mesh = InstancedMesh(geometry: geo, material: mat, cullInstances: false);

    for (int i = 0; i < _poolSize; i++) {
      _mesh.addInstance(
        vm.Matrix4.translation(vm.Vector3(0.0, -100000.0, 0.0)),
      );
      bullets.add(
        BulletData(
          index: i,
          position: vm.Vector3.zero(),
          velocity: vm.Vector3.zero(),
        ),
      );
    }

    node = Node()..addComponent(InstancedMeshComponent(_mesh));
    scene.add(node);
  }

  bool fire(vm.Vector3 origin, vm.Vector3 direction) {
    for (final b in bullets) {
      if (!b.alive) {
        b.alive = true;
        b.position = origin.clone();
        b.velocity = direction.normalized() * _bulletSpeed;
        b.ttl = _bulletTtl;
        _mesh.setInstanceTransform(b.index, _bulletTransform(b));
        return true;
      }
    }
    return false;
  }

  void update(double dt) {
    _mesh.updateInstanceTransforms((transforms) {
      for (final b in bullets) {
        if (!b.alive) continue;

        b.position = b.position + b.velocity * dt;
        b.ttl -= dt;

        if (b.ttl <= 0.0) {
          b.alive = false;
          transforms[b.index] = vm.Matrix4.translation(
            vm.Vector3(0.0, -100000.0, 0.0),
          );
        } else {
          transforms[b.index] = _bulletTransform(b);
        }
      }
    });
  }

  /// Orients the bullet capsule along its velocity vector.
  /// Uses a rotation from +Y (capsule default axis) to the velocity direction.
  vm.Matrix4 _bulletTransform(BulletData b) {
    final dir = b.velocity.normalized();
    // Rotation from local +Y to velocity direction
    final rotation = _rotationFromYToDir(dir);
    return vm.Matrix4.compose(
      b.position,
      rotation,
      vm.Vector3(1.0, 1.0, 1.0), // uniform scale — elongation is in geometry
    );
  }

  vm.Quaternion _rotationFromYToDir(vm.Vector3 dir) {
    final yAxis = vm.Vector3(0.0, 1.0, 0.0);
    final d = dir.normalized();
    if ((d - yAxis).length < 0.001) return vm.Quaternion.identity();
    if ((d + yAxis).length < 0.001) {
      return vm.Quaternion.axisAngle(vm.Vector3(1.0, 0.0, 0.0), 3.14159);
    }
    return vm.Quaternion.fromTwoVectors(yAxis, d);
  }

  void killBullet(int index) {
    if (index < 0 || index >= bullets.length) return;
    bullets[index].alive = false;
    _mesh.setInstanceTransform(
      index,
      vm.Matrix4.translation(vm.Vector3(0.0, -100000.0, 0.0)),
    );
  }

  void reset() {
    for (final b in bullets) {
      if (b.alive) killBullet(b.index);
    }
  }
}
