import 'dart:math' as math;

import '../../models/orb_frame.dart';
import '../../utils/orb_math.dart';
import '../orb_geometry.dart';
import '../orb_profile.dart';

const double _kSegment = 2.2;
const int _kMaxNodes = 96;
const int _kMaxFigure = 8;

/// Fixed stars on a slowly turning sphere; every few seconds a handful
/// join into a figure, hold it, and let it go — one reasoning step after
/// another.
class ConstellateGeometry extends OrbGeometry {
  const ConstellateGeometry();

  static final List<double> _sx = List<double>.filled(_kMaxNodes, 0);
  static final List<double> _sy = List<double>.filled(_kMaxNodes, 0);
  static final List<double> _sz = List<double>.filled(_kMaxNodes, 0);
  static final List<double> _lit = List<double>.filled(_kMaxNodes, 0);
  static final List<int> _figure = List<int>.filled(_kMaxFigure, 0);

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
    final pt = Projector(t * 0.09, 0.3, cx, cy, radius);
    final rs = radiusScale(size, o.rsPow);
    final n = math.min(_kMaxNodes, math.max(6, o.nodeN));
    final figureSize = math.min(_kMaxFigure, math.max(2, o.signals));
    final dir = Vec3();

    final seg = (t / _kSegment).floor();
    final local = (t - seg * _kSegment) / _kSegment;
    final window = math.sin(math.pi * local);
    final glow = smoothStep(window * 1.4) * intensity;

    for (var i = 0; i < n; i++) {
      fibDir(i, n, dir);
      final id = i.toDouble();
      final jx = 0.06 * (vnoise(id * 0.5 + 3, t * 0.2) - 0.5);
      final jy = 0.06 * (vnoise(id * 0.7 + 19, t * 0.18) - 0.5);
      final x = dir.x + jx;
      final y = dir.y + jy;
      final z = dir.z;
      final l = math.sqrt(x * x + y * y + z * z);
      pt.project(x / l, y / l, z / l);
      _sx[i] = pt.px;
      _sy[i] = pt.py;
      _sz[i] = pt.pz;
      _lit[i] = 0;
    }

    final segD = seg.toDouble();
    var anchor = (hashD(segD, 3.3) * n).floor();
    _figure[0] = anchor;
    _lit[anchor] = 1;
    for (var k = 1; k < figureSize; k++) {
      var best = -1;
      var bestScore = double.infinity;
      for (var j = 0; j < n; j++) {
        if (_lit[j] > 0) {
          continue;
        }
        final dx = _sx[j] - _sx[anchor];
        final dy = _sy[j] - _sy[anchor];
        final dz = (_sz[j] - _sz[anchor]) * radius;
        final score =
            math.sqrt(dx * dx + dy * dy + dz * dz) *
            (0.7 + 0.6 * hashD(segD + k, j.toDouble()));
        if (score < bestScore) {
          bestScore = score;
          best = j;
        }
      }
      if (best < 0) {
        break;
      }
      _figure[k] = best;
      _lit[best] = 1;
      anchor = best;
    }

    final lineW = math.max(0.5, o.lineW * rs);
    for (var k = 0; k + 1 < figureSize; k++) {
      final a = _figure[k];
      final b = _figure[k + 1];
      if (_lit[b] == 0) {
        break;
      }
      final reveal = clamp01(glow * figureSize - k);
      final depth = ((_sz[a] + _sz[b]) / 2 + 1) / 2;
      out.addLine(
        _sx[a],
        _sy[a],
        _sx[b],
        _sy[b],
        0.3,
        reveal * (0.25 + 0.6 * depth),
        lineW,
      );
    }

    for (var i = 0; i < n; i++) {
      final depth = (_sz[i] + 1) / 2;
      final lit = _lit[i] * glow;
      out.add(
        _sx[i],
        _sy[i],
        _sz[i],
        (o.nodeR + o.nodeRDepth * depth + o.rBoost * lit) * rs,
        0.62 - 0.4 * depth - 0.5 * lit,
        (0.4 + 0.5 * depth) * (1 - lit) + lit,
      );
    }
    out.clampRadius(o.rMin);
  }
}
