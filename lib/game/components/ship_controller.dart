import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Drives the player ship node from joystick + keyboard input.
///
/// All transform mutations follow correct flutter_scene patterns:
/// whole-value assignment, never in-place vector/matrix edit (trap #1).
///
/// Drag is applied frame-rate-independently via the exponential decay
/// formula: `velocity *= exp(-dampingPerSecond * dt)` which gives the same
/// damping regardless of tick rate.
class ShipController extends Component {
  vm.Vector3 velocity = vm.Vector3.zero();

  double _yaw = 0.0; // current facing angle around Y (radians)
  double _roll = 0.0; // banking roll angle around Z (radians)
  double _pitch = 0.0; // pitch tilt angle around X (radians)
  vm.Vector2 _joystickInput = vm.Vector2.zero();

  double get roll => _roll;
  double get pitch => _pitch;
  double get yaw => _yaw;

  /// World position of the ship node.
  vm.Vector3 get worldPosition => node.globalTransform.getTranslation();

  // Keyboard state — held keys accumulate input
  bool _keyLeft = false;
  bool _keyRight = false;
  bool _keyUp = false; // thrust
  bool _keyDown = false; // brake
  bool _firing = false;
  double _fireCooldown = 0.0;

  static const double _thrustForce = 20.0;
  static const double _rotateSpeed = 2.8; // radians/s
  static const double _dampingPerSecond = 1.2; // velocity half-life
  static const double _maxSpeed = 24.0;
  static const double _fireRate = 0.20; // seconds between shots

  // ── input setters (called from GameScreen each frame) ─────────────────────

  void setJoystickInput(vm.Vector2 dir) => _joystickInput = dir;
  void setFiring(bool v) => _firing = v;

  void setKeyLeft(bool v) => _keyLeft = v;
  void setKeyRight(bool v) => _keyRight = v;
  void setKeyThrust(bool v) => _keyUp = v;
  void setKeyBrake(bool v) => _keyDown = v;

  bool get canFire => _fireCooldown <= 0.0 && _firing;
  void consumeFire() => _fireCooldown = _fireRate;

  /// Unit vector pointing in the direction the ship faces (+Z rotated by yaw).
  vm.Vector3 get forward => vm.Vector3(math.sin(_yaw), 0.0, math.cos(_yaw));

  /// World position of the ship node.
  vm.Vector3 get worldPosition => node.globalTransform.getTranslation();

  /// Resets controller state — called on game restart.
  void reset() {
    velocity = vm.Vector3.zero();
    _yaw = 0.0;
    _joystickInput = vm.Vector2.zero();
    _keyLeft = false;
    _keyRight = false;
    _keyUp = false;
    _keyDown = false;
    _firing = false;
    _fireCooldown = 0.0;
  }

  @override
  void update(double deltaSeconds) {
    // ── fire cooldown ──────────────────────────────────────────────────────
    if (_fireCooldown > 0.0) _fireCooldown -= deltaSeconds;

    // ── merge joystick + keyboard into composite input ─────────────────────
    double inputX = _joystickInput.x;
    double inputY = _joystickInput.y; // +1 = thrust forward

    if (_keyLeft) inputX = (inputX - 1.0).clamp(-1.0, 1.0);
    if (_keyRight) inputX = (inputX + 1.0).clamp(-1.0, 1.0);
    if (_keyUp) inputY = (inputY + 1.0).clamp(-1.0, 1.0);
    if (_keyDown) inputY = (inputY - 1.0).clamp(-1.0, 1.0);

    // ── rotation ───────────────────────────────────────────────────────────
    if (inputX.abs() > 0.05) {
      _yaw += inputX * _rotateSpeed * deltaSeconds;
    }

    // ── thrust (joystick Y: +1 = forward) ─────────────────────────────────
    // No negation here — joystick widget already inverts screen Y.
    if (inputY.abs() > 0.05) {
      final thrust = forward * (inputY * _thrustForce * deltaSeconds);
      velocity = velocity + thrust;
    }

    // ── speed clamp ────────────────────────────────────────────────────────
    if (velocity.length > _maxSpeed) {
      velocity = velocity.normalized() * _maxSpeed;
    }

    // ── frame-rate-independent exponential drag ────────────────────────────
    // pow(e, -damping * dt) gives the same effective drag at any frame rate.
    final dragFactor = math.exp(-_dampingPerSecond * deltaSeconds);
    velocity = velocity * dragFactor;

    // ── position — assign whole value (never mutate in place) ─────────────
    final pos = node.globalTransform.getTranslation();
    node.position = pos + velocity * deltaSeconds;

    // ── dynamic banking roll & pitch tilt calculation ────────────────────────
    final targetRoll = (-inputX * 0.45).clamp(-0.45, 0.45);
    final targetPitch = (-inputY * 0.22).clamp(-0.25, 0.25);

    // Smooth lerp toward target angles
    _roll += (targetRoll - _roll) * math.min(1.0, deltaSeconds * 8.0);
    _pitch += (targetPitch - _pitch) * math.min(1.0, deltaSeconds * 8.0);

    // Compose orientation quaternion: Yaw * Pitch * Roll
    final qYaw = vm.Quaternion.axisAngle(vm.Vector3(0.0, 1.0, 0.0), _yaw);
    final qPitch = vm.Quaternion.axisAngle(vm.Vector3(1.0, 0.0, 0.0), _pitch);
    final qRoll = vm.Quaternion.axisAngle(vm.Vector3(0.0, 0.0, 1.0), _roll);

    node.rotation = qYaw * qPitch * qRoll;

    // ── wrap at field boundaries ───────────────────────────────────────────
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
    node.position = p;
  }
}
