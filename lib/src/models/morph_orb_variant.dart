/// The geometry a continuous state renders with. Each variant is its own
/// hand-tuned animation; any two morph into each other dot-for-dot.
enum MorphOrbVariant {
  /// Particles on tilted orbits over faint ghost paths.
  orbits,

  /// A face-on dotted ring whose radius undulates.
  ring,

  /// An undulating multi-band sash on a great circle.
  ribbon,

  /// Latitude bands twist in quarter turns, scramble, click back.
  rubik,

  /// A scan meridian sweeps a dotted globe.
  globe,

  /// A waveform rolls through latitude rings.
  wave,

  /// A constellation wires itself; packets run along its edges.
  web,

  /// Three strands plait around the sphere.
  braid,

  /// A dotted outline morphs circle → triangle → square.
  morph,

  /// Concentric rings radiate from a beating core.
  pulse,

  /// A flock skims an invisible sphere.
  swarm,

  /// Two strands wind around an axis; rungs flicker between them.
  helix,

  /// A soft noise cloud, dots breathing on their own tempo.
  nebula,

  /// Dots spiral inward and sink into a funnel.
  vortex,

  /// A sonar ring sweeps a dim sphere, lighting the dots it passes.
  echo,

  /// Stars join into a figure, hold it, and let it go.
  constellate,

  /// A dotted rose curve opens and closes its petals.
  bloom,
}
