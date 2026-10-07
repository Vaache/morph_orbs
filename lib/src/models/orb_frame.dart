import 'dart:typed_data';

import '../utils/orb_math.dart';

/// One rendered instant: a reusable, growable buffer of dots. Each dot is
/// `stride` doubles — x, y, z, radius, ink (0 = full ink, 1 = none), alpha.
/// [order] holds the indices sorted far → near after [sortByDepth].
class OrbFrame {
  OrbFrame({int capacity = 512}) : _data = Float64List(capacity * stride);

  static const int stride = 6;
  static const int _ox = 0;
  static const int _oy = 1;
  static const int _oz = 2;
  static const int _or = 3;
  static const int _oInk = 4;
  static const int _oAlpha = 5;

  static const int lineStride = 7;

  Float64List _data;
  int _length = 0;
  Float64List _lines = Float64List(16 * lineStride);
  int _lineCount = 0;
  Uint32List _order = Uint32List(0);
  Uint32List _orderView = Uint32List(0);
  int _sortedLength = 0;

  int get length => _length;
  bool get isEmpty => _length == 0;
  Float64List get data => _data;

  /// Stroked edges drawn under the dots: x1, y1, x2, y2, ink, alpha, width.
  int get lineCount => _lineCount;
  Float64List get lines => _lines;

  Uint32List get order => _sortedLength == _length
      ? _orderView
      : Uint32List.sublistView(_order, 0, 0);

  double x(int i) => _data[i * stride + _ox];
  double y(int i) => _data[i * stride + _oy];
  double z(int i) => _data[i * stride + _oz];
  double radius(int i) => _data[i * stride + _or];
  double ink(int i) => _data[i * stride + _oInk];
  double alpha(int i) => _data[i * stride + _oAlpha];

  void clear() {
    _length = 0;
    _lineCount = 0;
    _sortedLength = -1;
  }

  void addLine(
    double x1,
    double y1,
    double x2,
    double y2,
    double ink,
    double alpha,
    double width,
  ) {
    if (alpha < 0.02) {
      return;
    }
    final base = _lineCount * lineStride;
    if (base + lineStride > _lines.length) {
      final grown = Float64List(_lines.length * 2);
      grown.setAll(0, _lines);
      _lines = grown;
    }
    _lines[base] = x1;
    _lines[base + 1] = y1;
    _lines[base + 2] = x2;
    _lines[base + 3] = y2;
    _lines[base + 4] = ink;
    _lines[base + 5] = alpha;
    _lines[base + 6] = width;
    _lineCount++;
  }

  void _appendLines(OrbFrame other, double alphaFactor) {
    for (var i = 0; i < other._lineCount; i++) {
      final b = i * lineStride;
      final l = other._lines;
      addLine(
        l[b],
        l[b + 1],
        l[b + 2],
        l[b + 3],
        l[b + 4],
        l[b + 5] * alphaFactor,
        l[b + 6],
      );
    }
  }

  void add(
    double x,
    double y,
    double z,
    double radius,
    double ink, [
    double alpha = 1,
  ]) {
    if (alpha < 0.02) {
      return;
    }
    final base = _length * stride;
    if (base + stride > _data.length) {
      final grown = Float64List(_data.length * 2);
      grown.setAll(0, _data);
      _data = grown;
    }
    _data[base + _ox] = x;
    _data[base + _oy] = y;
    _data[base + _oz] = z;
    _data[base + _or] = radius;
    _data[base + _oInk] = ink;
    _data[base + _oAlpha] = alpha;
    _length++;
    _sortedLength = -1;
  }

  void clampRadius(double rMin) {
    for (var i = 0; i < _length; i++) {
      final at = i * stride + _or;
      if (_data[at] < rMin) {
        _data[at] = rMin;
      }
    }
  }

  void scaleAbout(double cx, double cy, double scale) {
    if (scale == 1) {
      return;
    }
    for (var i = 0; i < _length; i++) {
      final base = i * stride;
      _data[base + _ox] = cx + (_data[base + _ox] - cx) * scale;
      _data[base + _oy] = cy + (_data[base + _oy] - cy) * scale;
      _data[base + _or] *= scale;
    }
    for (var i = 0; i < _lineCount; i++) {
      final base = i * lineStride;
      _lines[base] = cx + (_lines[base] - cx) * scale;
      _lines[base + 1] = cy + (_lines[base + 1] - cy) * scale;
      _lines[base + 2] = cx + (_lines[base + 2] - cx) * scale;
      _lines[base + 3] = cy + (_lines[base + 3] - cy) * scale;
      _lines[base + 6] *= scale;
    }
  }

  void multiplyAlpha(double factor) {
    if (factor == 1) {
      return;
    }
    for (var i = 0; i < _length; i++) {
      _data[i * stride + _oAlpha] *= factor;
    }
    for (var i = 0; i < _lineCount; i++) {
      _lines[i * lineStride + 5] *= factor;
    }
  }

  void translate(double dx, double dy) {
    if (dx == 0 && dy == 0) {
      return;
    }
    for (var i = 0; i < _length; i++) {
      final base = i * stride;
      _data[base + _ox] += dx;
      _data[base + _oy] += dy;
    }
  }

  void copyFrom(OrbFrame other) {
    final needed = other._length * stride;
    if (_data.length < needed) {
      _data = Float64List(needed);
    }
    _data.setRange(0, needed, other._data);
    _length = other._length;
    _sortedLength = -1;
    _lineCount = 0;
    _appendLines(other, 1);
  }

  void sortByDepth() {
    if (_sortedLength == _length) {
      return;
    }
    if (_order.length < _length) {
      _order = Uint32List(_length);
    }
    final view = Uint32List.sublistView(_order, 0, _length);
    for (var i = 0; i < _length; i++) {
      view[i] = i;
    }
    final data = _data;
    view.sort(
      (a, b) => data[a * stride + _oz].compareTo(data[b * stride + _oz]),
    );
    _orderView = view;
    _sortedLength = _length;
  }

  /// Writes the index-mapped morph of [from] into [to] at [progress] into
  /// [out]. Dots leave in a staggered wave ([stagger] of the progress span)
  /// so the change reads as a flow rather than a slide. Lines cross-fade.
  static void blend(
    OrbFrame from,
    OrbFrame to,
    double progress,
    OrbFrame out, {
    double stagger = 0.35,
  }) {
    out.clear();
    if (from.isEmpty || progress >= 1) {
      out.copyFrom(to);
      return;
    }
    if (to.isEmpty || progress <= 0) {
      out.copyFrom(from);
      return;
    }
    final na = from._length;
    final nb = to._length;
    final n = na > nb ? na : nb;
    final a = from._data;
    final b = to._data;
    for (var k = 0; k < n; k++) {
      final ia = (k * na ~/ n) * stride;
      final ib = (k * nb ~/ n) * stride;
      final offset = stagger * hashD(k.toDouble(), 3.7);
      final f = smoothStep((progress * (1 + stagger) - offset) / 1);
      out.add(
        lerp(a[ia + _ox], b[ib + _ox], f),
        lerp(a[ia + _oy], b[ib + _oy], f),
        lerp(a[ia + _oz], b[ib + _oz], f),
        lerp(a[ia + _or], b[ib + _or], f),
        lerp(a[ia + _oInk], b[ib + _oInk], f),
        lerp(a[ia + _oAlpha], b[ib + _oAlpha], f),
      );
    }
    out._appendLines(from, 1 - progress);
    out._appendLines(to, progress);
  }
}
