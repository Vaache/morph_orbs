import 'dart:math' as math;

import '../../models/orb_frame.dart';
import '../../utils/orb_math.dart';
import '../orb_geometry.dart';
import '../orb_profile.dart';

/// A lat/long dot field with a scan meridian sweeping it — searching.
class GlobeGeometry extends OrbGeometry {
  const GlobeGeometry();

  @override
  void build(
    OrbFrame out,
    double size,
    double t,
    OrbProfile o,
    double intensity,
  ) {
    out.clear();
    const spin = 0.5;
    final cx = size / 2;
    final cy = size / 2;
    final radius = (size / 2) * 0.82;
    final tilt = 0.4 + 0.06 * math.sin(t * 0.35);
    final pt = Projector(t * spin, tilt, cx, cy, radius);
    final scan = t * (spin + (1.7 - spin) * o.scanMul);
    final rs = radiusScale(size, o.rsPow);
    final boostMul = o.rBoost * intensity;

    for (var li = 0; li <= o.latRings; li++) {
      final lat = -math.pi / 2 + (li / o.latRings) * math.pi;
      final cosLat = math.cos(lat);
      final sinLat = math.sin(lat);
      final lonCount = math.max(1, (cosLat.abs() * o.lonDensity).round());
      for (var lj = 0; lj < lonCount; lj++) {
        final lon = (lj / lonCount) * kTau;
        pt.project(cosLat * math.cos(lon), sinLat, cosLat * math.sin(lon));
        final depth = (pt.pz + 1) / 2;
        final d = angleDelta(lon + t * spin, scan);
        final boost = math.exp(-(d * d) / 0.18) * math.max(0.0, pt.pz);
        out.add(
          pt.px,
          pt.py,
          pt.pz,
          (o.rBase + o.rDepth * depth + boostMul * boost) * rs,
          o.inkFar - o.inkSpan * depth,
          o.dimBase + (1 - o.dimBase) * math.min(1.0, boost),
        );
      }
    }
    out.clampRadius(o.rMin);
  }
}

/// A waveform rolling through latitude rings — listening.
class WaveGeometry extends OrbGeometry {
  const WaveGeometry();

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
    final radius = (size / 2) * 0.874;
    final pt = Projector(t * 0.18, 0.38, cx, cy, 1);
    final rs = radiusScale(size, o.rsPow);

    for (var ri = 0; ri <= o.latRings; ri++) {
      final lat = -math.pi / 2 + (ri / o.latRings) * math.pi;
      final cosLat = math.cos(lat);
      final sinLat = math.sin(lat);
      final w =
          (0.62 * math.sin(t * 2.1 - ri * 0.52) +
              0.38 * math.sin(t * 1.27 + ri * 0.83)) *
          intensity;
      final rr = radius * (0.88 + 0.105 * w);
      final crest = math.max(0.0, w);
      final lonCount = math.max(1, (cosLat.abs() * o.lonDensity).round());
      for (var lj = 0; lj < lonCount; lj++) {
        final lon = (lj / lonCount) * kTau;
        pt.project(
          cosLat * math.cos(lon) * rr,
          sinLat * rr,
          cosLat * math.sin(lon) * rr,
        );
        final depth = (pt.pz / radius + 1) / 2;
        out.add(
          pt.px,
          pt.py,
          pt.pz,
          (o.rBase + o.rDepth * depth) * (1 + 0.4 * crest) * rs,
          0.66 - 0.56 * depth - 0.1 * crest,
        );
      }
    }
    out.clampRadius(o.rMin);
  }
}
