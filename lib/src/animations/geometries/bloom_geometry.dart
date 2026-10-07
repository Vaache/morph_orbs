import 'dart:math' as math;

import '../../models/orb_frame.dart';
import '../../utils/orb_math.dart';
import '../orb_geometry.dart';
import '../orb_profile.dart';

/// A dotted rose curve opens and closes its petals while turning slowly,
/// each petal lifted a little out of the plane — creative work.
class BloomGeometry extends OrbGeometry {
  const BloomGeometry();

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
    final radius = (size / 2) * 0.86;
    final pt = Projector(t * 0.12, 1.25, cx, cy, 1);
    final rs = radiusScale(size, o.rsPow);
    final petals = math.max(3, o.featureN);
    final n = math.max(12, o.fieldN);
    final k = petals / 2;

    final open = 0.45 + 0.55 * smoothStep(0.5 + 0.5 * math.sin(t * 0.55));
    final lift = 0.22 * intensity;

    for (var i = 0; i < n; i++) {
      final theta = (i / n) * kTau * 2;
      final rose = math.cos(k * theta).abs();
      final r = radius * open * (0.15 + 0.85 * rose);
      final z = radius * lift * math.sin(k * theta) * open;
      pt.project(math.cos(theta) * r, z, math.sin(theta) * r);
      final depth = (pt.pz / radius + 1) / 2;
      final tip = rose * rose;
      out.add(
        pt.px,
        pt.py,
        pt.pz,
        (o.rBase + o.rDepth * depth) * (0.7 + 0.5 * tip) * rs,
        0.45 - 0.3 * depth - 0.15 * tip,
        0.6 + 0.4 * depth,
      );
    }

    final core = math.max(1, o.particles);
    for (var i = 0; i < core; i++) {
      final a = (i / core) * kTau + t * 0.4;
      final rr = radius * 0.08 * (1.4 - open);
      pt.project(math.cos(a) * rr, 0, math.sin(a) * rr);
      out.add(pt.px, pt.py, pt.pz + 0.01, (o.partR + o.partRDepth) * rs, 0.08);
    }
    out.clampRadius(o.rMin);
  }
}
