import 'package:vector_math/vector_math.dart' as vm;

class AsteroidData {
  final int index; // slot index in InstancedMesh — immutable
  vm.Vector3 position;
  vm.Vector3 velocity;
  vm.Vector3 angularAxis;
  double angularSpeed;
  double radius;
  double angle; // current rotation angle (radians)
  bool alive;

  AsteroidData({
    required this.index,
    required this.position,
    required this.velocity,
    required this.angularAxis,
    required this.angularSpeed,
    required this.radius,
    this.angle = 0.0,
    this.alive = true,
  });
}
