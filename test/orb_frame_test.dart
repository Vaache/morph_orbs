import 'package:flutter_test/flutter_test.dart';
import 'package:morph_orbs/src/models/orb_frame.dart';

void main() {
  group('OrbFrame', () {
    test('grows past its initial capacity', () {
      final frame = OrbFrame(capacity: 2);
      for (var i = 0; i < 10; i++) {
        frame.add(i.toDouble(), 0, 0, 1, 0);
      }
      expect(frame.length, 10);
      expect(frame.x(9), 9);
    });

    test('drops invisible dots', () {
      final frame = OrbFrame()..add(0, 0, 0, 1, 0, 0.01);
      expect(frame.isEmpty, isTrue);
    });

    test('sorts far to near', () {
      final frame = OrbFrame()
        ..add(0, 0, 0.5, 1, 0)
        ..add(0, 0, -1, 1, 0)
        ..add(0, 0, 0.2, 1, 0)
        ..sortByDepth();
      expect(frame.order, [1, 2, 0]);
    });

    test('order is empty until sorted', () {
      final frame = OrbFrame()..add(0, 0, 0, 1, 0);
      expect(frame.order, isEmpty);
      frame.sortByDepth();
      expect(frame.order, hasLength(1));
      frame.add(1, 1, 1, 1, 0);
      expect(frame.order, isEmpty);
    });

    test('clamps radii and scales about a centre', () {
      final frame = OrbFrame()
        ..add(10, 10, 0, 0.1, 0)
        ..clampRadius(0.3)
        ..scaleAbout(0, 0, 2);
      expect(frame.radius(0), 0.6);
      expect(frame.x(0), 20);
      expect(frame.y(0), 20);
    });

    test('blend maps indices across different counts', () {
      final from = OrbFrame()
        ..add(0, 0, 0, 1, 0)
        ..add(10, 10, 0, 1, 0);
      final to = OrbFrame()
        ..add(100, 100, 0, 3, 1)
        ..add(100, 100, 0, 3, 1)
        ..add(100, 100, 0, 3, 1)
        ..add(100, 100, 0, 3, 1);
      final out = OrbFrame();
      OrbFrame.blend(from, to, 0.5, out, stagger: 0);
      expect(out.length, 4);
      for (var i = 0; i < out.length; i++) {
        expect(out.x(i), 50 + (i < 2 ? 0 : 5));
        expect(out.radius(i), 2);
        expect(out.ink(i), 0.5);
      }
    });

    test('blend ends exactly on the target and starts on the source', () {
      final from = OrbFrame()..add(0, 0, 0, 1, 0);
      final to = OrbFrame()..add(5, 5, 5, 2, 1);
      final out = OrbFrame();
      OrbFrame.blend(from, to, 0, out);
      expect(out.x(0), 0);
      OrbFrame.blend(from, to, 1, out);
      expect(out.x(0), 5);
      expect(out.z(0), 5);
    });

    test('blend with an empty source copies the target', () {
      final to = OrbFrame()..add(5, 5, 5, 2, 1);
      final out = OrbFrame();
      OrbFrame.blend(OrbFrame(), to, 0.3, out);
      expect(out.length, 1);
      expect(out.x(0), 5);
    });
  });
}
