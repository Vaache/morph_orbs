import '../models/orb_frame.dart';
import 'orb_profile.dart';

/// Pure geometry for one instant: writes the dots for (size, t, profile)
/// into [out]. No rendering surface, no colour — ink is resolved at paint
/// time. Implementations are stateless and deterministic, so any two
/// geometries can be morphed dot-for-dot by the controller.
abstract class OrbGeometry {
  const OrbGeometry();

  /// [t] is the geometry's own clock: already scaled by the preset speed for
  /// looping geometries, or seconds since the state was entered for glyphs.
  /// [intensity] scales deformation amplitude; `1` is the tuned look.
  void build(
    OrbFrame out,
    double size,
    double t,
    OrbProfile profile,
    double intensity,
  );

  /// Whether the geometry still changes at [t]; a settled glyph returns
  /// false so the ticker can stop.
  bool isAnimatingAt(double t) => true;
}
