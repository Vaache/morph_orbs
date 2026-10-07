import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../controllers/morph_orb_controller.dart';
import '../models/orb_frame.dart';

/// Paints the controller's current frame: far → near, one reused [Paint].
/// Depth is carried by radius and ink alone; no blur, no layers.
class MorphOrbPainter extends CustomPainter {
  MorphOrbPainter({required this.controller}) : super(repaint: controller);

  final MorphOrbController controller;

  final Paint _paint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.fill;
  final Paint _linePaint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    final side = math.min(size.width, size.height);
    final frame = controller.render(side);
    final ink = controller.inkColor();
    final background = controller.style.backgroundColor;
    final dx = (size.width - side) / 2;
    final dy = (size.height - side) / 2;
    final order = frame.order;
    final data = frame.data;
    const stride = OrbFrame.stride;

    final lines = frame.lines;
    for (var i = 0; i < frame.lineCount; i++) {
      final b = i * OrbFrame.lineStride;
      _linePaint
        ..color = _inkFor(ink, background, lines[b + 4], lines[b + 5])
        ..strokeWidth = lines[b + 6];
      canvas.drawLine(
        Offset(lines[b] + dx, lines[b + 1] + dy),
        Offset(lines[b + 2] + dx, lines[b + 3] + dy),
        _linePaint,
      );
    }

    for (var k = 0; k < order.length; k++) {
      final base = order[k] * stride;
      _paint.color = _inkFor(ink, background, data[base + 4], data[base + 5]);
      canvas.drawCircle(
        Offset(data[base] + dx, data[base + 1] + dy),
        data[base + 3],
        _paint,
      );
    }
  }

  static Color _inkFor(
    Color ink,
    Color? background,
    double rawWhite,
    double rawAlpha,
  ) {
    final white = rawWhite.clamp(0.0, 1.0);
    final alpha = rawAlpha.clamp(0.0, 1.0);
    if (background == null) {
      return ink.withValues(alpha: ink.a * alpha * (1 - white));
    }
    final mixed = Color.lerp(ink, background, white) ?? ink;
    return mixed.withValues(alpha: mixed.a * alpha);
  }

  @override
  bool shouldRepaint(MorphOrbPainter oldDelegate) =>
      oldDelegate.controller != controller;
}
