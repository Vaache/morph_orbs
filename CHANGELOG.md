## 0.2.0

- New `package:morph_orbs/engine.dart` library for packages built on the dot
  engine: `OrbFrame`, `paintOrbFrame`, `OrbGeometry`, `OrbProfile`,
  `resolveOrbState` and the math helpers.
- Dots can carry their own colour: `OrbFrame.addTinted` and a tint channel
  that `OrbFrame.blend` morphs across.
- Dots with a zero radius are skipped when painting.

## 0.1.0

Initial release.

- `MorphOrb` widget with seven lifecycle states: `idle`, `thinking`,
  `processing`, `generating`, `success`, `error`, `stopped`.
- Seventeen geometries selectable through `variant`: orbits, ring, ribbon,
  rubik, globe, wave, web, braid, morph, pulse, swarm, helix, nebula, vortex,
  echo, constellate, bloom.
- Dot-for-dot morph between any two geometries on state or variant change,
  interruptible mid-transition.
- Terminal states settle into a check, a cross or a frozen ring and then stop
  the ticker.
- `MorphOrbStyle` for ink, status colours, opaque background, transition
  duration and curve, density and dot scale.
- Continuous size support: tuned at 20 / 32 / 64 px, log-interpolated between.
- Reduced-motion support, semantics labels, single `Ticker` per orb, no
  per-frame widget rebuilds.
