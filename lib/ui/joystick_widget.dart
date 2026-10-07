import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:vector_math/vector_math.dart' as vm;

/// Virtual on-screen joystick.
///
/// Exposes a [ValueNotifier<vm.Vector2>] with values in -1..1 for X and Y.
/// Y convention: pushing up → positive Y (up = forward for the ship).
class JoystickWidget extends StatefulWidget {
  final ValueNotifier<vm.Vector2> direction;
  final double size;

  const JoystickWidget({super.key, required this.direction, this.size = 130.0});

  @override
  State<JoystickWidget> createState() => _JoystickWidgetState();
}

class _JoystickWidgetState extends State<JoystickWidget> {
  Offset _thumbOffset = Offset.zero;
  bool _active = false;

  void _updateThumb(Offset localPos) {
    final center = Offset(widget.size / 2, widget.size / 2);
    var delta = localPos - center;
    final maxDist = widget.size * 0.35;
    if (delta.distance > maxDist) {
      delta = delta / delta.distance * maxDist;
    }
    setState(() {
      _thumbOffset = delta;
      _active = true;
    });
    // Y is inverted: screen-down is positive delta.dy,
    // but we want screen-up = positive Y (forward thrust).
    widget.direction.value = vm.Vector2(
      delta.dx / maxDist,
      -(delta.dy / maxDist), // invert Y so up = forward
    );
  }

  void _reset() {
    setState(() {
      _thumbOffset = Offset.zero;
      _active = false;
    });
    widget.direction.value = vm.Vector2.zero();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (d) => _updateThumb(d.localPosition),
      onPanUpdate: (d) => _updateThumb(d.localPosition),
      onPanEnd: (_) => _reset(),
      onPanCancel: () => _reset(),
      child: SizedBox(
        width: s,
        height: s,
        child: CustomPaint(
          painter: _JoystickPainter(thumbOffset: _thumbOffset, active: _active),
        ),
      ),
    );
  }
}

class _JoystickPainter extends CustomPainter {
  final Offset thumbOffset;
  final bool active;

  _JoystickPainter({required this.thumbOffset, required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2.0, size.height / 2.0);
    final baseRadius = size.width * 0.48;
    final thumbRadius = size.width * 0.22;

    // Outer ring fill
    canvas.drawCircle(
      center,
      baseRadius,
      Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.12)
        ..style = PaintingStyle.fill,
    );
    // Outer ring stroke
    canvas.drawCircle(
      center,
      baseRadius,
      Paint()
        ..color = Colors.cyanAccent.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Thumb
    canvas.drawCircle(
      center + thumbOffset,
      thumbRadius,
      Paint()
        ..color = Colors.cyanAccent.withValues(alpha: active ? 0.80 : 0.45)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_JoystickPainter old) =>
      old.thumbOffset != thumbOffset || old.active != active;
}
