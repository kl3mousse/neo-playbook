import 'package:flutter/material.dart';

import '../../domain/expression.dart';

/// A compact, vector-drawn symbol for a complete joystick motion.
///
/// These glyphs intentionally communicate the movement path rather than its
/// numpad or letter shorthand, so one token can represent a full QCF, DP, or
/// other recognised fighting-game input.
class MotionGlyph extends StatelessWidget {
  final MotionShape shape;
  final double size;
  final Color color;

  const MotionGlyph({
    super.key,
    required this.shape,
    required this.color,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(
      painter: _MotionGlyphPainter(shape: shape, color: color),
    ),
  );
}

class _MotionGlyphPainter extends CustomPainter {
  final MotionShape shape;
  final Color color;

  const _MotionGlyphPainter({required this.shape, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 48;
    canvas.save();
    canvas.scale(scale);
    _drawStroke(canvas, _pathFor(shape));
    canvas.restore();
  }

  void _drawStroke(Canvas canvas, Path path) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, stroke);

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final start = metrics.first.getTangentForOffset(0);
    if (start != null) {
      canvas.drawCircle(start.position, 2.6, Paint()..color = color);
    }

    final endMetric = metrics.last;
    final end = endMetric.getTangentForOffset(endMetric.length);
    if (end == null) return;
    final length = end.vector.distance;
    if (length == 0) return;

    final direction = Offset(end.vector.dx / length, end.vector.dy / length);
    final normal = Offset(-direction.dy, direction.dx);
    final base = end.position - direction * 7;
    final arrow = Path()
      ..moveTo(end.position.dx, end.position.dy)
      ..lineTo((base + normal * 4.4).dx, (base + normal * 4.4).dy)
      ..moveTo(end.position.dx, end.position.dy)
      ..lineTo((base - normal * 4.4).dx, (base - normal * 4.4).dy);
    canvas.drawPath(arrow, stroke);
  }

  Path _pathFor(MotionShape shape) {
    final path = Path();
    switch (shape) {
      case MotionShape.quarterCircleForward:
        path
          ..moveTo(7, 40)
          ..cubicTo(7, 23, 18, 12, 41, 12);
      case MotionShape.quarterCircleBack:
        path
          ..moveTo(41, 40)
          ..cubicTo(41, 23, 30, 12, 7, 12);
      case MotionShape.halfCircleForward:
        path
          ..moveTo(7, 11)
          ..cubicTo(7, 43, 41, 43, 41, 11);
      case MotionShape.halfCircleBack:
        path
          ..moveTo(41, 11)
          ..cubicTo(41, 43, 7, 43, 7, 11);
      case MotionShape.dragonPunchForward:
        path
          ..moveTo(7, 39)
          ..lineTo(7, 17)
          ..lineTo(22, 30)
          ..lineTo(41, 9);
      case MotionShape.dragonPunchBack:
        path
          ..moveTo(41, 39)
          ..lineTo(41, 17)
          ..lineTo(26, 30)
          ..lineTo(7, 9);
      case MotionShape.reverseDragonPunchForward:
        path
          ..moveTo(7, 10)
          ..lineTo(23, 29)
          ..lineTo(41, 29);
      case MotionShape.reverseDragonPunchBack:
        path
          ..moveTo(41, 10)
          ..lineTo(25, 29)
          ..lineTo(7, 29);
      case MotionShape.fullCircle:
        path
          ..moveTo(12, 16)
          ..cubicTo(18, 6, 34, 7, 40, 18)
          ..cubicTo(45, 31, 35, 42, 22, 41)
          ..cubicTo(10, 40, 5, 27, 12, 16);
      case MotionShape.doubleQuarterCircleForward:
        path
          ..moveTo(4, 40)
          ..cubicTo(4, 27, 10, 20, 20, 20)
          ..moveTo(23, 40)
          ..cubicTo(23, 27, 31, 20, 44, 20);
      case MotionShape.doubleQuarterCircleBack:
        path
          ..moveTo(44, 40)
          ..cubicTo(44, 27, 38, 20, 28, 20)
          ..moveTo(25, 40)
          ..cubicTo(25, 27, 17, 20, 4, 20);
      case MotionShape.pretzelForward:
        path
          ..moveTo(7, 33)
          ..cubicTo(7, 42, 21, 42, 21, 32)
          ..cubicTo(21, 22, 7, 22, 7, 13)
          ..cubicTo(7, 5, 22, 5, 25, 13)
          ..cubicTo(28, 21, 40, 20, 41, 10);
      case MotionShape.pretzelBack:
        path
          ..moveTo(41, 33)
          ..cubicTo(41, 42, 27, 42, 27, 32)
          ..cubicTo(27, 22, 41, 22, 41, 13)
          ..cubicTo(41, 5, 26, 5, 23, 13)
          ..cubicTo(20, 21, 8, 20, 7, 10);
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _MotionGlyphPainter oldDelegate) =>
      shape != oldDelegate.shape || color != oldDelegate.color;
}
