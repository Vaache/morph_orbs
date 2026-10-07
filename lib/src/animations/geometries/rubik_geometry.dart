import 'dart:math' as math;

import '../../models/orb_frame.dart';
import '../../utils/orb_math.dart';
import '../orb_geometry.dart';
import '../orb_profile.dart';

const double _kSlotDuration = 0.42;
const double _kRest = 1.2;
const int _kMaxMoves = 32;

/// Latitude bands twist in quarter turns, scramble, then click back solved
/// — the processing state.
class RubikGeometry extends OrbGeometry {
  const RubikGeometry();

  static final List<double> _amount = List<double>.filled(_kMaxMoves, 0);
  static final List<int> _axis = List<int>.generate(
    _kMaxMoves,
    (i) => math.min(2, (hashD(i.toDouble(), 2.3) * 3).floor()),
  );
  static final List<double> _lo = List<double>.generate(
    _kMaxMoves,
    (i) => -1.0 + 0.5 * math.min(3, (hashD(i.toDouble(), 5.9) * 4).floor()),
  );
  static final List<double> _ang = List<double>.generate(
    _kMaxMoves,
    (i) => (hashD(i.toDouble(), 7.7) < 0.5 ? 1 : -1) * math.pi / 2,
  );

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
    final pt = Projector(
      t * 0.55,
      0.35 + 0.1 * math.sin(t * 0.9),
      cx,
      cy,
      radius,
    );
    final rs = radiusScale(size, o.rsPow);
    final count = math.min(_kMaxMoves, o.moveCount);
    final active = _solveCycle(t, count);

    for (var li = 0; li <= o.latRings; li++) {
      final lat = -math.pi / 2 + (li / o.latRings) * math.pi;
      final cosLat = math.cos(lat);
      final sinLat = math.sin(lat);
      final lonCount = math.max(1, (cosLat.abs() * o.lonDensity).round());
      for (var lj = 0; lj < lonCount; lj++) {
        final lon = (lj / lonCount) * kTau;
        var x = cosLat * math.cos(lon);
        var y = sinLat;
        var z = cosLat * math.sin(lon);
        var inActive = false;
        for (var i = 0; i < count; i++) {
          final amount = _amount[i];
          if (amount <= 0) {
            continue;
          }
          final coord = _axis[i] == 0 ? x : (_axis[i] == 1 ? y : z);
          final lo = _lo[i];
          if (coord < lo || coord >= lo + 0.5) {
            continue;
          }
          if (i == active) {
            inActive = true;
          }
          final a = _ang[i] * amount * intensity;
          final ca = math.cos(a);
          final sa = math.sin(a);
          switch (_axis[i]) {
            case 0:
              final y2 = y * ca - z * sa;
              z = y * sa + z * ca;
              y = y2;
            case 1:
              final x2 = x * ca + z * sa;
              z = -x * sa + z * ca;
              x = x2;
            default:
              final x2 = x * ca - y * sa;
              y = x * sa + y * ca;
              x = x2;
          }
        }
        pt.project(x, y, z);
        final depth = (pt.pz + 1) / 2;
        out.add(
          pt.px,
          pt.py,
          pt.pz,
          (o.rBase + o.rDepth * depth + (inActive ? o.rActive : 0)) * rs,
          o.inkFar - o.inkSpan * depth - (inActive ? 0.14 : 0),
        );
      }
    }
    out.clampRadius(o.rMin);
  }

  /// Fills [_amount] for the palindromic scramble → solve cycle and returns
  /// the index of the move in motion, or -1 while resting.
  static int _solveCycle(double time, int count) {
    final cycle = 2 * count * _kSlotDuration + _kRest;
    final tc = time % cycle;
    for (var i = 0; i < count; i++) {
      _amount[i] = 0;
    }
    if (tc >= 2 * count * _kSlotDuration) {
      return -1;
    }
    final slot = (tc / _kSlotDuration).floor();
    final p = (tc - slot * _kSlotDuration) / _kSlotDuration;
    final cl = math.min(1.0, p / 0.7);
    final ep = 1 - math.pow(1 - cl, 3).toDouble();
    if (slot < count) {
      for (var i = 0; i < slot; i++) {
        _amount[i] = 1;
      }
      _amount[slot] = ep;
      return slot;
    }
    final u = 2 * count - 1 - slot;
    for (var i = 0; i < u; i++) {
      _amount[i] = 1;
    }
    _amount[u] = 1 - ep;
    return u;
  }
}
