import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Drives the player ship node from joystick input.
///
/// Input is set each frame via [setInput] (called from GameScreen before
/// the scene tick). All transform mutations use the correct flutter_scene
/// patterns — whole-value assignment, never in-place vector edit.
class ShipController extends Component {
  vm.Vector3 velocity = vm.Vector3.zero();

  double _yaw = 0.0; // current facing angle around Y (radians)
  vm.Vector2 _input = vm.Vector2.zero(); // joystick -1..1
  bool _firing = false;
  double _fireCooldown = 0.0;

  static const double _thrustForce = 18.0;
  static const double _rotateSpeed = 2.8; // radians per second
  static const double _drag = 0.96; // per-frame multiplier
  static const double _maxSpeed = 22.0;
  static const double _fireRate = 0.22; // seconds between shots

  // Called every frame from GameScreen/Game before scene tick
  void setInput(vm.Vector2 dir) => _input = dir;
  void setFiring(bool v) => _firing = v;

  bool get canFire => _fireCooldown <= 0.0 && _firing;
  void consumeFire() => _fireCooldown = _fireRate;

  /// Unit vector pointing in the direction the ship faces (+Z rotated by yaw).
  vm.Vector3 get forward =>
      vm.Vector3(math.sin(_yaw), 0.0, math.cos(_yaw));

  /// Current world position of the ship node.
  vm.Vector3 get worldPosition => node.globalTransform.getTranslation();

  @override
  void update(double deltaSeconds) {
    // ── fire cooldown ───────────────────────────────────────────────────────
    if (_fireCooldown > 0.0) _fireCooldown -= deltaSeconds;

    // ── rotation (joystick X) ───────────────────────────────────────────────
    if (_input.x.abs() > 0.05) {
      _yaw += _input.x * _rotateSpeed * deltaSeconds;
    }

    // ── thrust (joystick Y, +Y = forward on stick = -Y in screen coords) ───
    if (_input.y.abs() > 0.05) {
      // Joystick Y: pushing up (+1) should thrust forward
      final thrust = forward * (-_input.y * _thrustForce * deltaSeconds);
      velocity = velocity + thrust;
    }

    // ── speed clamp ─────────────────────────────────────────────────────────
    if (velocity.length > _maxSpeed) {
      velocity = velocity.normalized() * _maxSpeed;
    }

    // ── drag ────────────────────────────────────────────────────────────────
    velocity = velocity * _drag;

    // ── position — assign whole value, NEVER mutate in place (trap #1) ─────
    final pos = node.globalTransform.getTranslation();
    node.position = pos + velocity * deltaSeconds;

    // ── facing rotation — assign whole Quaternion ───────────────────────────
    node.rotation = vm.Quaternion.axisAngle(vm.Vector3(0.0, 1.0, 0.0), _yaw);

    // ── world boundary wrap ─────────────────────────────────────────────────
    _wrapPosition();
  }

  void _wrapPosition() {
    const bound = 90.0;
    var p = node.position;
    if (p.x > bound) p = vm.Vector3(-bound + 1.0, p.y, p.z);
    if (p.x < -bound) p = vm.Vector3(bound - 1.0, p.y, p.z);
    if (p.z > bound) p = vm.Vector3(p.x, p.y, -bound + 1.0);
    if (p.z < -bound) p = vm.Vector3(p.x, p.y, bound - 1.0);
    if (p.y > 20.0) p = vm.Vector3(p.x, 20.0, p.z);
    if (p.y < -20.0) p = vm.Vector3(p.x, -20.0, p.z);
    // Assign whole value — correct pattern
    node.position = p;
  }
}
