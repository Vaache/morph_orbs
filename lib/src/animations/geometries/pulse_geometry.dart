import 'dart:math' as math;

import '../../models/orb_frame.dart';
import '../../utils/orb_math.dart';
import '../orb_geometry.dart';
import '../orb_profile.dart';

/// Concentric dotted rings radiate from a small core and fade as they
/// reach the edge — a slow heartbeat.
class PulseGeometry extends OrbGeometry {
  const PulseGeometry();

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
    final radius = (size / 2) * 0.86;
    final rs = radiusScale(size, o.rsPow);
    final rings = math.max(1, o.featureN);
    final perRing = math.max(8, o.fieldN);
    final beat = 0.5 + 0.5 * math.sin(t * 0.9);

    for (var k = 0; k < rings; k++) {
      final phase = frac(t * 0.22 + k / rings);
      final eased = phase * phase * (2 - phase);
      final rr = radius * (0.12 + 0.88 * eased);
      final fade = 1 - 0.75 * phase * phase;
      final twist = k * 0.4 + t * 0.05;
      for (var i = 0; i < perRing; i++) {
        final a = (i / perRing) * kTau + twist;
        final wob = 1 + 0.03 * intensity * math.sin(a * 6 + t * 1.3 + k);
        out.add(
          cx + math.cos(a) * rr * wob,
          cy + math.sin(a) * rr * wob,
          phase - 0.5,
          (o.rBase + o.rDepth * (1 - phase)) * rs,
          0.12 + 0.45 * phase,
          fade,
        );
      }
    }

    final core = math.max(1, o.particles);
    final coreR = radius * 0.1 * (1 + 0.5 * beat * intensity);
    for (var i = 0; i < core; i++) {
      final a = (i / core) * kTau - t * 0.6;
      out.add(
        cx + math.cos(a) * coreR,
        cy + math.sin(a) * coreR,
        1,
        (o.partR + o.partRDepth * beat) * rs,
        0.05,
      );
    }
    out.clampRadius(o.rMin);
  }
}
