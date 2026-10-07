import 'dart:math' as math;

import '../../models/orb_frame.dart';
import '../../utils/orb_math.dart';
import '../orb_geometry.dart';
import '../orb_profile.dart';

/// Three strands plait around the sphere, trading places over and under —
/// weaving.
class BraidGeometry extends OrbGeometry {
  const BraidGeometry();

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
    final radius = (size / 2) * 0.76;
    final pt = Projector(t * 0.4, 0.3, cx, cy, 1);
    final rs = radiusScale(size, o.rsPow);

    final dir = Vec3();
    for (var i = 0; i < o.ghostN; i++) {
      fibDir(i, o.ghostN, dir);
      pt.project(dir.x * radius, dir.y * radius, dir.z * radius);
      final depth = (pt.pz / radius + 1) / 2;
      out.add(pt.px, pt.py, pt.pz, 0.8 * rs, 0.78, 0.1 + 0.22 * depth);
    }

    final weaveAmp = 0.075 * intensity;
    for (var s = 0; s < 3; s++) {
      final phase = (s / 3) * kTau;
      for (var i = 0; i < o.strandN; i++) {
        final u = (frac(i / o.strandN + t * 0.045) * 2 - 1) * 0.96;
        final surf = math.sqrt(math.max(0.0, 1 - u * u));
        final endFade = math.min(1.0, (1 - u.abs()) / 0.1);
        final a = u * math.pi * o.turns + phase;
        final weave =
            1 +
            weaveAmp *
                math.sin(u * math.pi * o.turns * 2 + phase * 2 + t * 0.8);
        final rr = surf * radius * weave;
        pt.project(math.cos(a) * rr, u * radius * weave, math.sin(a) * rr);
        final depth = (pt.pz / radius + 1) / 2;
        out.add(
          pt.px,
          pt.py,
          pt.pz,
          (o.rBase + o.rDepth * depth) * rs,
          0.55 - 0.45 * depth,
          endFade * (0.45 + 0.55 * depth),
        );
      }
    }
    out.clampRadius(o.rMin);
  }
}
