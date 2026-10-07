import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/morph_orb_state.dart';
import '../models/morph_orb_variant.dart';
import '../utils/orb_math.dart';
import 'geometries/bloom_geometry.dart';
import 'geometries/braid_geometry.dart';
import 'geometries/constellate_geometry.dart';
import 'geometries/echo_geometry.dart';
import 'geometries/glyph_geometry.dart';
import 'geometries/helix_geometry.dart';
import 'geometries/lattice_geometry.dart';
import 'geometries/morph_geometry.dart';
import 'geometries/nebula_geometry.dart';
import 'geometries/orbits_geometry.dart';
import 'geometries/pulse_geometry.dart';
import 'geometries/ribbon_geometry.dart';
import 'geometries/rubik_geometry.dart';
import 'geometries/swarm_geometry.dart';
import 'geometries/vortex_geometry.dart';
import 'geometries/web_geometry.dart';
import 'orb_geometry.dart';
import 'orb_profile.dart';

/// Every geometry the engine can draw: the public variants plus the
/// terminal glyphs.
enum OrbGeometryKind {
  orbits,
  ring,
  ribbon,
  rubik,
  globe,
  wave,
  web,
  braid,
  morph,
  pulse,
  swarm,
  helix,
  nebula,
  vortex,
  echo,
  constellate,
  bloom,
  check,
  cross;

  static OrbGeometryKind of(MorphOrbVariant variant) =>
      OrbGeometryKind.values[variant.index];
}

/// One tuned (geometry × size) point: multipliers over the base profile.
@immutable
class OrbPreset {
  const OrbPreset({
    required this.speed,
    required this.count,
    required this.size,
    this.bandMul = 1,
    this.wobMul = 1,
    this.spin = 1,
  });

  final double speed;
  final double count;
  final double size;
  final double bandMul;
  final double wobMul;
  final double spin;

  static OrbPreset lerpLogBetween(OrbPreset a, OrbPreset b, double f) =>
      OrbPreset(
        speed: lerpLog(a.speed, b.speed, f),
        count: lerpLog(a.count, b.count, f),
        size: lerpLog(a.size, b.size, f),
        bandMul: lerpLog(a.bandMul, b.bandMul, f),
        wobMul: lerpLog(a.wobMul, b.wobMul, f),
        spin: lerp(a.spin, b.spin, f),
      );
}

/// What one [MorphOrbState] renders: a geometry, the per-state tweaks on
/// its resolved profile, and how it is framed.
@immutable
class OrbStateSpec {
  const OrbStateSpec({
    required this.kind,
    this.speedMul = 1,
    this.wobMul = 1,
    this.scale = 1,
    this.opacity = 1,
    this.frozen = false,
  });

  final OrbGeometryKind kind;
  final double speedMul;
  final double wobMul;
  final double scale;
  final double opacity;

  /// The clock does not advance for this state.
  final bool frozen;

  /// The default geometry of a continuous state; null for terminal states,
  /// which always draw their own glyph.
  static MorphOrbVariant? defaultVariant(MorphOrbState state) =>
      switch (state) {
        MorphOrbState.idle => MorphOrbVariant.ring,
        MorphOrbState.thinking => MorphOrbVariant.orbits,
        MorphOrbState.processing => MorphOrbVariant.rubik,
        MorphOrbState.generating => MorphOrbVariant.ribbon,
        MorphOrbState.success ||
        MorphOrbState.error ||
        MorphOrbState.stopped => null,
      };

  static OrbStateSpec of(MorphOrbState state, MorphOrbVariant? variant) {
    final chosen = variant ?? defaultVariant(state);
    return switch (state) {
      MorphOrbState.idle => OrbStateSpec(
        kind: OrbGeometryKind.of(chosen!),
        speedMul: 0.42,
        wobMul: 0.38,
      ),
      MorphOrbState.thinking ||
      MorphOrbState.processing ||
      MorphOrbState.generating => OrbStateSpec(
        kind: OrbGeometryKind.of(chosen!),
      ),
      MorphOrbState.success => const OrbStateSpec(kind: OrbGeometryKind.check),
      MorphOrbState.error => const OrbStateSpec(kind: OrbGeometryKind.cross),
      MorphOrbState.stopped => const OrbStateSpec(
        kind: OrbGeometryKind.ring,
        wobMul: 0,
        scale: 0.86,
        opacity: 0.55,
        frozen: true,
      ),
    };
  }
}

