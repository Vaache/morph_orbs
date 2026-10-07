import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morph_orbs/morph_orbs.dart';

/// Renders the README media frame by frame. Skipped unless `ORB_MEDIA_DIR`
/// points at a directory to write into; `tool/render_media.sh` assembles
/// the frames into GIF / MP4.
void main() {
  final dir = Platform.environment['ORB_MEDIA_DIR'];
  const bg = Color(0xFF0B0B0C);
  const ink = Color(0xFFF2F2F2);
  const fps = 24;
  const frame = Duration(microseconds: 1000000 ~/ fps);
  final key = GlobalKey();

  Future<void> snap(WidgetTester tester, String path) async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await tester.runAsync(() => boundary.toImage(pixelRatio: 2));
    final bytes = await tester.runAsync(
      () => image!.toByteData(format: ui.ImageByteFormat.png),
    );
    File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
  }

  Widget stage(Size size, Widget child) => RepaintBoundary(
    key: key,
    child: SizedBox.fromSize(
      size: size,
      child: ColoredBox(
        color: bg,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(child: child),
        ),
      ),
    ),
  );

  Widget orb(
    MorphOrbState state, {
    MorphOrbVariant? variant,
    double size = 160,
  }) => MorphOrb(
    key: const ValueKey('orb'),
    state: state,
    variant: variant,
    size: size,
    color: ink,
    style: const MorphOrbStyle(
      successColor: Color(0xFF6EE7A8),
      errorColor: Color(0xFFFF6B6B),
    ),
  );

  Future<void> sequence(
    WidgetTester tester,
    String name,
    Size size,
    List<(Widget, Duration)> steps,
  ) async {
    final out = Directory('$dir/$name')..createSync(recursive: true);
    tester.view.physicalSize = size;
    var n = 0;
    for (final (child, hold) in steps) {
      await tester.pumpWidget(stage(size, child));
      final frames = hold.inMicroseconds ~/ frame.inMicroseconds;
      for (var f = 0; f < frames; f++) {
        await tester.pump(frame);
        await snap(tester, '${out.path}/${n.toString().padLeft(4, '0')}.png');
        n++;
      }
    }
    await tester.pumpWidget(const SizedBox());
  }

  testWidgets('flow: idle → thinking → processing → generating → success', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await sequence(tester, 'flow', const Size(240, 240), [
      (orb(MorphOrbState.idle), const Duration(milliseconds: 1400)),
      (orb(MorphOrbState.thinking), const Duration(milliseconds: 2400)),
      (orb(MorphOrbState.processing), const Duration(milliseconds: 2400)),
      (orb(MorphOrbState.generating), const Duration(milliseconds: 2600)),
      (orb(MorphOrbState.success), const Duration(milliseconds: 2000)),
    ]);
  }, skip: dir == null);

  testWidgets('fail-stop: thinking → error, thinking → stopped', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await sequence(tester, 'failstop', const Size(240, 240), [
      (orb(MorphOrbState.thinking), const Duration(milliseconds: 1800)),
      (orb(MorphOrbState.error), const Duration(milliseconds: 2200)),
      (orb(MorphOrbState.thinking), const Duration(milliseconds: 1800)),
      (orb(MorphOrbState.stopped), const Duration(milliseconds: 2000)),
    ]);
  }, skip: dir == null);

  testWidgets('variant morphs', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    const order = [
      MorphOrbVariant.orbits,
      MorphOrbVariant.swarm,
      MorphOrbVariant.helix,
      MorphOrbVariant.bloom,
      MorphOrbVariant.constellate,
      MorphOrbVariant.vortex,
      MorphOrbVariant.ribbon,
    ];
    await sequence(tester, 'morphs', const Size(240, 240), [
      for (final v in order)
        (
          orb(MorphOrbState.thinking, variant: v),
          const Duration(milliseconds: 1700),
        ),
    ]);
  }, skip: dir == null);

  testWidgets('variants grid', (tester) async {
    const cell = 150.0;
    const cols = 6;
    final rows = (MorphOrbVariant.values.length / cols).ceil();
    tester.view.physicalSize = Size(cell * cols, cell * rows);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final grid = Wrap(
      children: [
        for (final v in MorphOrbVariant.values)
          SizedBox(
            width: cell,
            height: cell,
            child: Center(
              child: MorphOrb(variant: v, size: 88, color: ink),
            ),
          ),
      ],
    );
    await sequence(tester, 'variants', Size(cell * cols, cell * rows), [
      (SizedBox(width: cell * cols, child: grid), const Duration(seconds: 5)),
    ]);
  }, skip: dir == null);

  testWidgets('states row', (tester) async {
    const cell = 150.0;
    tester.view.physicalSize = Size(cell * MorphOrbState.values.length, cell);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final s in MorphOrbState.values)
          SizedBox(
            width: cell,
            height: cell,
            child: Center(
              child: MorphOrb(
                state: s,
                size: 88,
                color: ink,
                style: const MorphOrbStyle(
                  successColor: Color(0xFF6EE7A8),
                  errorColor: Color(0xFFFF6B6B),
                ),
              ),
            ),
          ),
      ],
    );
    await sequence(
      tester,
      'states',
      Size(cell * MorphOrbState.values.length, cell),
      [(row, const Duration(seconds: 4))],
    );
  }, skip: dir == null);
}
