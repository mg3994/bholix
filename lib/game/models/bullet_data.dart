import 'package:vector_math/vector_math.dart' as vm;

// ── Bullet data — same mutable-class reasoning as AsteroidData ────────────────
//
// Bullets are updated 30 times per frame in a tight loop. Immutable records
// would allocate one record per bullet per frame — that's 30 allocations/frame
// for data the GC must then collect. The mutable class holds its state in-place.
//
// The immutable record [BulletSnapshot] is the read-only surface exposed to
// CollisionSystem.

/// Mutable runtime state for one bullet pool slot.
final class BulletData {
  final int index; // InstancedMesh slot — immutable
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

  /// Immutable snapshot for collision consumers.
  BulletSnapshot get snapshot =>
      (index: index, position: position.clone(), alive: alive);
}

/// Immutable read-only record passed to collision consumers.
typedef BulletSnapshot = ({int index, vm.Vector3 position, bool alive});