const double _kSmallSize = 20;
const double _kMidSize = 32;
const double _kLargeSize = 64;

const Map<OrbGeometryKind, OrbGeometry> _kGeometries = {
  OrbGeometryKind.orbits: OrbitsGeometry(),
  OrbGeometryKind.ring: RibbonGeometry(),
  OrbGeometryKind.ribbon: RibbonGeometry(),
  OrbGeometryKind.rubik: RubikGeometry(),
  OrbGeometryKind.globe: GlobeGeometry(),
  OrbGeometryKind.wave: WaveGeometry(),
  OrbGeometryKind.web: WebGeometry(),
  OrbGeometryKind.braid: BraidGeometry(),
  OrbGeometryKind.morph: MorphGeometry(),
  OrbGeometryKind.pulse: PulseGeometry(),
  OrbGeometryKind.swarm: SwarmGeometry(),
  OrbGeometryKind.helix: HelixGeometry(),
  OrbGeometryKind.nebula: NebulaGeometry(),
  OrbGeometryKind.vortex: VortexGeometry(),
  OrbGeometryKind.echo: EchoGeometry(),
  OrbGeometryKind.constellate: ConstellateGeometry(),
  OrbGeometryKind.bloom: BloomGeometry(),
  OrbGeometryKind.check: GlyphGeometry.check(),
  OrbGeometryKind.cross: GlyphGeometry.cross(),
};

const Map<OrbGeometryKind, OrbProfile> _kBaseProfiles = {
  OrbGeometryKind.orbits: OrbProfile(
    orbitN: 12,
    ghostN: 40,
    ghostR: 0.9,
    ghostA: 0.5,
    particles: 3,
    partR: 1.2,
    partRDepth: 1.6,
  ),
  OrbGeometryKind.ring: OrbProfile(
    lanes: 5,
    segs: 88,
    rBase: 1.1,
    rDepth: 1.7,
    faceOn: true,
  ),
  OrbGeometryKind.ribbon: OrbProfile(
    lanes: 5,
    segs: 88,
    ghostN: 150,
    rBase: 1.1,
    rDepth: 1.7,
  ),
  OrbGeometryKind.rubik: OrbProfile(
    latRings: 15,
    lonDensity: 40,
    moveCount: 14,
    rBase: 0.6,
    rDepth: 1.7,
    rActive: 0.3,
  ),
  OrbGeometryKind.globe: OrbProfile(
    latRings: 17,
    lonDensity: 44,
    rBase: 0.6,
    rDepth: 1.7,
    rBoost: 1,
  ),
  OrbGeometryKind.wave: OrbProfile(
    latRings: 15,
    lonDensity: 40,
    rBase: 0.6,
    rDepth: 1.7,
  ),
  OrbGeometryKind.web: OrbProfile(
    nodeN: 30,
    thr: 0.72,
    signals: 5,
    nodeR: 1.4,
    nodeRDepth: 1.8,
    lineW: 0.8,
  ),
  OrbGeometryKind.braid: OrbProfile(
    strandN: 52,
    turns: 3,
    ghostN: 150,
    rBase: 1.2,
    rDepth: 1.8,
  ),
  OrbGeometryKind.morph: OrbProfile(glyphDots: 34, rDot: 0.021, rMin: 0.25),
  OrbGeometryKind.pulse: OrbProfile(
    fieldN: 40,
    featureN: 3,
    particles: 5,
    rBase: 0.7,
    rDepth: 1.3,
    partR: 1.1,
    partRDepth: 0.9,
  ),
  OrbGeometryKind.swarm: OrbProfile(fieldN: 110, rBase: 0.8, rDepth: 1.9),
  OrbGeometryKind.helix: OrbProfile(
    strandN: 56,
    featureN: 10,
    turns: 3.2,
    rBase: 1.0,
    rDepth: 1.8,
    lineW: 0.8,
  ),
  OrbGeometryKind.nebula: OrbProfile(fieldN: 160, rBase: 0.5, rDepth: 1.9),
  OrbGeometryKind.vortex: OrbProfile(
    fieldN: 120,
    featureN: 4,
    turns: 1.1,
    rBase: 0.6,
    rDepth: 1.7,
  ),
  OrbGeometryKind.echo: OrbProfile(
    fieldN: 140,
    featureN: 48,
    rBase: 0.6,
    rDepth: 1.2,
    rBoost: 1.4,
    dimBase: 0.3,
  ),
  OrbGeometryKind.constellate: OrbProfile(
    nodeN: 44,
    signals: 5,
    nodeR: 0.9,
    nodeRDepth: 1.4,
    rBoost: 1.6,
    lineW: 0.8,
  ),
  OrbGeometryKind.bloom: OrbProfile(
    fieldN: 150,
    featureN: 5,
    particles: 4,
    rBase: 0.7,
    rDepth: 1.6,
    partR: 1.0,
    partRDepth: 0.6,
  ),
  OrbGeometryKind.check: OrbProfile(glyphDots: 30, rDot: 0.024, rMin: 0.35),
  OrbGeometryKind.cross: OrbProfile(glyphDots: 32, rDot: 0.024, rMin: 0.35),
};

