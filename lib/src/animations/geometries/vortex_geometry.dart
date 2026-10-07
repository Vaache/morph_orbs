import 'dart:math' as math;

import '../../models/orb_frame.dart';
import '../../utils/orb_math.dart';
import '../orb_geometry.dart';
import '../orb_profile.dart';

/// Dots are born at the rim, spiral inward faster and faster, sink into
/// the funnel and vanish at the centre — summarising, compressing.
class VortexGeometry extends OrbGeometry {
  const VortexGeometry();

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
    final radius = (size / 2) * 0.84;
    final pt = Projector(0, 1.25, cx, cy, 1);
    final rs = radiusScale(size, o.rsPow);
    final n = math.max(6, o.fieldN);
    final arms = math.max(1, o.featureN);
    final twist = o.turns * intensity;

    for (var i = 0; i < n; i++) {
      final id = i.toDouble();
      final phase = frac(t * 0.16 + hashD(id, 2.2));
      final r = radius * math.pow(1 - phase, 0.75).toDouble();
      final arm = i % arms;
      final a =
          arm * kTau / arms +
          0.12 * (hashD(id, 5.5) - 0.5) +
          phase * phase * kTau * twist +
          t * 0.1;
      final sink = (phase - 0.3) * radius * 0.5;
      pt.project(math.cos(a) * r, -sink, math.sin(a) * r);
      final depth = (pt.pz / radius + 1) / 2;
      final life = math.sin(math.pi * phase);
      out.add(
        pt.px,
        pt.py,
        pt.pz,
        (o.rBase + o.rDepth * (0.3 + 0.7 * phase)) * rs,
        0.55 - 0.45 * phase,
        life * (0.5 + 0.5 * depth),
      );
    }

    const rim = 36;
    for (var i = 0; i < rim; i++) {
      final a = (i / rim) * kTau + t * 0.05;
      pt.project(math.cos(a) * radius, -radius * 0.15, math.sin(a) * radius);
      final depth = (pt.pz / radius + 1) / 2;
      out.add(pt.px, pt.py, pt.pz, 0.7 * rs, 0.78, 0.12 + 0.2 * depth);
    }
    out.clampRadius(o.rMin);
  }
}
