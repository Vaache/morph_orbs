import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morph_orbs/morph_orbs.dart';

const Duration _kTransition = Duration(milliseconds: 400);
const MorphOrbStyle _kStyle = MorphOrbStyle(
  color: Color(0xFFFFFFFF),
  successColor: Color(0xFF00FF00),
  errorColor: Color(0xFFFF0000),
  transitionDuration: _kTransition,
  transitionCurve: Curves.linear,
);

/// Builds a controller and primes the ticker: a ticker's first tick is at
/// elapsed zero, so one pump lets the next pump advance the clock.
Future<MorphOrbController> _controller(
  WidgetTester tester, {
  MorphOrbState state = MorphOrbState.thinking,
  bool reducedMotion = false,
}) async {
  final controller = MorphOrbController(
    vsync: const TestVSync(),
    state: state,
    size: 40,
    style: _kStyle,
    reducedMotion: reducedMotion,
  );
  await tester.pump();
  return controller;
}

void main() {
  group('MorphOrbController', () {
    testWidgets('starts in the given state, ticking, not transitioning', (
      tester,
    ) async {
      final controller = await _controller(tester);
      expect(controller.state, MorphOrbState.thinking);
      expect(controller.previousState, isNull);
      expect(controller.isTransitioning, isFalse);
      expect(controller.transitionProgress, 1);
      expect(controller.isTicking, isTrue);
      controller.dispose();
    });

    testWidgets('advances its clock on frames and notifies listeners', (
      tester,
    ) async {
      final controller = await _controller(tester);
      var notified = 0;
      controller.addListener(() => notified++);
      await tester.pump(const Duration(milliseconds: 500));
      expect(controller.elapsed, closeTo(0.5, 0.02));
      expect(notified, greaterThan(0));
      controller.dispose();
    });

    testWidgets('setState starts a transition that completes on time', (
      tester,
    ) async {
      final controller = await _controller(tester);
      await tester.pump(const Duration(milliseconds: 100));
      controller.setState(MorphOrbState.generating);
      expect(controller.state, MorphOrbState.generating);
      expect(controller.previousState, MorphOrbState.thinking);
      expect(controller.isTransitioning, isTrue);
      expect(controller.transitionProgress, 0);

      await tester.pump(const Duration(milliseconds: 200));
      expect(controller.transitionProgress, closeTo(0.5, 0.05));
      controller.render(40);
      expect(controller.isTransitioning, isTrue);

      await tester.pump(const Duration(milliseconds: 250));
      expect(controller.transitionProgress, 1);
      controller.render(40);
      expect(controller.isTransitioning, isFalse);
      expect(controller.previousState, isNull);
      controller.dispose();
    });

    testWidgets('setState to the same state is a no-op', (tester) async {
      final controller = await _controller(tester);
      var notified = 0;
      controller.addListener(() => notified++);
      controller.setState(MorphOrbState.thinking);
      expect(notified, 0);
      expect(controller.isTransitioning, isFalse);
      controller.dispose();
    });

    testWidgets('a change mid-transition morphs from the current dots', (
      tester,
    ) async {
      final controller = await _controller(tester);
      controller.setState(MorphOrbState.generating);
      await tester.pump(const Duration(milliseconds: 200));
      final midway = controller.render(40);
      final midX = midway.x(0);
      controller.setState(MorphOrbState.success);
      expect(controller.previousState, MorphOrbState.generating);
      expect(controller.transitionProgress, 0);
      final restarted = controller.render(40);
      expect(restarted.x(0), closeTo(midX, 1e-9));
      controller.dispose();
    });

    testWidgets('setVariant morphs a continuous state like a state change', (
      tester,
    ) async {
      final controller = await _controller(tester);
      controller.setVariant(MorphOrbVariant.swarm);
      expect(controller.variant, MorphOrbVariant.swarm);
      expect(controller.state, MorphOrbState.thinking);
      expect(controller.isTransitioning, isTrue);
      await tester.pump(const Duration(milliseconds: 500));
      controller.render(40);
      expect(controller.isTransitioning, isFalse);
      controller.dispose();
    });

    testWidgets('setVariant on a terminal state only records the choice', (
      tester,
    ) async {
      final controller = await _controller(
        tester,
        state: MorphOrbState.stopped,
      );
      controller.setVariant(MorphOrbVariant.nebula);
      expect(controller.variant, MorphOrbVariant.nebula);
      expect(controller.isTransitioning, isFalse);
      controller.setState(MorphOrbState.thinking);
      expect(controller.isTransitioning, isTrue);
      controller.dispose();
    });

    testWidgets('ink lerps from the previous state colour to the next', (
      tester,
    ) async {
      final controller = await _controller(tester);
      expect(controller.inkColor(), const Color(0xFFFFFFFF));
      controller.setState(MorphOrbState.error);
      await tester.pump(const Duration(milliseconds: 200));
      final mid = controller.inkColor();
      expect(mid.g, closeTo(0.5, 0.05));
      await tester.pump(const Duration(milliseconds: 300));
      controller.render(40);
      expect(controller.inkColor(), const Color(0xFFFF0000));
      controller.dispose();
    });

    testWidgets('the ticker stops once a terminal state has settled', (
      tester,
    ) async {
      final controller = await _controller(tester);
      controller.setState(MorphOrbState.success);
      expect(controller.isTicking, isTrue);
      await tester.pump(const Duration(milliseconds: 500));
      expect(controller.isTicking, isTrue);
      await tester.pump(const Duration(seconds: 2));
      expect(controller.isTicking, isFalse);
      final clock = controller.elapsed;
      await tester.pump(const Duration(seconds: 1));
      expect(controller.elapsed, clock);
      controller.dispose();
    });

    testWidgets('stopped freezes after its transition', (tester) async {
      final controller = await _controller(tester);
      controller.setState(MorphOrbState.stopped);
      expect(controller.isTicking, isTrue);
      await tester.pump(const Duration(milliseconds: 500));
      expect(controller.isTicking, isFalse);
      controller.dispose();
    });

    testWidgets('leaving a settled state restarts the ticker', (tester) async {
      final controller = await _controller(
        tester,
        state: MorphOrbState.stopped,
      );
      expect(controller.isTicking, isFalse);
      controller.setState(MorphOrbState.thinking);
      expect(controller.isTicking, isTrue);
      controller.dispose();
    });

    testWidgets('reduced motion never ticks and switches instantly', (
      tester,
    ) async {
      final controller = await _controller(tester, reducedMotion: true);
      expect(controller.isTicking, isFalse);
      controller.setState(MorphOrbState.generating);
      expect(controller.isTransitioning, isFalse);
      expect(controller.isTicking, isFalse);
      expect(controller.render(40).length, greaterThan(0));
      controller.dispose();
    });

    testWidgets('update re-resolves for a new size and notifies', (
      tester,
    ) async {
      final controller = await _controller(tester);
      final before = controller.render(40).length;
      var notified = 0;
      controller.addListener(() => notified++);
      controller.update(size: 64);
      expect(notified, 1);
      expect(controller.size, 64);
      expect(controller.render(64).length, greaterThan(before));
      controller.update(size: 64);
      expect(notified, 1);
      controller.dispose();
    });

    testWidgets('render returns dots sorted far to near', (tester) async {
      final controller = await _controller(tester);
      await tester.pump(const Duration(milliseconds: 300));
      final frame = controller.render(40);
      final order = frame.order;
      expect(order.length, frame.length);
      for (var i = 1; i < order.length; i++) {
        expect(frame.z(order[i]), greaterThanOrEqualTo(frame.z(order[i - 1])));
      }
      controller.dispose();
    });

    testWidgets('dispose stops the ticker and ignores later updates', (
      tester,
    ) async {
      final controller = await _controller(tester);
      expect(controller.isTicking, isTrue);
      controller.dispose();
      await tester.pump(const Duration(milliseconds: 100));
      expect(SchedulerBinding.instance.hasScheduledFrame, isFalse);
    });
  });
}