/// Hand-tuned points at 20 / 32 / 64 px (inline text, compact avatar,
/// chat avatar); any other size is log-interpolated between its neighbours
/// and clamped outside the range, where [radiusScale] takes over.
const Map<OrbGeometryKind, (OrbPreset, OrbPreset, OrbPreset)> _kPresets = {
  OrbGeometryKind.orbits: (
    OrbPreset(speed: 3.9, count: 0.238, size: 2.4),
    OrbPreset(speed: 2.9072, count: 0.4251, size: 1.6849),
    OrbPreset(speed: 1.885, count: 1, size: 1),
  ),
  OrbGeometryKind.ring: (
    OrbPreset(
      speed: 3.78,
      count: 0.028,
      size: 1.622,
      bandMul: 3.968,
      wobMul: 0.565,
      spin: 0,
    ),
    OrbPreset(
      speed: 3.5517,
      count: 0.0678,
      size: 1.31,
      bandMul: 3.8265,
      wobMul: 0.4751,
      spin: 0,
    ),
    OrbPreset(
      speed: 3.24,
      count: 0.25,
      size: 0.956,
      bandMul: 3.627,
      wobMul: 0.368,
      spin: 0,
    ),
  ),
  OrbGeometryKind.ribbon: (
    OrbPreset(speed: 3.12, count: 0.051, size: 1.073, bandMul: 4.94, spin: 0),
    OrbPreset(
      speed: 2.7776,
      count: 0.0969,
      size: 0.9766,
      bandMul: 4.49,
      spin: 0,
    ),
    OrbPreset(speed: 2.34, count: 0.25, size: 0.85, bandMul: 3.9, spin: 0),
  ),
  OrbGeometryKind.rubik: (
    OrbPreset(speed: 1.95, count: 0.088, size: 1.9),
    OrbPreset(speed: 1.8964, count: 0.1537, size: 1.4951),
    OrbPreset(speed: 1.82, count: 0.35, size: 1.05),
  ),
  OrbGeometryKind.globe: (
    OrbPreset(speed: 2.665, count: 0.105, size: 1.75),
    OrbPreset(speed: 2.3803, count: 0.1839, size: 1.4769),
    OrbPreset(speed: 2.015, count: 0.42, size: 1.15),
  ),
  OrbGeometryKind.wave: (
    OrbPreset(speed: 3.998, count: 0.105, size: 1.6),
    OrbPreset(speed: 4.1512, count: 0.169, size: 1.3232),
    OrbPreset(speed: 4.388, count: 0.341, size: 1),
  ),
  OrbGeometryKind.web: (
    OrbPreset(speed: 6.63, count: 0.25, size: 1.52),
    OrbPreset(speed: 5.0104, count: 0.4942, size: 1.2571),
    OrbPreset(speed: 3.315, count: 1.35, size: 0.95),
  ),
  OrbGeometryKind.braid: (
    OrbPreset(speed: 2.75, count: 0.1125, size: 1.36),
    OrbPreset(speed: 2.2234, count: 0.2056, size: 1.2011),
    OrbPreset(speed: 1.625, count: 0.5, size: 1),
  ),
  OrbGeometryKind.morph: (
    OrbPreset(speed: 2.08, count: 0.53, size: 1.011),
    OrbPreset(speed: 2.2057, count: 0.5937, size: 0.6916),
    OrbPreset(speed: 2.405, count: 0.702, size: 0.395),
  ),
  OrbGeometryKind.pulse: (
    OrbPreset(speed: 3.2, count: 0.45, size: 2.0),
    OrbPreset(speed: 2.9, count: 0.65, size: 1.5),
    OrbPreset(speed: 2.6, count: 1, size: 1),
  ),
  OrbGeometryKind.swarm: (
    OrbPreset(speed: 3.4, count: 0.3, size: 2.1),
    OrbPreset(speed: 2.9, count: 0.5, size: 1.55),
    OrbPreset(speed: 2.4, count: 1, size: 1),
  ),
  OrbGeometryKind.helix: (
    OrbPreset(speed: 3.0, count: 0.5, size: 1.9),
    OrbPreset(speed: 2.6, count: 0.7, size: 1.45),
    OrbPreset(speed: 2.2, count: 1, size: 1),
  ),
  OrbGeometryKind.nebula: (
    OrbPreset(speed: 3.2, count: 0.3, size: 2.2),
    OrbPreset(speed: 2.8, count: 0.5, size: 1.6),
    OrbPreset(speed: 2.4, count: 1, size: 1),
  ),
  OrbGeometryKind.vortex: (
    OrbPreset(speed: 3.6, count: 0.35, size: 2.0),
    OrbPreset(speed: 3.1, count: 0.55, size: 1.5),
    OrbPreset(speed: 2.6, count: 1, size: 1),
  ),
  OrbGeometryKind.echo: (
    OrbPreset(speed: 2.8, count: 0.3, size: 2.0),
    OrbPreset(speed: 2.5, count: 0.5, size: 1.5),
    OrbPreset(speed: 2.2, count: 1, size: 1),
  ),
  OrbGeometryKind.constellate: (
    OrbPreset(speed: 2.6, count: 0.4, size: 1.9),
    OrbPreset(speed: 2.3, count: 0.6, size: 1.45),
    OrbPreset(speed: 2.0, count: 1, size: 1),
  ),
  OrbGeometryKind.bloom: (
    OrbPreset(speed: 3.0, count: 0.3, size: 2.0),
    OrbPreset(speed: 2.7, count: 0.5, size: 1.5),
    OrbPreset(speed: 2.4, count: 1, size: 1),
  ),
  OrbGeometryKind.check: (
    OrbPreset(speed: 1, count: 0.55, size: 1.5),
    OrbPreset(speed: 1, count: 0.75, size: 1.2),
    OrbPreset(speed: 1, count: 1, size: 1),
  ),
  OrbGeometryKind.cross: (
    OrbPreset(speed: 1, count: 0.55, size: 1.5),
    OrbPreset(speed: 1, count: 0.75, size: 1.2),
    OrbPreset(speed: 1, count: 1, size: 1),
  ),
};

