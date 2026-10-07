import 'dart:math' as math;

import '../../models/orb_frame.dart';
import '../../utils/orb_math.dart';
import '../orb_geometry.dart';
import '../orb_profile.dart';

/// Particles on tilted orbits with faint ghost paths — the thinking state.
/// The whole system breathes gently so the orb never reads as a rigid gyro.
class OrbitsGeometry extends OrbGeometry {
  const OrbitsGeometry();

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
    final breathe = 1 + 0.025 * intensity * math.sin(t * 0.45);
    final radius = (size / 2) * 0.82 * breathe;
    final pt = Projector(t * 0.12, 0.3 + 0.05 * math.sin(t * 0.21), cx, cy, 1);
    final rs = radiusScale(size, o.rsPow);
    final ghostPulse = 0.85 + 0.15 * math.sin(t * 0.7);

    for (var orb = 0; orb < o.orbitN; orb++) {
      final od = orb.toDouble();
      final h1 = hashD(od, 1.7);
      final h2 = hashD(od, 5.2);
      final h3 = hashD(od, 8.9);
      final ro = radius * (0.45 + 0.52 * h1);
      final th = h1 * kTau;
      final phi = math.acos(2 * h2 - 1);
      final nx = math.sin(phi) * math.cos(th);
      final ny = math.cos(phi);
      final nz = math.sin(phi) * math.sin(th);
      var ux = -ny;
      var uy = nx;
      const uz = 0.0;
      final ul = math.max(1e-6, math.sqrt(ux * ux + uy * uy));
      ux /= ul;
      uy /= ul;
      final vx = ny * uz - nz * uy;
      final vy = nz * ux - nx * uz;
      final vz = nx * uy - ny * ux;
      final speed = (0.25 + 0.55 * h3) * (h3 > 0.5 ? 1 : -1);

      for (var k = 0; k < o.ghostN; k++) {
        final a = (k / o.ghostN) * kTau;
        final ca = math.cos(a);
        final sa = math.sin(a);
        pt.project(
          (ux * ca + vx * sa) * ro,
          (uy * ca + vy * sa) * ro,
          (uz * ca + vz * sa) * ro,
        );
        final depth = (pt.pz / ro + 1) / 2;
        out.add(
          pt.px,
          pt.py,
          pt.pz,
          o.ghostR * rs,
          0.6,
          o.ghostA * ghostPulse * (0.4 + 0.6 * depth),
        );
      }
      for (var m = 0; m < o.particles; m++) {
        final a = t * speed + (m / o.particles) * kTau + h2 * 6;
        final ca = math.cos(a);
        final sa = math.sin(a);
        pt.project(
          (ux * ca + vx * sa) * ro,
          (uy * ca + vy * sa) * ro,
          (uz * ca + vz * sa) * ro,
        );
        final depth = (pt.pz / ro + 1) / 2;
        out.add(
          pt.px,
          pt.py,
          pt.pz,
          (o.partR + o.partRDepth * depth) * rs,
          0.3 - 0.22 * depth,
        );
      }
    }
    out.clampRadius(o.rMin);
  }
}
