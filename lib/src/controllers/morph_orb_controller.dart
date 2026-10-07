import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../animations/orb_presets.dart';
import '../models/orb_frame.dart';
import '../models/morph_orb_state.dart';
import '../models/morph_orb_style.dart';
import '../models/morph_orb_variant.dart';
import '../utils/orb_math.dart';

/// The static instant drawn under reduced motion, in geometry seconds.
const double kReducedMotionInstant = 0.6;

/// Drives one orb: a single [Ticker], the state machine, and the morph
/// between the outgoing and incoming geometry. Listeners (the painter)
/// are notified per frame; nothing in the widget tree rebuilds.
///
/// The ticker runs only while something moves: it stops once a terminal
/// state has settled, and never runs under reduced motion.
class MorphOrbController extends ChangeNotifier {
  MorphOrbController({
    required TickerProvider vsync,
    MorphOrbState state = MorphOrbState.thinking,
    MorphOrbVariant? variant,
    double size = 40,
    MorphOrbStyle style = const MorphOrbStyle(),
    Color fallbackColor = const Color(0xFFFFFFFF),
    double speed = 1,
    double intensity = 1,
    bool reducedMotion = false,
  }) : _state = state,
       _variant = variant,
       _size = size,
       _style = style,
       _fallbackColor = fallbackColor,
       _speed = speed,
       _intensity = intensity,
       _reducedMotion = reducedMotion {
    _ticker = vsync.createTicker(_onTick);
    _current = _resolve(state);
    _ensureTicking();
  }

  late final Ticker _ticker;

  MorphOrbState _state;
  MorphOrbVariant? _variant;
  MorphOrbState? _previousState;
  MorphOrbVariant? _previousVariant;
  late ResolvedOrbState _current;
  ResolvedOrbState? _previous;

  double _size;
  MorphOrbStyle _style;
  Color _fallbackColor;
  double _speed;
  double _intensity;
  bool _reducedMotion;

  double _clock = 0;
  double _clockAtStart = 0;
  double _stateEnteredAt = 0;
  double _previousEnteredAt = 0;
  double _transitionStartedAt = 0;
  bool _fromSnapshot = false;
  bool _disposed = false;

  final OrbFrame _fromFrame = OrbFrame();
  final OrbFrame _toFrame = OrbFrame();
  final OrbFrame _outFrame = OrbFrame();
  final OrbFrame _snapshot = OrbFrame();

  MorphOrbState get state => _state;

  /// The geometry override for continuous states, or null for the
  /// state's default.
  MorphOrbVariant? get variant => _variant;
  MorphOrbState? get previousState => _previousState;
  double get size => _size;
  MorphOrbStyle get style => _style;
  double get speed => _speed;
  double get intensity => _intensity;
  bool get reducedMotion => _reducedMotion;
  bool get isTicking => _ticker.isActive;

  /// Seconds of orb time elapsed, across ticker stops and starts.
  double get elapsed => _clock;

  bool get isTransitioning => _previous != null;

  /// 0..1 progress of the current transition, eased; 1 when none runs.
  double get transitionProgress {
    if (_previous == null) {
      return 1;
    }
    final ms = _style.transitionDuration.inMicroseconds / 1e6;
    if (ms <= 0) {
      return 1;
    }
    return _style.transitionCurve.transform(
      clamp01((_clock - _transitionStartedAt) / ms),
    );
  }

  double get _localTime => _clock - _stateEnteredAt;

  /// Moves to [next], morphing from the current dots. A change mid-transition
  /// morphs from where the dots are now rather than restarting.
  void setState(MorphOrbState next) {
    if (next == _state) {
      return;
    }
    _retarget(next, _variant);
  }

  /// Swaps the geometry of the continuous states, morphing like a state
  /// change. A terminal state keeps drawing its glyph and picks the new
  /// variant up when it leaves.
  void setVariant(MorphOrbVariant? next) {
    if (next == _variant) {
      return;
    }
    if (_state.isTerminal) {
      _variant = next;
      return;
    }
    _retarget(_state, next);
  }

  void _retarget(MorphOrbState state, MorphOrbVariant? variant) {
    if (_previous != null) {
      _snapshot.copyFrom(_outFrame);
      _fromSnapshot = true;
    } else {
      _fromSnapshot = false;
    }
    _previous = _current;
    _previousState = _state;
    _previousVariant = _variant;
    _previousEnteredAt = _stateEnteredAt;
    _state = state;
    _variant = variant;
    _current = _resolve(state);
    _stateEnteredAt = _clock;
    _transitionStartedAt = _clock;
    if (_reducedMotion) {
      _finishTransition();
    }
    _ensureTicking();
    notifyListeners();
  }

