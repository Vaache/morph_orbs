import 'package:flutter/widgets.dart';

import '../controllers/morph_orb_controller.dart';
import '../models/morph_orb_state.dart';
import '../models/morph_orb_style.dart';
import '../models/morph_orb_variant.dart';
import '../painters/morph_orb_painter.dart';

/// A dotted 3D orb that shows what an assistant is doing. Change [state]
/// and the dots morph into the next geometry; nothing is torn down.
///
/// ```dart
/// MorphOrb(state: MorphOrbState.thinking, size: 48)
/// ```
class MorphOrb extends StatefulWidget {
  const MorphOrb({
    super.key,
    this.state = MorphOrbState.thinking,
    this.variant,
    this.size = 40,
    this.color,
    this.style = const MorphOrbStyle(),
    this.speed = 1,
    this.intensity = 1,
    this.semanticsLabel,
    this.excludeFromSemantics = false,
  }) : assert(size > 0, 'size must be positive'),
       assert(speed > 0, 'speed must be positive'),
       assert(intensity >= 0, 'intensity must not be negative');

  final MorphOrbState state;

  /// Geometry for the continuous states; null uses each state's default
  /// (idle → ring, thinking → orbits, processing → rubik, generating →
  /// ribbon). Terminal states always draw their own glyph.
  final MorphOrbVariant? variant;

  /// Side of the square the orb is drawn in, in logical pixels.
  final double size;

  /// Ink colour; overrides [MorphOrbStyle.color]. Defaults to the
  /// ambient text colour, so the orb follows the surrounding theme.
  final Color? color;

  final MorphOrbStyle style;

  /// Multiplier on every state's tuned tempo.
  final double speed;

  /// Multiplier on deformation amplitude: `0` is a clean, still shape.
  final double intensity;

  /// Replaces the per-state default ("Thinking", "Done", …).
  final String? semanticsLabel;

  /// Set when adjacent text already says what is happening.
  final bool excludeFromSemantics;

  @override
  State<MorphOrb> createState() => _MorphOrbState();
}

class _MorphOrbState extends State<MorphOrb>
    with SingleTickerProviderStateMixin {
  late final MorphOrbController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MorphOrbController(
      vsync: this,
      state: widget.state,
      variant: widget.variant,
      size: widget.size,
      style: _effectiveStyle,
      speed: widget.speed,
      intensity: widget.intensity,
    );
  }

  MorphOrbStyle get _effectiveStyle => widget.color == null
      ? widget.style
      : widget.style.copyWith(color: widget.color);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.update(
      fallbackColor: _ambientColor(context),
      reducedMotion: MediaQuery.maybeDisableAnimationsOf(context) ?? false,
    );
  }

  @override
  void didUpdateWidget(MorphOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.update(
      size: widget.size,
      style: _effectiveStyle,
      speed: widget.speed,
      intensity: widget.intensity,
    );
    if (widget.variant != oldWidget.variant) {
      _controller.setVariant(widget.variant);
    }
    if (widget.state != oldWidget.state) {
      _controller.setState(widget.state);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orb = RepaintBoundary(
      child: CustomPaint(
        size: Size.square(widget.size),
        isComplex: true,
        painter: MorphOrbPainter(controller: _controller),
      ),
    );
    if (widget.excludeFromSemantics) {
      return ExcludeSemantics(child: orb);
    }
    return Semantics(
      label: widget.semanticsLabel ?? widget.state.defaultSemanticsLabel,
      image: true,
      child: orb,
    );
  }

  static Color _ambientColor(BuildContext context) {
    final text = DefaultTextStyle.of(context).style.color;
    if (text != null) {
      return text;
    }
    final icon = IconTheme.of(context).color;
    if (icon != null) {
      return icon;
    }
    final dark =
        MediaQuery.maybePlatformBrightnessOf(context) == Brightness.dark;
    return dark ? const Color(0xFFFFFFFF) : const Color(0xFF171717);
  }
}
