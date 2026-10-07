import 'dart:math' as math;

import '../../models/orb_frame.dart';
import '../../utils/orb_math.dart';
import '../orb_geometry.dart';
import '../orb_profile.dart';

const double _kPeriod = 1.9;

/// A dim dotted sphere; a sonar ring sweeps out from the centre and each
/// dot it passes lights up and dims again — waiting for a reply.
class EchoGeometry extends OrbGeometry {
  const EchoGeometry();

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
    final radius = (size / 2) * 0.82;
    final pt = Projector(t * 0.1, 0.35, cx, cy, radius);
    final rs = radiusScale(size, o.rsPow);
    final n = math.max(8, o.fieldN);
    final dir = Vec3();

    final phase = frac(t / _kPeriod);
    final eased = 1 - math.pow(1 - phase, 2).toDouble();
    final ringR = radius * (0.05 + 0.98 * eased);
    final ringFade = math.pow(1 - phase, 1.4).toDouble();
    final width = radius * 0.11;

    for (var i = 0; i < n; i++) {
      fibDir(i, n, dir);
      pt.project(dir.x, dir.y, dir.z);
      final depth = (pt.pz + 1) / 2;
      final dx = pt.px - cx;
      final dy = pt.py - cy;
      final dist = math.sqrt(dx * dx + dy * dy);
      final d = (dist - ringR) / width;
      final hit = math.exp(-d * d) * ringFade * intensity;
      out.add(
        pt.px,
        pt.py,
        pt.pz,
        (o.rBase + o.rDepth * depth + o.rBoost * hit) * rs,
        0.72 - 0.3 * depth - 0.45 * hit,
        o.dimBase + (1 - o.dimBase) * math.min(1.0, hit * 1.5),
      );
    }

    final ringDots = math.max(12, o.featureN);
    for (var i = 0; i < ringDots; i++) {
      final a = (i / ringDots) * kTau;
      out.add(
        cx + math.cos(a) * ringR,
        cy + math.sin(a) * ringR * 0.94,
        1.5,
        0.75 * rs,
        0.2,
        ringFade * 0.8,
      );
    }
    out.clampRadius(o.rMin);
  }
}
