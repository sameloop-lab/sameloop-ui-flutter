// SPDX-License-Identifier: MIT
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'simulation.dart';

/// Implement this contract for AFB/KUKSA/etc.; widgets never call a transport.
abstract class LoopBackend extends ChangeNotifier {
  LoopSnapshot get snapshot;
  String get name;
  Future<void> setSetpoint(double value);
  Future<void> setMode(ControlMode mode);
}

class SimulationBackend extends LoopBackend {
  SimulationBackend({bool autoStart = true}) {
    if (autoStart) {
      _clock.start();
      _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
        final now = _clock.elapsed;
        simulation.advance(now - _lastTick);
        _lastTick = now;
        notifyListeners();
      });
    }
  }
  final ThermalSimulation simulation = ThermalSimulation();
  final Stopwatch _clock = Stopwatch();
  Duration _lastTick = Duration.zero;
  Timer? _timer;
  @override
  String get name => 'Local simulator';
  @override
  LoopSnapshot get snapshot => simulation.snapshot;
  @override
  Future<void> setSetpoint(double value) async {
    simulation.setSetpoint(value);
    notifyListeners();
  }
  @override
  Future<void> setMode(ControlMode mode) async {
    simulation.setMode(mode);
    notifyListeners();
  }
  void changeFault(void Function(ThermalSimulation) action) {
    action(simulation);
    notifyListeners();
  }
  @override
  void dispose() {
    _timer?.cancel();
    _clock.stop();
    super.dispose();
  }
}
