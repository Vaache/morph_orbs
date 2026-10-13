/// The dot engine behind `morph_orbs`, for packages that build their own
/// dotted animations on top of it: the reusable [OrbFrame] buffer and its
/// index-mapped morph, the shared painter, every orb geometry resolved for
/// a size, and the small math kit the geometries use.
///
/// ```dart
/// import 'package:morph_orbs/engine.dart';
/// ```
///
/// Most apps only need `package:morph_orbs/morph_orbs.dart`.
library;

export 'src/animations/orb_geometry.dart';
export 'src/animations/orb_presets.dart'
    show OrbStateSpec, ResolvedOrbState, resolveOrbState;
export 'src/animations/orb_profile.dart';
export 'src/models/orb_frame.dart';
export 'src/painters/morph_orb_painter.dart' show paintOrbFrame;
export 'src/utils/orb_math.dart';
