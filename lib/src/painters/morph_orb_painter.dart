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
    paintOrbFrame(
      canvas,
      controller.render(side),
      ink: controller.inkColor(),
      background: controller.style.backgroundColor,
      offset: Offset((size.width - side) / 2, (size.height - side) / 2),
      dotPaint: _paint,
      linePaint: _linePaint,
    );
  }

  @override
  bool shouldRepaint(MorphOrbPainter oldDelegate) =>
      oldDelegate.controller != controller;
}

/// Draws [frame] onto [canvas]: stroked lines first, then dots far → near.
///
/// Each dot is painted in [ink], leaned toward its own tint when it has one,
/// then faded by its ink and alpha channels — toward transparent, or toward
/// [background] when that is given. [offset] shifts the whole frame; the
/// two paints are reused across calls so nothing is allocated per dot.
void paintOrbFrame(
  Canvas canvas,
  OrbFrame frame, {
  required Color ink,
  required Color? background,
  required Offset offset,
  required Paint dotPaint,
  required Paint linePaint,
}) {
  final dx = offset.dx;
  final dy = offset.dy;
  final order = frame.order;
  final data = frame.data;
  const stride = OrbFrame.stride;

  final lines = frame.lines;
  for (var i = 0; i < frame.lineCount; i++) {
    final b = i * OrbFrame.lineStride;
    linePaint
      ..color = _inkFor(ink, background, lines[b + 4], lines[b + 5])
      ..strokeWidth = lines[b + 6];
    canvas.drawLine(
      Offset(lines[b] + dx, lines[b + 1] + dy),
      Offset(lines[b + 2] + dx, lines[b + 3] + dy),
      linePaint,
    );
  }

  for (var k = 0; k < order.length; k++) {
    final base = order[k] * stride;
    final radius = data[base + 3];
    if (radius <= 0.01) {
      continue;
    }
    final tint = data[base + 9];
    final dotInk = tint <= 0
        ? ink
        : Color.lerp(
                ink,
                Color.from(
                  alpha: ink.a,
                  red: data[base + 6],
                  green: data[base + 7],
                  blue: data[base + 8],
                ),
                tint.clamp(0.0, 1.0),
              ) ??
              ink;
    dotPaint.color = _inkFor(
      dotInk,
      background,
      data[base + 4],
      data[base + 5],
    );
    canvas.drawCircle(
      Offset(data[base] + dx, data[base + 1] + dy),
      radius,
      dotPaint,
    );
  }
}

Color _inkFor(Color ink, Color? background, double rawWhite, double rawAlpha) {
  final white = rawWhite.clamp(0.0, 1.0);
  final alpha = rawAlpha.clamp(0.0, 1.0);
  if (background == null) {
    return ink.withValues(alpha: ink.a * alpha * (1 - white));
  }
  final mixed = Color.lerp(ink, background, white) ?? ink;
  return mixed.withValues(alpha: mixed.a * alpha);
}
