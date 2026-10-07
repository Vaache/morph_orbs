import 'dart:math' as math;

import '../../models/orb_frame.dart';
import '../../utils/orb_math.dart';
import '../orb_geometry.dart';
import '../orb_profile.dart';

/// Two strands wind around a vertical axis and rotate; rungs between them
/// flicker in sequence.
class HelixGeometry extends OrbGeometry {
  const HelixGeometry();

  @override
  void build(
    OrbFrame out,
    double size,
    double t,
    OrbProfile o,
    double intensity,
  ) {
    out.clear();
    final cx = size / 2;
    final cy = size / 2;
    final radius = (size / 2) * 0.8;
    final pt = Projector(0.25 * math.sin(t * 0.3), 0.18, cx, cy, 1);
    const shear = 0.42;
    final rs = radiusScale(size, o.rsPow);
    final n = math.max(6, o.strandN);
    final turns = o.turns;
    final coil = radius * 0.5;
    final spin = t * 1.1;
    final rungEvery = math.max(2, (n / math.max(1, o.featureN)).round());
    final lineW = math.max(0.5, o.lineW * rs);
    final breathe = 1 + 0.04 * intensity * math.sin(t * 0.8);

    for (var i = 0; i < n; i++) {
      final u = (i / (n - 1)) * 2 - 1;
      final y = u * radius * 0.92;
      final a = u * math.pi * turns + spin;
      final endFade = math.min(1.0, (1.02 - u.abs()) / 0.18);
      double x1 = 0;
      double y1 = 0;
      double z1 = 0;
      for (var s = 0; s < 2; s++) {
        final aa = a + s * math.pi;
        pt.project(
          math.cos(aa) * coil * breathe + y * shear,
          y,
          math.sin(aa) * coil * breathe,
        );
        final depth = (pt.pz / coil + 1) / 2;
        out.add(
          pt.px,
          pt.py,
          pt.pz,
          (o.rBase + o.rDepth * depth) * rs,
          0.55 - 0.45 * depth,
          endFade * (0.45 + 0.55 * depth),
        );
        if (s == 0) {
          x1 = pt.px;
          y1 = pt.py;
          z1 = pt.pz;
        } else if (i % rungEvery == 0) {
          final glow = 0.5 + 0.5 * math.sin(t * 2.4 - i * 0.9);
          final depth = ((z1 + pt.pz) / 2 / coil + 1) / 2;
          out.addLine(
            x1,
            y1,
            pt.px,
            pt.py,
            0.35,
            endFade * (0.12 + 0.5 * glow) * (0.4 + 0.6 * depth),
            lineW,
          );
        }
      }
    }
    out.clampRadius(o.rMin);
  }
}
