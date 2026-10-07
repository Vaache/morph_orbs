import 'dart:math' as math;

import '../../models/orb_frame.dart';
import '../../utils/orb_math.dart';
import '../orb_geometry.dart';
import '../orb_profile.dart';

const int _kMaxNodes = 96;

/// A constellation wiring itself: nodes drift on the sphere, close pairs
/// grow an edge, bright packets run between nodes — connecting.
class WebGeometry extends OrbGeometry {
  const WebGeometry();

  static final List<double> _nx = List<double>.filled(_kMaxNodes, 0);
  static final List<double> _ny = List<double>.filled(_kMaxNodes, 0);
  static final List<double> _nz = List<double>.filled(_kMaxNodes, 0);

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
    final radius = (size / 2) * 0.8 * o.spread;
    final pt = Projector(t * 0.12, 0.32, cx, cy, radius);
    final rs = radiusScale(size, o.rsPow);
    final n = math.min(_kMaxNodes, o.nodeN);
    final wander = 0.3 * intensity;

    final dir = Vec3();
    for (var i = 0; i < n; i++) {
      fibDir(i, n, dir);
      final x = dir.x + wander * (vnoise(i * 0.31 + 9, t * 0.24) - 0.5) * 2;
      final y = dir.y + wander * (vnoise(i * 0.53 + 27, t * 0.21) - 0.5) * 2;
      final z = dir.z + wander * (vnoise(i * 0.77 + 55, t * 0.27) - 0.5) * 2;
      final l = math.sqrt(x * x + y * y + z * z);
      _nx[i] = x / l;
      _ny[i] = y / l;
      _nz[i] = z / l;
    }

    final lineW = math.max(0.6, o.lineW * rs);
    for (var i = 0; i < n; i++) {
      for (var j = i + 1; j < n; j++) {
        final dx = _nx[i] - _nx[j];
        final dy = _ny[i] - _ny[j];
        final dz = _nz[i] - _nz[j];
        final dist = math.sqrt(dx * dx + dy * dy + dz * dz);
        if (dist >= o.thr) {
          continue;
        }
        pt.project(_nx[i], _ny[i], _nz[i]);
        final x1 = pt.px;
        final y1 = pt.py;
        final z1 = pt.pz;
        pt.project(_nx[j], _ny[j], _nz[j]);
        final depth = ((z1 + pt.pz) / 2 + 1) / 2;
        out.addLine(
          x1,
          y1,
          pt.px,
          pt.py,
          0.42,
          (1 - dist / o.thr) * (0.3 + 0.55 * depth),
          lineW,
        );
      }
    }

    for (var i = 0; i < n; i++) {
      pt.project(_nx[i], _ny[i], _nz[i]);
      final depth = (pt.pz + 1) / 2;
      final pulse = 1 + 0.25 * math.sin(t * 1.4 + i * 2.7);
      out.add(
        pt.px,
        pt.py,
        pt.pz,
        (o.nodeR + o.nodeRDepth * depth) * pulse * rs,
        0.55 - 0.45 * depth,
      );
    }

    for (var s = 0; s < o.signals; s++) {
      final seg = (t * 0.55 + s * 7.31).floorToDouble();
      final a = (hashD(seg, s * 3.1 + 1.7) * n).floor();
      final b = (hashD(seg, s * 5.7 + 4.2) * n).floor();
      if (a == b) {
        continue;
      }
      final f = frac(t * 0.55 + s * 7.31);
      final x = lerp(_nx[a], _nx[b], f);
      final y = lerp(_ny[a], _ny[b], f);
      final z = lerp(_nz[a], _nz[b], f);
      final l = math.max(1e-6, math.sqrt(x * x + y * y + z * z));
      pt.project(x / l, y / l, z / l);
      final depth = (pt.pz + 1) / 2;
      out.add(
        pt.px,
        pt.py,
        pt.pz,
        (o.nodeR * 1.5 + o.nodeRDepth * depth) * rs,
        0.05,
        0.5 + 0.5 * depth,
      );
    }
    out.clampRadius(o.rMin);
  }
}