  void update({
    double? size,
    MorphOrbStyle? style,
    Color? fallbackColor,
    double? speed,
    double? intensity,
    bool? reducedMotion,
  }) {
    var changed = false;
    if (fallbackColor != null && fallbackColor != _fallbackColor) {
      _fallbackColor = fallbackColor;
      changed = true;
    }
    if (speed != null && speed != _speed) {
      _speed = speed;
      changed = true;
    }
    if (intensity != null && intensity != _intensity) {
      _intensity = intensity;
      changed = true;
    }
    final resolveAgain =
        (size != null && size != _size) ||
        (style != null &&
            (style.density != _style.density ||
                style.dotScale != _style.dotScale));
    if (size != null) {
      _size = size;
    }
    if (style != null && style != _style) {
      _style = style;
      changed = true;
    }
    if (resolveAgain) {
      _current = _resolve(_state);
      if (_previousState != null && !_fromSnapshot) {
        _previous = _resolve(_previousState!, _previousVariant);
      }
      changed = true;
    }
    if (reducedMotion != null && reducedMotion != _reducedMotion) {
      _reducedMotion = reducedMotion;
      if (reducedMotion) {
        _finishTransition();
      }
      changed = true;
    }
    if (changed) {
      _ensureTicking();
      notifyListeners();
    }
  }

  /// The ink for this instant, lerped across a transition.
  Color inkColor() {
    final to = _style.colorFor(_state) ?? _fallbackColor;
    final previous = _previousState;
    if (previous == null) {
      return to;
    }
    final from = _style.colorFor(previous) ?? _fallbackColor;
    return Color.lerp(from, to, transitionProgress) ?? to;
  }

  /// Builds and returns the dots to draw for an orb of [size] now. The
  /// frame is a reused buffer, valid until the next call.
  OrbFrame render(double size) {
    if (size != _size) {
      _size = size;
      _current = _resolve(_state);
      if (_previousState != null && !_fromSnapshot) {
        _previous = _resolve(_previousState!, _previousVariant);
      }
    }
    _buildFrame(_current, _stateEnteredAt, _toFrame);
    final previous = _previous;
    if (previous == null) {
      _outFrame.copyFrom(_toFrame);
    } else {
      final progress = transitionProgress;
      if (progress >= 1) {
        _finishTransition();
        _outFrame.copyFrom(_toFrame);
      } else {
        if (_fromSnapshot) {
          _fromFrame.copyFrom(_snapshot);
        } else {
          _buildFrame(previous, _previousEnteredAt, _fromFrame);
        }
        OrbFrame.blend(_fromFrame, _toFrame, progress, _outFrame);
      }
    }
    _outFrame.sortByDepth();
    return _outFrame;
  }

  void _buildFrame(ResolvedOrbState resolved, double enteredAt, OrbFrame out) {
    final spec = resolved.spec;
    final double t;
    if (_reducedMotion) {
      t = kReducedMotionInstant;
    } else if (spec.frozen) {
      t = 0;
    } else if (resolved.state.isTerminal) {
      t = (_clock - enteredAt) * _speed;
    } else {
      t = _clock * resolved.profile.speed * _speed;
    }
    resolved.geometry.build(out, _size, t, resolved.profile, _intensity);
    final center = _size / 2;
    out
      ..scaleAbout(center, center, spec.scale)
      ..multiplyAlpha(spec.opacity);
  }

  ResolvedOrbState _resolve(MorphOrbState state, [MorphOrbVariant? variant]) =>
      resolveOrbState(
        state,
        _size,
        variant: identical(state, _state) && variant == null
            ? _variant
            : variant,
        density: _style.density,
        dotScale: _style.dotScale,
      );

  void _finishTransition() {
    _previous = null;
    _previousState = null;
    _previousVariant = null;
    _fromSnapshot = false;
  }

  bool get _needsTicking {
    if (_reducedMotion) {
      return false;
    }
    if (_previous != null) {
      return true;
    }
    final spec = _current.spec;
    if (spec.frozen) {
      return false;
    }
    if (_state.isTerminal) {
      return _current.geometry.isAnimatingAt(_localTime * _speed);
    }
    return true;
  }

  void _ensureTicking() {
    if (_disposed) {
      return;
    }
    final needs = _needsTicking;
    if (needs && !_ticker.isActive) {
      _clockAtStart = _clock;
      _ticker.start();
    } else if (!needs && _ticker.isActive) {
      _ticker.stop();
    }
  }

  void _onTick(Duration sinceStart) {
    _clock = _clockAtStart + sinceStart.inMicroseconds / 1e6;
    if (_previous != null && transitionProgress >= 1) {
      _finishTransition();
    }
    notifyListeners();
    if (!_needsTicking) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker.dispose();
    super.dispose();
  }
}
