import 'dart:math' as math;

import '../../models/orb_frame.dart';
import '../../utils/orb_math.dart';
import '../orb_geometry.dart';
import '../orb_profile.dart';

/// A soft cloud: dots displaced by slow noise drift through a sphere,
/// each breathing in size and brightness on its own tempo.
class NebulaGeometry extends OrbGeometry {
  const NebulaGeometry();

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
    final pt = Projector(t * 0.08, 0.35, cx, cy, 1);
    final rs = radiusScale(size, o.rsPow);
    final n = math.max(6, o.fieldN);
    final dir = Vec3();
    final drift = 0.6 * intensity;

    for (var i = 0; i < n; i++) {
      final id = i.toDouble();
      fibDir(i, n, dir);
      final shell = 0.25 + 0.75 * hashD(id, 9.3);
      final x = dir.x * shell + drift * (vnoise(id * 0.41 + 5, t * 0.17) - 0.5);
      final y =
          dir.y * shell + drift * (vnoise(id * 0.67 + 23, t * 0.15) - 0.5);
      final z =
          dir.z * shell + drift * (vnoise(id * 0.91 + 61, t * 0.19) - 0.5);
      final l = math.sqrt(x * x + y * y + z * z);
      final clamped = l > 1 ? 1 / l : 1.0;
      pt.project(
        x * clamped * radius,
        y * clamped * radius,
        z * clamped * radius,
      );
      final depth = (pt.pz / radius + 1) / 2;
      final breath = vnoise(id * 2.1 + 100, t * 0.45);
      out.add(
        pt.px,
        pt.py,
        pt.pz,
        (o.rBase + o.rDepth * depth) * (0.6 + 0.8 * breath) * rs,
        0.7 - 0.5 * depth - 0.15 * breath,
        (0.2 + 0.6 * breath) * (0.5 + 0.5 * depth),
      );
    }
    out.clampRadius(o.rMin);
  }
}
