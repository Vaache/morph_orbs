import 'dart:math' as math;

import '../../models/orb_frame.dart';
import '../../utils/orb_math.dart';
import '../orb_geometry.dart';
import '../orb_profile.dart';

/// A flock skims the surface of an invisible sphere: every dot drifts on
/// its own noise, lags the shared turn by a little, and the whole swarm
/// leans into the direction it is heading.
class SwarmGeometry extends OrbGeometry {
  const SwarmGeometry();

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
    final rs = radiusScale(size, o.rsPow);
    final n = math.max(4, o.fieldN);
    final dir = Vec3();

    final heading = t * 0.35 + 0.6 * math.sin(t * 0.23);
    final lean = 0.35 * math.sin(t * 0.41);
    final pt = Projector(heading, 0.3 + lean, cx, cy, 1);
    final wander = 0.55 * intensity;

    for (var i = 0; i < n; i++) {
      final id = i.toDouble();
      fibDir(i, n, dir);
      final lag = 0.25 * hashD(id, 4.1);
      final tt = t - lag;
      final x = dir.x + wander * (vnoise(id * 0.37 + 3, tt * 0.33) - 0.5);
      final y = dir.y + wander * (vnoise(id * 0.59 + 17, tt * 0.29) - 0.5);
      final z = dir.z + wander * (vnoise(id * 0.83 + 41, tt * 0.37) - 0.5);
      final l = math.max(1e-6, math.sqrt(x * x + y * y + z * z));
      final shell = 0.82 + 0.18 * vnoise(id * 1.3, tt * 0.5);
      final rr = radius * shell;
      pt.project(x / l * rr, y / l * rr, z / l * rr);
      final depth = (pt.pz / radius + 1) / 2;
      final flicker = 0.75 + 0.25 * math.sin(tt * 2.3 + id * 1.7);
      out.add(
        pt.px,
        pt.py,
        pt.pz,
        (o.rBase + o.rDepth * depth) * flicker * rs,
        0.6 - 0.5 * depth,
        0.35 + 0.65 * depth,
      );
    }
    out.clampRadius(o.rMin);
  }
}
