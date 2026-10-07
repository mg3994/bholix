import 'package:vector_math/vector_math.dart' as vm;
import 'package:flutter_scene/scene.dart';

import '../asteroid_field.dart';
import '../bullet_pool.dart';
import '../models/game_state.dart';

/// Sphere-vs-sphere collision detection run before any component ticks.
///
/// [SceneTickListener.beforeTick] fires before all [Component.update] calls,
/// ensuring kills are reflected in the same frame's render.
class CollisionSystem extends SceneTickListener {
  final AsteroidField asteroidField;
  final BulletPool bulletPool;
  final GameCubit gameCubit;
  final void Function(double trauma) addCameraTrauma;
  final vm.Vector3 Function() getShipPosition;

  static const double _shipHitRadius = 0.9;
  static const double _bulletHitRadius = 0.13;

  // No const — AsteroidField / BulletPool are not const objects
  CollisionSystem({
    required this.asteroidField,
    required this.bulletPool,
    required this.gameCubit,
    required this.addCameraTrauma,
    required this.getShipPosition,
  });

  @override
  void beforeTick(double deltaSeconds) {
    final state = gameCubit.stateValue;
    if (!state.isPlaying) return;

    // Tick timers first so invincibility expires correctly
    gameCubit.tickTimers(deltaSeconds);

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
          final pts = asteroidField.destroy(
            asteroid.index,
            split: true,
            shipPosition: getShipPosition(),
          );
          gameCubit.addScore(pts);
          addCameraTrauma(0.18);
          break;
        }
      }
    }
  }

  void _checkShipVsAsteroid() {
    // Invincibility frames — skip ship collision check
    if (gameCubit.stateValue.isInvincible) return;

    final shipPos = getShipPosition();

    for (final asteroid in asteroidField.asteroids) {
      if (!asteroid.alive) continue;

      final dist = (shipPos - asteroid.position).length;
      if (dist < asteroid.radius + _shipHitRadius) {
        asteroidField.destroy(asteroid.index, split: false);
        gameCubit.loseLife();
        addCameraTrauma(0.9);
        return;
      }
    }
  }
}
