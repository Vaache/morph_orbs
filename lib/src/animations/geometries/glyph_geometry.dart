import 'dart:math' as math;

import '../../models/orb_frame.dart';
import '../../utils/orb_math.dart';
import '../orb_geometry.dart';
import '../orb_profile.dart';

/// A dotted outline laid evenly along one or more polylines, in unit space
/// (the orb is the square −0.5..0.5). The dots arrive through the
/// controller's morph; the glyph itself only plays a short settle.
class GlyphGeometry extends OrbGeometry {
  const GlyphGeometry._({
    required this.strokes,
    required this.settleDuration,
    required this.pulse,
    required this.shake,
    required this.scatter,
  });

  /// Dots gather into a check and bloom once.
  const GlyphGeometry.check()
    : this._(
        strokes: const [
          [(-0.25, 0.01), (-0.08, 0.18), (0.27, -0.17)],
        ],
        settleDuration: 0.7,
        pulse: 0.07,
        shake: 0,
        scatter: 0,
      );

  /// Dots lose cohesion with a decaying shudder, then snap onto a cross.
  const GlyphGeometry.cross()
    : this._(
        strokes: const [
          [(-0.19, -0.19), (0.19, 0.19)],
          [(0.19, -0.19), (-0.19, 0.19)],
        ],
        settleDuration: 1.1,
        pulse: 0,
        shake: 0.035,
        scatter: 0.09,
      );

  final List<List<(double, double)>> strokes;
  final double settleDuration;
  final double pulse;
  final double shake;
  final double scatter;

  @override
  bool isAnimatingAt(double t) => t < settleDuration;

  @override
  void build(
    OrbFrame out,
    double size,
    double t,
    OrbProfile o,
    double intensity,
  ) {
    out.clear();
    final local = math.max(0.0, t);
    final settled = clamp01(local / settleDuration);

    var total = 0.0;
    for (final stroke in strokes) {
      for (var i = 0; i + 1 < stroke.length; i++) {
        total += _segmentLength(stroke[i], stroke[i + 1]);
      }
    }
    final n = math.max(6, o.glyphDots);
    final dotR = math.max(o.rMin, o.rDot * size);
    final bloom = pulse * intensity * math.sin(math.pi * settled);
    final scale = 1 + bloom;
    final shakeX =
        shake *
        intensity *
        size *
        math.sin(local * 48) *
        math.exp(-local * 5) *
        (settled < 1 ? 1 : 0);
    final scatterAmp = scatter * intensity * size * math.exp(-local * 4.5);
    final ink = 0.1 + 0.25 * math.exp(-local * 3);
    final cx = size / 2;
    final cy = size / 2;

    var strokeIndex = 0;
    var segIndex = 0;
    var acc = 0.0;
    var segLen = _currentSegment(strokeIndex, segIndex);
    for (var k = 0; k < n; k++) {
      final target = (k + 0.5) / n * total;
      while (acc + segLen < target) {
        acc += segLen;
        segIndex++;
        if (segIndex + 1 >= strokes[strokeIndex].length) {
          if (strokeIndex + 1 >= strokes.length) {
            segIndex--;
            acc -= segLen;
            break;
          }
          strokeIndex++;
          segIndex = 0;
        }
        segLen = _currentSegment(strokeIndex, segIndex);
      }
      final stroke = strokes[strokeIndex];
      final a = stroke[segIndex];
      final b = stroke[math.min(stroke.length - 1, segIndex + 1)];
      final f = segLen == 0 ? 0.0 : clamp01((target - acc) / segLen);
      final kd = k.toDouble();
      final jitterAngle = hashD(kd, 11.3) * kTau;
      final jitterMag = scatterAmp * (0.4 + 0.6 * hashD(kd, 17.9));
      final x =
          cx +
          (a.$1 + (b.$1 - a.$1) * f) * size * scale +
          shakeX +
          math.cos(jitterAngle) * jitterMag;
      final y =
          cy +
          (a.$2 + (b.$2 - a.$2) * f) * size * scale +
          math.sin(jitterAngle) * jitterMag;
      out.add(x, y, 0, dotR * (1 + bloom * 1.5), ink);
    }
  }

  double _currentSegment(int strokeIndex, int segIndex) {
    final stroke = strokes[strokeIndex];
    if (segIndex + 1 >= stroke.length) {
      return 0;
    }
    return _segmentLength(stroke[segIndex], stroke[segIndex + 1]);
  }

  static double _segmentLength((double, double) a, (double, double) b) {
    final dx = b.$1 - a.$1;
    final dy = b.$2 - a.$2;
    return math.sqrt(dx * dx + dy * dy);
  }
}
