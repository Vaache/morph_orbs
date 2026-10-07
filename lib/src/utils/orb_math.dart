import 'dart:math' as math;

const double kTau = math.pi * 2;

double lerp(double a, double b, double f) => a + (b - a) * f;

double frac(double x) => x - x.floorToDouble();

double clamp01(double x) => x < 0 ? 0 : (x > 1 ? 1 : x);

double smoothStep(double x) {
  final c = clamp01(x);
  return c * c * (3 - 2 * c);
}

/// Deterministic hash in [0, 1).
double hashD(double a, double b) {
  final h = math.sin(a * 12.9898 + b * 78.233) * 43758.5453;
  return h - h.floorToDouble();
}

/// Value noise on a 2D lattice — smooth, deterministic, cheap.
double vnoise(double x, double y) {
  final xi = x.floorToDouble();
  final yi = y.floorToDouble();
  var fx = x - xi;
  var fy = y - yi;
  fx = fx * fx * (3 - 2 * fx);
  fy = fy * fy * (3 - 2 * fy);
  final a = hashD(xi, yi);
  final b = hashD(xi + 1, yi);
  final c = hashD(xi, yi + 1);
  final d = hashD(xi + 1, yi + 1);
  return a + (b - a) * fx + (c - a) * fy + (a - b - c + d) * fx * fy;
}

/// Shortest signed angular distance, wrapped to (-π, π].
double angleDelta(double a, double b) =>
    math.atan2(math.sin(a - b), math.cos(a - b));

/// Dot radii were tuned for a 300pt frame; sub-linear scaling keeps small
/// orbs legible.
double radiusScale(double size, double pow) =>
    math.pow(size / 300, pow).toDouble();

/// Interpolates ratios in log space, so a multiplier halfway between 1 and 4
/// is 2, not 2.5.
double lerpLog(double a, double b, double f) =>
    math.exp(lerp(math.log(a), math.log(b), f));

/// Stable directions on a unit sphere (Fibonacci lattice), written to [out].
void fibDir(int i, int n, Vec3 out) {
  const golden = math.pi * (3 - 2.23606797749979);
  final y = 1 - (2 * (i + 0.5)) / n;
  final rad = math.sqrt(math.max(0, 1 - y * y));
  final a = i * golden;
  out
    ..x = rad * math.cos(a)
    ..y = y
    ..z = rad * math.sin(a);
}

class Vec3 {
  double x = 0;
  double y = 0;
  double z = 0;
}

/// Spin + tilt + orthographic projection. Mutable scratch output avoids a
/// list allocation per projected point.
class Projector {
  Projector(double yaw, double tilt, this.cx, this.cy, this.scale)
    : _st = math.sin(tilt),
      _ct = math.cos(tilt),
      _sy = math.sin(yaw),
      _cyw = math.cos(yaw);

  final double cx;
  final double cy;
  final double scale;
  final double _st;
  final double _ct;
  final double _sy;
  final double _cyw;

  double px = 0;
  double py = 0;
  double pz = 0;

  void project(double x, double y, double z) {
    final x1 = x * _cyw + z * _sy;
    final z1 = -x * _sy + z * _cyw;
    final y1 = y * _ct - z1 * _st;
    px = cx + x1 * scale;
    py = cy - y1 * scale;
    pz = y * _st + z1 * _ct;
  }
}
