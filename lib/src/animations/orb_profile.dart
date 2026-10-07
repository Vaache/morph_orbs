import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Density and mark tuning for one geometry, after preset multipliers.
/// Lattice pairs (rings × dots-per-ring, lanes × segs) scale by √factor on
/// each side so the total count scales linearly; flat counts scale directly.
@immutable
class OrbProfile {
  const OrbProfile({
    this.latRings = 0,
    this.lonDensity = 0,
    this.orbitN = 0,
    this.ghostN = 0,
    this.particles = 0,
    this.lanes = 0,
    this.segs = 0,
    this.moveCount = 0,
    this.glyphDots = 0,
    this.fieldN = 0,
    this.featureN = 0,
    this.strandN = 0,
    this.nodeN = 0,
    this.signals = 0,
    this.rBase = 0,
    this.rDepth = 0,
    this.rActive = 0,
    this.ghostR = 0,
    this.ghostA = 0,
    this.partR = 0,
    this.partRDepth = 0,
    this.rDot = 0,
    this.nodeR = 0,
    this.nodeRDepth = 0,
    this.lineW = 0.8,
    this.thr = 0.72,
    this.turns = 3,
    this.scanMul = 1,
    this.dimBase = 1,
    this.rBoost = 1,
    this.spread = 1,
    this.inkFar = 0.62,
    this.inkSpan = 0.54,
    this.rsPow = 0.6,
    this.rMin = 0.3,
    this.spin = 1,
    this.bandMul = 1,
    this.wobMul = 1,
    this.faceOn = false,
    this.speed = 1,
  });

  final int latRings;
  final int lonDensity;
  final int orbitN;
  final int ghostN;
  final int particles;
  final int lanes;
  final int segs;
  final int moveCount;
  final int glyphDots;

  /// Generic primary count (a field of dots) for the house geometries.
  final int fieldN;

  /// Generic secondary count (rings, petals, rows, strands) for the house
  /// geometries.
  final int featureN;
  final int strandN;
  final int nodeN;
  final int signals;

  final double rBase;
  final double rDepth;
  final double rActive;
  final double ghostR;
  final double ghostA;
  final double partR;
  final double partRDepth;
  final double rDot;
  final double nodeR;
  final double nodeRDepth;
  final double lineW;
  final double thr;
  final double turns;
  final double scanMul;
  final double dimBase;
  final double rBoost;
  final double spread;

  final double inkFar;
  final double inkSpan;
  final double rsPow;
  final double rMin;
  final double spin;
  final double bandMul;
  final double wobMul;
  final bool faceOn;

  /// Clock multiplier for this geometry.
  final double speed;

  OrbProfile scaleCounts(double factor) {
    if (factor == 1) {
      return this;
    }
    final root = math.sqrt(factor);
    int pair(int v) => v == 0 ? 0 : math.max(2, (v * root).round());
    int flat(int v) => v == 0 ? 0 : math.max(1, (v * factor).round());
    return copyWith(
      latRings: pair(latRings),
      lonDensity: pair(lonDensity),
      lanes: pair(lanes),
      segs: pair(segs),
      orbitN: flat(orbitN),
      ghostN: flat(ghostN),
      glyphDots: flat(glyphDots),
      fieldN: flat(fieldN),
      strandN: flat(strandN),
      nodeN: flat(nodeN),
      signals: flat(signals),
    );
  }

  OrbProfile scaleRadii(double factor) {
    if (factor == 1) {
      return this;
    }
    return copyWith(
      rBase: rBase * factor,
      rDepth: rDepth * factor,
      rActive: rActive * factor,
      ghostR: ghostR * factor,
      partR: partR * factor,
      partRDepth: partRDepth * factor,
      rDot: rDot * factor,
      nodeR: nodeR * factor,
      nodeRDepth: nodeRDepth * factor,
      lineW: lineW * factor,
    );
  }

  OrbProfile copyWith({
    int? latRings,
    int? lonDensity,
    int? orbitN,
    int? ghostN,
    int? particles,
    int? lanes,
    int? segs,
    int? moveCount,
    int? glyphDots,
    int? fieldN,
    int? featureN,
    int? strandN,
    int? nodeN,
    int? signals,
    double? rBase,
    double? rDepth,
    double? rActive,
    double? ghostR,
    double? ghostA,
    double? partR,
    double? partRDepth,
    double? rDot,
    double? nodeR,
    double? nodeRDepth,
    double? lineW,
    double? thr,
    double? turns,
    double? scanMul,
    double? dimBase,
    double? rBoost,
    double? spread,
    double? inkFar,
    double? inkSpan,
    double? rsPow,
    double? rMin,
    double? spin,
    double? bandMul,
    double? wobMul,
    bool? faceOn,
    double? speed,
  }) => OrbProfile(
    latRings: latRings ?? this.latRings,
    lonDensity: lonDensity ?? this.lonDensity,
    orbitN: orbitN ?? this.orbitN,
    ghostN: ghostN ?? this.ghostN,
    particles: particles ?? this.particles,
    lanes: lanes ?? this.lanes,
    segs: segs ?? this.segs,
    moveCount: moveCount ?? this.moveCount,
    glyphDots: glyphDots ?? this.glyphDots,
    fieldN: fieldN ?? this.fieldN,
    featureN: featureN ?? this.featureN,
    strandN: strandN ?? this.strandN,
    nodeN: nodeN ?? this.nodeN,
    signals: signals ?? this.signals,
    rBase: rBase ?? this.rBase,
    rDepth: rDepth ?? this.rDepth,
    rActive: rActive ?? this.rActive,
    ghostR: ghostR ?? this.ghostR,
    ghostA: ghostA ?? this.ghostA,
    partR: partR ?? this.partR,
    partRDepth: partRDepth ?? this.partRDepth,
    rDot: rDot ?? this.rDot,
    nodeR: nodeR ?? this.nodeR,
    nodeRDepth: nodeRDepth ?? this.nodeRDepth,
    lineW: lineW ?? this.lineW,
    thr: thr ?? this.thr,
    turns: turns ?? this.turns,
    scanMul: scanMul ?? this.scanMul,
    dimBase: dimBase ?? this.dimBase,
    rBoost: rBoost ?? this.rBoost,
    spread: spread ?? this.spread,
    inkFar: inkFar ?? this.inkFar,
    inkSpan: inkSpan ?? this.inkSpan,
    rsPow: rsPow ?? this.rsPow,
    rMin: rMin ?? this.rMin,
    spin: spin ?? this.spin,
    bandMul: bandMul ?? this.bandMul,
    wobMul: wobMul ?? this.wobMul,
    faceOn: faceOn ?? this.faceOn,
    speed: speed ?? this.speed,
  );
}
