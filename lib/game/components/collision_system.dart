import 'package:vector_math/vector_math.dart' as vm;
import 'package:flutter_scene/scene.dart';

import '../asteroid_field.dart';
import '../bullet_pool.dart';
import '../models/game_state.dart';

/// Runs sphere-vs-sphere collision detection before any component ticks.
///
/// [SceneTickListener.beforeTick] fires before all [Component.update] calls,
/// so kills made here are reflected in the same frame's component updates.
///
/// Holds a direct reference to [GameCubit] — reads [stateValue] for the
/// phase guard and calls [addScore] / [loseLife] which [emit] synchronously.
class CollisionSystem extends SceneTickListener {
  final AsteroidField asteroidField;
  final BulletPool bulletPool;
  final GameCubit gameCubit;
  final void Function(double trauma) addCameraTrauma;
  final vm.Vector3 Function() getShipPosition;

  static const double _shipHitRadius = 0.9;
  static const double _bulletHitRadius = 0.14;

  const CollisionSystem({
    required this.asteroidField,
    required this.bulletPool,
    required this.gameCubit,
    required this.addCameraTrauma,
    required this.getShipPosition,
  });

  @override
  void beforeTick(double deltaSeconds) {
    if (gameCubit.stateValue.isGameOver) return;
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
          final pts = asteroidField.scoreFor(asteroid.index);
          asteroidField.destroy(asteroid.index, split: true);
          gameCubit.addScore(pts);
          addCameraTrauma(0.22);
          break; // bullet consumed — next bullet
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
        gameCubit.loseLife();
        addCameraTrauma(0.85);
        return; // one hit per frame
      }
    }
  }
}
