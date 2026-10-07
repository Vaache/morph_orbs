import 'package:flutter_test/flutter_test.dart';
import 'package:morph_orbs/src/animations/orb_presets.dart';
import 'package:morph_orbs/src/models/orb_frame.dart';
import 'package:morph_orbs/morph_orbs.dart';

void main() {
  group('resolveOrbState', () {
    for (final state in MorphOrbState.values) {
      for (final size in const [20.0, 24.0, 40.0, 64.0, 96.0]) {
        test('$state at $size px builds a non-empty frame inside the box', () {
          final resolved = resolveOrbState(state, size);
          final frame = OrbFrame();
          resolved.geometry.build(frame, size, 1.3, resolved.profile, 1);
          expect(frame.length, greaterThan(5));
          for (var i = 0; i < frame.length; i++) {
            expect(frame.x(i), inInclusiveRange(-size * 0.1, size * 1.1));
            expect(frame.y(i), inInclusiveRange(-size * 0.1, size * 1.1));
            expect(
              frame.radius(i),
              greaterThanOrEqualTo(resolved.profile.rMin),
            );
            expect(frame.radius(i).isFinite, isTrue);
          }
        });
      }
    }

    test('dot count grows with size and with density', () {
      int count(double size, {double density = 1}) {
        final resolved = resolveOrbState(
          MorphOrbState.thinking,
          size,
          density: density,
        );
        final frame = OrbFrame();
        resolved.geometry.build(frame, size, 0, resolved.profile, 1);
        return frame.length;
      }

      expect(count(20), lessThan(count(40)));
      expect(count(40), lessThan(count(64)));
      expect(count(64), count(96));
      expect(count(40, density: 2), greaterThan(count(40)));
    });

    test('speed interpolates in log space between tuned sizes', () {
      final small = resolveOrbState(MorphOrbState.thinking, 20);
      final mid = resolveOrbState(MorphOrbState.thinking, 32);
      final between = resolveOrbState(MorphOrbState.thinking, 26);
      expect(
        between.profile.speed,
        inExclusiveRange(mid.profile.speed, small.profile.speed),
      );
    });

    for (final variant in MorphOrbVariant.values) {
      for (final size in const [20.0, 40.0, 64.0]) {
        test('variant $variant at $size px builds a frame inside the box', () {
          final resolved = resolveOrbState(
            MorphOrbState.thinking,
            size,
            variant: variant,
          );
          expect(resolved.spec.kind, OrbGeometryKind.of(variant));
          final frame = OrbFrame();
          for (final t in const [0.0, 0.7, 2.9, 11.3]) {
            resolved.geometry.build(frame, size, t, resolved.profile, 1);
            expect(frame.length, greaterThan(5), reason: 'at t=$t');
            for (var i = 0; i < frame.length; i++) {
              expect(frame.x(i), inInclusiveRange(-size * 0.15, size * 1.15));
              expect(frame.y(i), inInclusiveRange(-size * 0.15, size * 1.15));
              expect(frame.radius(i).isFinite, isTrue);
              expect(frame.alpha(i).isFinite, isTrue);
            }
            for (var i = 0; i < frame.lineCount; i++) {
              final b = i * OrbFrame.lineStride;
              expect(frame.lines[b].isFinite, isTrue);
              expect(frame.lines[b + 6], greaterThan(0));
            }
          }
        });
      }
    }

    test('terminal states ignore the variant', () {
      for (final state in const [
        MorphOrbState.success,
        MorphOrbState.error,
        MorphOrbState.stopped,
      ]) {
        final plain = resolveOrbState(state, 48);
        final overridden = resolveOrbState(
          state,
          48,
          variant: MorphOrbVariant.helix,
        );
        expect(overridden.spec.kind, plain.spec.kind);
      }
    });

    test('idle is a slower, calmer ring than the tuned breathing preset', () {
      final idle = resolveOrbState(MorphOrbState.idle, 64);
      final stopped = resolveOrbState(MorphOrbState.stopped, 64);
      expect(idle.spec.kind, OrbGeometryKind.ring);
      expect(idle.profile.speed, lessThan(3.24));
      expect(idle.profile.wobMul, lessThan(0.368));
      expect(stopped.profile.wobMul, 0);
      expect(stopped.spec.frozen, isTrue);
      expect(stopped.spec.opacity, lessThan(1));
    });

    test('glyphs settle, loops never do', () {
      final check = resolveOrbState(MorphOrbState.success, 64).geometry;
      final cross = resolveOrbState(MorphOrbState.error, 64).geometry;
      final orbits = resolveOrbState(MorphOrbState.thinking, 64).geometry;
      expect(check.isAnimatingAt(0.1), isTrue);
      expect(check.isAnimatingAt(5), isFalse);
      expect(cross.isAnimatingAt(5), isFalse);
      expect(orbits.isAnimatingAt(1000), isTrue);
    });

    test('a frozen ring is identical at any instant', () {
      final stopped = resolveOrbState(MorphOrbState.stopped, 48);
      final a = OrbFrame();
      final b = OrbFrame();
      stopped.geometry.build(a, 48, 0, stopped.profile, 1);
      stopped.geometry.build(b, 48, 7.3, stopped.profile, 1);
      expect(a.length, b.length);
      for (var i = 0; i < a.length; i++) {
        expect(a.x(i), closeTo(b.x(i), 1e-9));
        expect(a.y(i), closeTo(b.y(i), 1e-9));
      }
    });
  });
}
