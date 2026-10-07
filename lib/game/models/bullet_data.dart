import 'package:vector_math/vector_math.dart' as vm;

class BulletData {
  final int index; // slot index in InstancedMesh — immutable
  vm.Vector3 position;
  vm.Vector3 velocity;
  double ttl; // seconds remaining
  bool alive;

  BulletData({
    required this.index,
    required this.position,
    required this.velocity,
    this.ttl = 2.5,
    this.alive = false,
  });
}
