import 'package:vector_math/vector_math.dart' as vm;

// ── Dart 3 record — immutable snapshot of one asteroid's state ────────────────
//
// AsteroidData is mutated in a tight per-frame loop inside AsteroidField.
// Using a mutable class here (not a record) is intentional: records would
// require allocating a new record every frame per asteroid, which creates
// unnecessary GC pressure in the hot path.
//
// The *identity* fields (index, angularAxis, angularSpeed, radius) never
// change after spawn and are exposed as a companion immutable record for
// read-only consumers (e.g. CollisionSystem).

/// Mutable runtime state for one asteroid slot.
final class AsteroidData {
  final int index; // InstancedMesh slot — immutable
  vm.Vector3 position;
  vm.Vector3 velocity;
  final vm.Vector3 angularAxis; // immutable after spawn
  final double angularSpeed; // immutable after spawn
  final double radius; // immutable after spawn
  double angle;
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

  /// Immutable snapshot — used by CollisionSystem for read-only sphere checks.
  AsteroidSnapshot get snapshot =>
      (index: index, position: position.clone(), radius: radius, alive: alive);
}

/// Immutable read-only record passed to collision consumers.
typedef AsteroidSnapshot = ({
  int index,
  vm.Vector3 position,
  double radius,
  bool alive,
});
