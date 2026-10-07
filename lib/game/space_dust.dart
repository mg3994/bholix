import 'dart:math' as math;
import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Creates a ambient floating space dust particle field around the player ship.
/// Gives immediate high-speed depth perception when moving through 3D space.
class SpaceDustField {
  static const int _particleCount = 180;
  static const double _fieldRadius = 45.0;

  late final InstancedMesh _mesh;
  final List<vm.Vector3> _offsets = [];
  final _rng = math.Random(1337);

  late final Node node;

  void init(Scene scene) {
    final geo = IcosphereGeometry(radius: 0.08, subdivisions: 1);
    final mat = PhysicallyBasedMaterial()
      ..baseColorFactor = vm.Vector4(0.4, 0.9, 1.0, 0.8)
      ..emissiveFactor = vm.Vector4(0.2, 0.8, 1.0, 1.0)
      ..emissiveStrength = 12.0
      ..roughnessFactor = 0.0;

    _mesh = InstancedMesh(geometry: geo, material: mat, cullInstances: false);

    for (int i = 0; i < _particleCount; i++) {
      final offset = vm.Vector3(
        (_rng.nextDouble() - 0.5) * _fieldRadius * 2.0,
        (_rng.nextDouble() - 0.5) * _fieldRadius * 0.8,
        (_rng.nextDouble() - 0.5) * _fieldRadius * 2.0,
      );
      _offsets.add(offset);
      _mesh.addInstance(vm.Matrix4.translation(offset));
    }

    node = Node()..addComponent(InstancedMeshComponent(_mesh));
    scene.add(node);
  }

  void update(vm.Vector3 shipPos) {
    _mesh.updateInstanceTransforms((transforms) {
      for (int i = 0; i < _offsets.length; i++) {
        var rel = _offsets[i];

        // Wrap particle positions relative to ship position
        if (rel.x - shipPos.x > _fieldRadius) rel.x -= _fieldRadius * 2.0;
        if (rel.x - shipPos.x < -_fieldRadius) rel.x += _fieldRadius * 2.0;
        if (rel.z - shipPos.z > _fieldRadius) rel.z -= _fieldRadius * 2.0;
        if (rel.z - shipPos.z < -_fieldRadius) rel.z += _fieldRadius * 2.0;

        _offsets[i] = rel;
        transforms[i] = vm.Matrix4.translation(rel);
      }
    });
  }
}
