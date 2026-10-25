import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sameloop_ui_flutter/src/app.dart';
import 'package:sameloop_ui_flutter/src/backend.dart';
import 'package:sameloop_ui_flutter/src/simulation.dart';

void main() {
  for (final size in [const Size(1280, 900), const Size(800, 600), const Size(390, 844)]) {
    testWidgets('dashboard fits $size and controls work', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final backend = SimulationBackend(autoStart: false);
      addTearDown(backend.dispose);
      await tester.pumpWidget(SameLoopApp(backend: backend));
      expect(tester.takeException(), isNull);
      final plus = find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == 'Increase setpoint',
      );
      await tester.ensureVisible(plus);
      await tester.tap(plus);
      await tester.pump();
      expect(backend.snapshot.setpoint, 25.5);
      final auto = find.text('AUTO');
      await tester.ensureVisible(auto);
      await tester.tap(auto);
      await tester.pump();
      expect(backend.snapshot.mode, ControlMode.auto);
      expect(tester.takeException(), isNull);
      backend.changeFault((s) => s.connected = false);
      await tester.pump();
      expect(find.textContaining('Disconnected ·'), findsOneWidget);
      final button = tester.widget<IconButton>(plus);
      expect(button.onPressed, isNull);
    });
  }
}
