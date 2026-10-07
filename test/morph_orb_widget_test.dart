import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morph_orbs/morph_orbs.dart';

Widget _host(Widget child, {bool reduced = false}) => Directionality(
  textDirection: TextDirection.ltr,
  child: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: DefaultTextStyle(
      style: const TextStyle(color: Color(0xFF123456)),
      child: Center(child: child),
    ),
  ),
);

void main() {
  group('MorphOrb', () {
    testWidgets('renders a square CustomPaint of the given size', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const MorphOrb(size: 48)));
      final paint = tester.widget<CustomPaint>(find.byType(CustomPaint));
      expect(paint.size, const Size.square(48));
      expect(tester.getSize(find.byType(MorphOrb)), const Size.square(48));
    });

    testWidgets('exposes a per-state semantics label', (tester) async {
      await tester.pumpWidget(
        _host(const MorphOrb(state: MorphOrbState.generating)),
      );
      expect(find.bySemanticsLabel('Generating'), findsOneWidget);
      await tester.pumpWidget(
        _host(
          const MorphOrb(
            state: MorphOrbState.generating,
            semanticsLabel: 'Drafting a reply',
          ),
        ),
      );
      expect(find.bySemanticsLabel('Drafting a reply'), findsOneWidget);
    });

    testWidgets('can be hidden from semantics', (tester) async {
      await tester.pumpWidget(
        _host(const MorphOrb(excludeFromSemantics: true)),
      );
      expect(find.bySemanticsLabel('Thinking'), findsNothing);
      expect(find.byType(ExcludeSemantics), findsOneWidget);
    });

    testWidgets('keeps one controller across state changes and transitions', (
      tester,
    ) async {
      await tester.pumpWidget(_host(const MorphOrb(state: MorphOrbState.idle)));
      final element = tester.element(find.byType(MorphOrb));
      final before = tester.firstWidget<CustomPaint>(find.byType(CustomPaint));

      await tester.pumpWidget(
        _host(const MorphOrb(state: MorphOrbState.thinking)),
      );
      expect(tester.element(find.byType(MorphOrb)), same(element));
      final after = tester.firstWidget<CustomPaint>(find.byType(CustomPaint));
      final controller =
          (after.painter! as dynamic).controller as MorphOrbController;
      expect((before.painter! as dynamic).controller, same(controller));
      expect(controller.state, MorphOrbState.thinking);
      expect(controller.previousState, MorphOrbState.idle);
      expect(controller.isTransitioning, isTrue);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(controller.isTransitioning, isFalse);
    });

    testWidgets('picks the ambient text colour as ink', (tester) async {
      await tester.pumpWidget(_host(const MorphOrb()));
      final paint = tester.widget<CustomPaint>(find.byType(CustomPaint));
      final controller =
          (paint.painter! as dynamic).controller as MorphOrbController;
      expect(controller.inkColor(), const Color(0xFF123456));
    });

    testWidgets('an explicit colour wins over the ambient one', (tester) async {
      await tester.pumpWidget(_host(const MorphOrb(color: Color(0xFFABCDEF))));
      final paint = tester.widget<CustomPaint>(find.byType(CustomPaint));
      final controller =
          (paint.painter! as dynamic).controller as MorphOrbController;
      expect(controller.inkColor(), const Color(0xFFABCDEF));
    });

    testWidgets('follows the reduced-motion media query', (tester) async {
      await tester.pumpWidget(_host(const MorphOrb(), reduced: true));
      final paint = tester.widget<CustomPaint>(find.byType(CustomPaint));
      final controller =
          (paint.painter! as dynamic).controller as MorphOrbController;
      expect(controller.reducedMotion, isTrue);
      expect(controller.isTicking, isFalse);
    });

    testWidgets('disposes its controller when unmounted', (tester) async {
      await tester.pumpWidget(_host(const MorphOrb()));
      final paint = tester.widget<CustomPaint>(find.byType(CustomPaint));
      final controller =
          (paint.painter! as dynamic).controller as MorphOrbController;
      expect(controller.isTicking, isTrue);
      await tester.pumpWidget(const SizedBox());
      expect(() => controller.addListener(() {}), throwsFlutterError);
    });

    testWidgets('paints every variant without errors', (tester) async {
      for (final variant in MorphOrbVariant.values) {
        await tester.pumpWidget(_host(MorphOrb(variant: variant, size: 64)));
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pump(const Duration(milliseconds: 700));
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('paints every state without errors', (tester) async {
      for (final state in MorphOrbState.values) {
        await tester.pumpWidget(_host(MorphOrb(state: state, size: 64)));
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pump(const Duration(milliseconds: 700));
      }
      expect(tester.takeException(), isNull);
    });
  });
}
