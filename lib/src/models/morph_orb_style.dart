import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

import 'morph_orb_state.dart';

/// Visual tuning shared by every state. Everything is optional: the orb
/// resolves its ink from the surrounding text colour when [color] is null.
@immutable
class MorphOrbStyle {
  const MorphOrbStyle({
    this.color,
    this.successColor,
    this.errorColor,
    this.backgroundColor,
    this.transitionDuration = const Duration(milliseconds: 650),
    this.transitionCurve = Curves.easeInOutCubic,
    this.density = 1,
    this.dotScale = 1,
  }) : assert(density > 0, 'density must be positive'),
       assert(dotScale > 0, 'dotScale must be positive');

  /// Ink colour. Depth shading fades it toward transparent (or toward
  /// [backgroundColor] when set).
  final Color? color;

  /// Ink used once the orb has settled into [MorphOrbState.success].
  final Color? successColor;

  /// Ink used once the orb has settled into [MorphOrbState.error].
  final Color? errorColor;

  /// When the orb sits on a known solid surface, far dots fade toward this
  /// colour instead of toward transparent, so near dots occlude far ones.
  final Color? backgroundColor;

  final Duration transitionDuration;
  final Curve transitionCurve;

  /// Multiplier on the tuned dot count; `0.5` halves density, `2` doubles.
  final double density;

  /// Multiplier on every dot radius.
  final double dotScale;

  Color? colorFor(MorphOrbState state) => switch (state) {
    MorphOrbState.success => successColor ?? color,
    MorphOrbState.error => errorColor ?? color,
    _ => color,
  };

  MorphOrbStyle copyWith({
    Color? color,
    Color? successColor,
    Color? errorColor,
    Color? backgroundColor,
    Duration? transitionDuration,
    Curve? transitionCurve,
    double? density,
    double? dotScale,
  }) => MorphOrbStyle(
    color: color ?? this.color,
    successColor: successColor ?? this.successColor,
    errorColor: errorColor ?? this.errorColor,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    transitionDuration: transitionDuration ?? this.transitionDuration,
    transitionCurve: transitionCurve ?? this.transitionCurve,
    density: density ?? this.density,
    dotScale: dotScale ?? this.dotScale,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MorphOrbStyle &&
          other.color == color &&
          other.successColor == successColor &&
          other.errorColor == errorColor &&
          other.backgroundColor == backgroundColor &&
          other.transitionDuration == transitionDuration &&
          other.transitionCurve == transitionCurve &&
          other.density == density &&
          other.dotScale == dotScale;

  @override
  int get hashCode => Object.hash(
    color,
    successColor,
    errorColor,
    backgroundColor,
    transitionDuration,
    transitionCurve,
    density,
    dotScale,
  );
}
