import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morph_orbs/morph_orbs.dart';

/// Dumps PNG frames of every state for eyeballing. Skipped unless
/// `ORB_PREVIEW_DIR` points at a directory to write into.
void main() {
  final dir = Platform.environment['ORB_PREVIEW_DIR'];

  testWidgets('renders preview frames', (tester) async {
    tester.view.physicalSize = const Size(900, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey();

    Future<void> dump(
      String name,
      MorphOrbState state, [
      MorphOrbVariant? variant,
    ]) async {
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: ColoredBox(
            color: const Color(0xFF111111),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (final size in const [24.0, 40.0, 64.0, 120.0])
                    MorphOrb(
                      state: state,
                      variant: variant,
                      size: size,
                      color: const Color(0xFFFFFFFF),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      for (final ms in const [0, 350, 700, 1400]) {
        await tester.pump(Duration(milliseconds: ms));
        await tester.pump();
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await tester.runAsync(
          () => boundary.toImage(pixelRatio: 3),
        );
        final bytes = await tester.runAsync(
          () => image!.toByteData(format: ui.ImageByteFormat.png),
        );
        File(
          '$dir/$name-$ms.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
      }
    }

    for (final state in MorphOrbState.values) {
      await dump(state.name, state);
    }
    for (final variant in MorphOrbVariant.values) {
      await dump('v-${variant.name}', MorphOrbState.thinking, variant);
    }
    await tester.pumpWidget(const SizedBox());
  }, skip: dir == null);
}
