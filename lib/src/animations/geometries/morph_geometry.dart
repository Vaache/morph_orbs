import 'dart:math' as math;

import '../../models/orb_frame.dart';
import '../../utils/orb_math.dart';
import '../orb_geometry.dart';
import '../orb_profile.dart';

const double _kHold = 1.4;
const double _kMorph = 0.9;
const double _kSegment = _kHold + _kMorph;
const int _kSamples = 160;

typedef _Path = (double, double) Function(double f);

_Path _polyPath(List<(double, double)> verts) {
  final count = verts.length;
  final lengths = <double>[];
  var total = 0.0;
  for (var i = 0; i < count; i++) {
    final a = verts[i];
    final b = verts[(i + 1) % count];
    final l = math.sqrt(
      (b.$1 - a.$1) * (b.$1 - a.$1) + (b.$2 - a.$2) * (b.$2 - a.$2),
    );
    lengths.add(l);
    total += l;
  }
  return (f) {
    var target = f * total;
    var i = 0;
    while (target > lengths[i] && i < count - 1) {
      target -= lengths[i];
      i++;
    }
    final a = verts[i];
    final b = verts[(i + 1) % count];
    final ff = lengths[i] == 0 ? 0.0 : math.min(1.0, target / lengths[i]);
    return (a.$1 + (b.$1 - a.$1) * ff, a.$2 + (b.$2 - a.$2) * ff);
  };
}

(double, double) _circle(double f) {
  final a = -math.pi / 2 + f * kTau;
  return (math.cos(a) * 0.24, math.sin(a) * 0.24);
}

final _Path _triangle = _polyPath(const [
  (0.0, -0.26),
  (0.24, 0.16),
  (-0.24, 0.16),
]);
final _Path _square = _polyPath(const [
  (0.0, -0.2),
  (0.2, -0.2),
  (0.2, 0.2),
  (-0.2, 0.2),
  (-0.2, -0.2),
]);
final List<_Path> _cycle = [_circle, _triangle, _square];

/// A dotted outline cycling circle → triangle → square, dots laid evenly
/// along the blended outline — shaping.
class MorphGeometry extends OrbGeometry {
  const MorphGeometry();

  static final List<double> _px = List<double>.filled(_kSamples, 0);
  static final List<double> _py = List<double>.filled(_kSamples, 0);
  static final List<double> _len = List<double>.filled(_kSamples, 0);

  @override
  void build(
    OrbFrame out,
    double size,
    double t,
    OrbProfile o,
    double intensity,
  ) {
    out.clear();
    final k = _cycle.length;
    final tc = t % (_kSegment * k);
    final shape = (tc / _kSegment).floor();
    final local = tc - shape * _kSegment;
    final m = local > _kHold ? smoothStep((local - _kHold) / _kMorph) : 0.0;
    final spread = o.spread;

    final pathA = _cycle[shape];
    final pathB = _cycle[(shape + 1) % k];
    for (var i = 0; i < _kSamples; i++) {
      final f = i / _kSamples;
      final a = pathA(f);
      final b = pathB(f);
      _px[i] = (a.$1 + (b.$1 - a.$1) * m) * spread;
      _py[i] = (a.$2 + (b.$2 - a.$2) * m) * spread;
    }
    var total = 0.0;
    for (var i = 0; i < _kSamples; i++) {
      final j = (i + 1) % _kSamples;
      final dx = _px[j] - _px[i];
      final dy = _py[j] - _py[i];
      _len[i] = math.sqrt(dx * dx + dy * dy);
      total += _len[i];
    }

    final n = math.max(6, o.glyphDots);
    final re = o.rDot * 1.35 * spread;
    final pulse = 1 + 0.02 * intensity * math.sin(local * 3.1);
    final c2 = size / 2;
    var seg = 0;
    var acc = 0.0;
    for (var d = 0; d < n; d++) {
      final target = (d / n) * total;
      while (acc + _len[seg] < target && seg < _kSamples - 1) {
        acc += _len[seg];
        seg++;
      }
      final j = (seg + 1) % _kSamples;
      final f = _len[seg] == 0
          ? 0.0
          : math.min(1.0, (target - acc) / _len[seg]);
      final x = (_px[seg] + (_px[j] - _px[seg]) * f) * pulse;
      final y = (_py[seg] + (_py[j] - _py[seg]) * f) * pulse;
      out.add(c2 + x * size, c2 + y * size, 0, math.max(0.35, re * size), 0.1);
    }
    out.clampRadius(o.rMin);
  }
}
