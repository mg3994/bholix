// ignore: depend_on_referenced_packages
import 'package:vector_math/vector_math.dart' as vm;
import 'package:flutter_scene/scene.dart';

import '../asteroid_field.dart';
import '../bullet_pool.dart';
import '../models/game_state.dart';

/// Runs sphere-vs-sphere collision detection before any component ticks.
///
/// [SceneTickListener.beforeTick] fires before all [Component.update] calls,
/// so kills made here are reflected in the same frame's component updates.
class CollisionSystem extends SceneTickListener {
  final AsteroidField asteroidField;
  final BulletPool bulletPool;

  /// Callbacks — kept as function references so CollisionSystem doesn't
  /// hold a hard reference to Game (avoids circular import).
  final GameState Function() getState;
  final void Function(int points) addScore;
  final void Function() loseLife;
  final void Function(double trauma) addCameraTrauma;
  final vm.Vector3 Function() getShipPosition;

  static const double _shipHitRadius = 0.9;
  static const double _bulletHitRadius = 0.14;

  CollisionSystem({
    required this.asteroidField,
    required this.bulletPool,
    required this.getState,
    required this.addScore,
    required this.loseLife,
    required this.addCameraTrauma,
    required this.getShipPosition,
  });

  @override
  void beforeTick(double deltaSeconds) {
    if (getState().phase != GamePhase.playing) return;

    _checkBulletVsAsteroid();
    _checkShipVsAsteroid();
  }

  void _checkBulletVsAsteroid() {
    for (final bullet in bulletPool.bullets) {
      if (!bullet.alive) continue;

      for (final asteroid in asteroidField.asteroids) {
        if (!asteroid.alive) continue;

        final dist = (bullet.position - asteroid.position).length;
        if (dist < asteroid.radius + _bulletHitRadius) {
          bulletPool.killBullet(bullet.index);
          final score = asteroidField.scoreFor(asteroid.index);
          asteroidField.destroy(asteroid.index, split: true);
          addScore(score);
          addCameraTrauma(0.22);
          break; // bullet is consumed — stop checking this bullet
        }
      }
    }
  }

  void _checkShipVsAsteroid() {
    final shipPos = getShipPosition();

    for (final asteroid in asteroidField.asteroids) {
      if (!asteroid.alive) continue;

      final dist = (shipPos - asteroid.position).length;
      if (dist < asteroid.radius + _shipHitRadius) {
        asteroidField.destroy(asteroid.index, split: false);
        loseLife();
        addCameraTrauma(0.85);
        return; // one collision per frame is enough
      }
    }
  }
}
