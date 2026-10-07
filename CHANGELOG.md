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
