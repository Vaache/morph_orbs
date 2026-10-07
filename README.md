# morph_orbs

Dotted 3D "thinking orb" indicators for AI chat interfaces. Seven states,
seventeen geometries, and smooth dot-for-dot morphs between any of them. Plain `Canvas` circles: no shaders, no blur, no layers, no
dependencies beyond Flutter.

The visual concept and the tuned geometries follow
[thinking-orbs](https://github.com/Jakubantalik/Libraries.dev) by Jakub
Antalik (MIT), re-implemented natively for Flutter. See `LICENSE`.

## Installation

```yaml
dependencies:
  morph_orbs: ^0.1.0
```

```dart
import 'package:morph_orbs/morph_orbs.dart';
```

## Basic usage

```dart
MorphOrb(
  state: MorphOrbState.thinking,
  size: 48,
)
```

Change `state` on rebuild and the orb morphs into the next geometry. The
widget keeps one controller and one ticker for its whole life; nothing is
torn down between states.

```dart
MorphOrb(
  state: isStreaming ? MorphOrbState.generating : MorphOrbState.thinking,
  size: 40,
)
```

## States

| State        | Motion                                                        | Fits                              |
| ------------ | ------------------------------------------------------------- | --------------------------------- |
| `idle`       | A face-on dotted ring, breathing very slowly                  | Ready, waiting for input          |
| `thinking`   | Particles on tilted orbits over faint ghost paths; slow spin  | Reasoning, "Thinking…"            |
| `processing` | Latitude bands twist in quarter turns, scramble, click back   | Tool calls, lookups, code running |
| `generating` | An undulating multi-band sash                                 | Streaming a reply                 |
| `success`    | Dots gather into a check and bloom once, then hold            | Reply finished                    |
| `error`      | A decaying shudder and scatter, then dots snap onto a cross   | Request failed                    |
| `stopped`    | Frozen, dimmed, slightly smaller ring                         | User cancelled                    |

`success`, `error` and `stopped` are terminal: they settle and then the
ticker stops. The continuous states loop.

### Variants

A continuous state renders with its default geometry (above). Pass
`variant:` to pick another; terminal states keep their glyphs.

```dart
MorphOrb(state: MorphOrbState.thinking, variant: MorphOrbVariant.swarm)
```

| Variant       | Motion                                                         |
| ------------- | -------------------------------------------------------------- |
| `orbits`      | particles on tilted orbits over ghost paths                    |
| `ring`        | face-on ring, radius undulating                                |
| `ribbon`      | undulating multi-band sash                                     |
| `rubik`       | bands twist in quarter turns, scramble, click back             |
| `globe`       | scan meridian sweeps a dotted globe                            |
| `wave`        | waveform rolls through latitude rings                          |
| `web`         | constellation wires itself, packets on the edges               |
| `braid`       | three strands plait around the sphere                          |
| `morph`       | dotted outline: circle → triangle → square                     |
| `pulse`       | concentric rings radiate from a beating core                   |
| `swarm`       | a flock skims an invisible sphere                              |
| `helix`       | double helix turns, rungs flicker                              |
| `nebula`      | soft noise cloud, dots breathing                               |
| `vortex`      | spiral arms sink into a funnel                                 |
| `echo`        | sonar ring lights the dots it passes                           |
| `constellate` | stars join into a figure, hold, let go                         |
| `bloom`       | dotted rose opens and closes its petals                        |

Changing `variant` morphs exactly like a state change.

### Transitions

Every state produces a list of dots. On a state change the controller
builds both the outgoing and the incoming geometry each frame and lerps
them dot-for-dot (position, depth, radius, ink), staggered so the change
reads as a flow. Changing state again mid-transition morphs from where the
dots are now. The default is 650 ms on `Curves.easeInOutCubic`.

```text
idle → thinking → processing → generating → success
                  thinking → error
                  thinking → stopped
```

## Customization

```dart
MorphOrb(
  state: state,
  size: 64,
  color: theme.textPrimary,       // ink; defaults to the ambient text colour
  speed: 1.0,                     // tempo multiplier
  intensity: 1.0,                 // deformation amplitude; 0 is a still shape
  semanticsLabel: 'Drafting…',    // replaces the per-state default
  style: MorphOrbStyle(
    successColor: theme.statusSuccess,
    errorColor: theme.statusError,
    backgroundColor: theme.bgSurface, // far dots fade toward this, not alpha
    transitionDuration: Duration(milliseconds: 650),
    transitionCurve: Curves.easeInOutCubic,
    density: 1.0,                   // dot count multiplier
    dotScale: 1.0,                  // dot radius multiplier
  ),
)
```

- **Ink**: `color` wins over `style.color`, which wins over the ambient
  `DefaultTextStyle` colour. Depth shading fades the ink toward transparent,
  so the orb works over any surface, including glass. Set
  `style.backgroundColor` on a known solid surface for opaque occlusion.
- **Sizes**: 20, 32 and 64 px are tuned points (count, dot radius, tempo);
  anything between is log-interpolated, anything beyond keeps the nearest
  tuning and scales the mark sub-linearly. 24 / 40 / 64 all read well.
- **Reduced motion**: with `MediaQuery.disableAnimations` the orb draws one
  static representative frame, switches states instantly and never ticks.
- **Semantics**: `Semantics(image: true, label: …)` with a per-state default;
  pass `excludeFromSemantics: true` when adjacent text already says it.

## Example

`example/` is a gallery: every state and variant, an interactive stage with
a scripted reply flow, and the size row.

```bash
cd example && flutter run
```

## Architecture

```text
lib/
├── morph_orbs.dart                 public exports
└── src/
    ├── models/
    │   ├── morph_orb_state.dart    the seven states
    │   ├── morph_orb_style.dart    colours, transition, density, dot scale
    │   └── orb_frame.dart             reusable Float64List dot buffer, z-sort, blend
    ├── animations/
    │   ├── orb_geometry.dart          build(out, size, t, profile, intensity)
    │   ├── orb_profile.dart           typed density / radius tuning + scalers
    │   ├── orb_presets.dart           state → geometry, tuned sizes, resolver
    │   └── geometries/                orbits · rubik · ribbon (+ ring) · glyph
    ├── controllers/
    │   └── morph_orb_controller.dart  Ticker, clock, state machine, morph
    ├── painters/
    │   └── morph_orb_painter.dart  CustomPainter, repaint: controller
    ├── widgets/
    │   └── morph_orb.dart             the public widget
    └── utils/
        └── orb_math.dart              hash, noise, Fibonacci sphere, projector
```

Geometry is pure: `(size, t, profile) → dots`, no colour and no canvas.
The controller owns time and transitions; the painter only draws what the
controller hands it. The widget is a thin `StatefulWidget` that maps props
onto the controller.

## Performance

- One `Ticker` per orb, created through the widget's `TickerProvider`, so
  `TickerMode` mutes it on inactive routes. It stops entirely once a
  terminal state has settled and never runs under reduced motion.
- No `setState` per frame: the ticker notifies the `CustomPainter` through
  `repaint:` and only the orb's own `RepaintBoundary` repaints.
- Dots live in reusable `Float64List` buffers (6 doubles per dot); a frame
  allocates nothing beyond the per-dot `Color`. Sorting reuses an index
  buffer.
- Drawing is `drawCircle` (and `drawLine` for the few edge-based variants)
  with one reused `Paint` each: 100–600 marks per frame depending on size,
  trivial for Skia and Impeller. No `saveLayer`, no blur,
  no shaders, so there is no shader-compilation jank on first frame.
- Transitions cost two geometry builds per frame for their duration only.

A `FragmentShader` was considered and rejected: the signature of the look is
discrete depth-shaded dots, which `drawCircle` renders exactly; a shader
would add compile cost and a platform-specific asset for no visual gain.

## Testing

```bash
flutter test
```

Tests cover the dot buffer and morph, every state at every size, preset
interpolation, the controller's state machine (transitions, interruption,
ticker lifecycle, reduced motion, disposal) and the widget (rendering,
semantics, ambient colour, controller reuse, disposal). The optional
`test/preview/render_preview_test.dart` dumps PNG frames when
`ORB_PREVIEW_DIR` is set, for eyeballing changes.