/// A state resolved for one size: the geometry to run and its profile.
@immutable
class ResolvedOrbState {
  const ResolvedOrbState({
    required this.state,
    required this.spec,
    required this.geometry,
    required this.profile,
  });

  final MorphOrbState state;
  final OrbStateSpec spec;
  final OrbGeometry geometry;
  final OrbProfile profile;
}

OrbPreset _presetFor(OrbGeometryKind kind, double size) {
  final (small, mid, large) = _kPresets[kind]!;
  if (size <= _kSmallSize) {
    return small;
  }
  if (size >= _kLargeSize) {
    return large;
  }
  if (size <= _kMidSize) {
    return OrbPreset.lerpLogBetween(
      small,
      mid,
      (size - _kSmallSize) / (_kMidSize - _kSmallSize),
    );
  }
  return OrbPreset.lerpLogBetween(
    mid,
    large,
    (size - _kMidSize) / (_kLargeSize - _kMidSize),
  );
}

ResolvedOrbState resolveOrbState(
  MorphOrbState state,
  double size, {
  MorphOrbVariant? variant,
  double density = 1,
  double dotScale = 1,
}) {
  final spec = OrbStateSpec.of(state, variant);
  final preset = _presetFor(spec.kind, size);
  var profile = _kBaseProfiles[spec.kind]!
      .scaleCounts(preset.count * math.max(0.1, density))
      .scaleRadii(preset.size * math.max(0.1, dotScale));
  profile = profile.copyWith(
    speed: preset.speed * spec.speedMul,
    bandMul: preset.bandMul,
    wobMul: preset.wobMul * spec.wobMul,
    spin: preset.spin,
  );
  return ResolvedOrbState(
    state: state,
    spec: spec,
    geometry: _kGeometries[spec.kind]!,
    profile: profile,
  );
}
