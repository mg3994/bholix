import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' as vm;
import '../game/asteroid_field.dart';

/// Tactical space mini-map radar widget overlay showing relative positions of asteroids and ship.
class RadarWidget extends StatelessWidget {
  final vm.Vector3 shipPos;
  final double shipYaw;
  final AsteroidField asteroidField;
  final double radius;

  const RadarWidget({
    super.key,
    required this.shipPos,
    required this.shipYaw,
    required this.asteroidField,
    this.radius = 48.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF07111E).withValues(alpha: 0.8),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withValues(alpha: 0.15),
            blurRadius: 10,
          ),
        ],
      ),
      child: CustomPaint(
        painter: _RadarPainter(
          shipPos: shipPos,
          shipYaw: shipYaw,
          asteroids: asteroidField.asteroids,
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final vm.Vector3 shipPos;
  final double shipYaw;
  final List asteroids;

  _RadarPainter({
    required this.shipPos,
    required this.shipYaw,
    required this.asteroids,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxDist = 70.0;
    final r = size.width / 2;

    // Crosshair rings
    final ringPaint = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, r * 0.5, ringPaint);
    canvas.drawCircle(center, r * 0.85, ringPaint);

    // Player ship blip (centre cyan arrow)
    final shipPaint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(center.dx, center.dy - 5)
      ..lineTo(center.dx - 3, center.dy + 4)
      ..lineTo(center.dx + 3, center.dy + 4)
      ..close();
    canvas.drawPath(path, shipPaint);

    // Asteroid blips
    final astPaint = Paint()..style = PaintingStyle.fill;
    for (final a in asteroids) {
      if (!a.alive) continue;
      final dx = a.position.x - shipPos.x;
      final dz = a.position.z - shipPos.z;

      final dist = math.sqrt(dx * dx + dz * dz);
      if (dist > maxDist) continue;

      final nx = (dx / maxDist) * (r * 0.85);
      final nz = (dz / maxDist) * (r * 0.85);

      astPaint.color = a.radius > 3.0 ? Colors.redAccent : Colors.orangeAccent;
      canvas.drawCircle(Offset(center.dx + nx, center.dy + nz), a.radius > 3.0 ? 2.5 : 1.5, astPaint);
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) => true;
}
