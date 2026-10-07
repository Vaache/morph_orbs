import 'dart:math' as math;

import '../../models/orb_frame.dart';
import '../../utils/orb_math.dart';
import '../orb_geometry.dart';
import '../orb_profile.dart';

const double _kCamTilt = 0.3;

/// An undulating sash of parallel strands on a great circle — generating.
/// With [OrbProfile.faceOn] the same painter draws a face-on ring whose
/// radius, not its out-of-plane offset, undulates — idle and stopped.
class RibbonGeometry extends OrbGeometry {
  const RibbonGeometry();

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
    final radius = (size / 2) * 0.78;
    final spin = o.spin;
    final pt = Projector(t * 0.1 * spin, _kCamTilt, cx, cy, 1);
    final rs = radiusScale(size, o.rsPow);
    final wobMul = o.wobMul * intensity;

    final dir = Vec3();
    for (var i = 0; i < o.ghostN; i++) {
      fibDir(i, o.ghostN, dir);
      pt.project(dir.x * radius, dir.y * radius, dir.z * radius);
      final depth = (pt.pz / radius + 1) / 2;
      out.add(pt.px, pt.py, pt.pz, 0.8 * rs, 0.78, 0.1 + 0.22 * depth);
    }

    final ya = t * 0.24 * spin;
    final ta = o.faceOn ? -_kCamTilt : 0.55 + 0.3 * math.sin(t * 0.18) * spin;
    final ux = math.cos(ya);
    const uy = 0.0;
    final uz = math.sin(ya);
    final vx = -uz * math.sin(ta);
    final vy = math.cos(ta);
    final vz = ux * math.sin(ta);
    final nx = uy * vz - uz * vy;
    final ny = uz * vx - ux * vz;
    final nz = ux * vy - uy * vx;

    final wobAmp = 0.23 * wobMul;
    final baseR = o.faceOn ? radius / (1 + 0.85 * wobAmp) : radius;

    final lanes = math.max(1, (o.lanes * o.bandMul).round());
    final half = (lanes - 1) / 2;
    for (var w = 0; w < lanes; w++) {
      final laneOff = (w - half) * 0.075;
      final edge = half == 0 ? 0.0 : (w - half).abs() / half;
      for (var k = 0; k < o.segs; k++) {
        final a = (k / o.segs) * kTau;
        final wob =
            (0.16 * math.sin(a * 3 - t * 1.7 + w * 0.22) +
                0.07 * math.sin(a * 5 + t * 1.1)) *
            wobMul;
        final radial = o.faceOn ? 1 + wob : 1.0;
        final off = o.faceOn ? laneOff : laneOff + wob;
        final ca = math.cos(a);
        final sa = math.sin(a);
        final x = ux * ca + vx * sa + nx * off;
        final y = uy * ca + vy * sa + ny * off;
        final z = uz * ca + vz * sa + nz * off;
        final l = math.sqrt(x * x + y * y + z * z);
        final rr = baseR * radial / l;
        pt.project(x * rr, y * rr, z * rr);
        final depth = (pt.pz / radius + 1) / 2;
        out.add(
          pt.px,
          pt.py,
          pt.pz,
          (o.rBase + o.rDepth * depth) * (1 - 0.25 * edge) * rs,
          0.52 - 0.44 * depth + 0.18 * edge,
          0.4 + 0.6 * depth,
        );
      }
    }
    out.clampRadius(o.rMin);
  }
}
