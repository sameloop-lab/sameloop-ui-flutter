import 'package:flutter_test/flutter_test.dart';
import 'package:sameloop_ui_flutter/src/simulation.dart';

void main() {
  test('startup and valid first sample are distinct', () {
    final sim = ThermalSimulation();
    expect(sim.snapshot.mode, ControlMode.off);
    expect(sim.snapshot.setpoint, 25);
    expect(sim.snapshot.temperature, isNull);
    expect(sim.snapshot.sensorUnavailable, isTrue);
    sim.advance(const Duration(milliseconds: 100));
    expect(sim.snapshot.temperature, 32.4);
    expect(sim.snapshot.fresh, isTrue);
  });
  test('invalid settings do not change accepted value', () {
    final sim = ThermalSimulation();
    for (final v in [double.nan, double.infinity, 14.0, 41.0]) {
      expect(() => sim.setSetpoint(v), throwsArgumentError);
      expect(sim.snapshot.setpoint, 25);
    }
  });
  test('cooling responds and requested differs from applied duty', () {
    final sim = ThermalSimulation()..setMode(ControlMode.auto);
    sim.advance(const Duration(milliseconds: 100));
    expect(sim.snapshot.requestedDuty, 100);
    expect(sim.snapshot.appliedDuty, lessThan(100));
    sim.advance(const Duration(seconds: 30));
    expect(sim.snapshot.temperature!, lessThan(30));
    sim.setMode(ControlMode.off);
    expect(sim.snapshot.requestedDuty, 0);
  });
  test('timeout at one second and recovery in AUTO', () {
    final sim = ThermalSimulation()..setMode(ControlMode.auto);
    sim.advance(const Duration(milliseconds: 100));
    sim.paused = true;
    sim.advance(const Duration(milliseconds: 999));
    expect(sim.snapshot.sensorUnavailable, isFalse);
    sim.advance(const Duration(milliseconds: 1));
    expect(sim.snapshot.sensorUnavailable, isTrue);
    expect(sim.snapshot.requestedDuty, 0);
    sim.paused = false;
    sim.advance(const Duration(milliseconds: 100));
    expect(sim.snapshot.fresh, isTrue);
    expect(sim.snapshot.requestedDuty!, greaterThan(0));
  });
  test('invalid sensor suspends regulation and preserves alarm as stale', () {
    final sim = ThermalSimulation()..setMode(ControlMode.auto)..injectOvertemperature();
    sim.advance(const Duration(milliseconds: 100));
    expect(sim.snapshot.overtemperature, isTrue);
    sim.sensorValid = false;
    sim.advance(const Duration(milliseconds: 100));
    expect(sim.snapshot.sensorUnavailable, isTrue);
    expect(sim.snapshot.requestedDuty, 0);
    expect(sim.snapshot.overtemperature, isTrue);
    expect(sim.snapshot.fresh, isFalse);
  });
  test('disconnect rejects commands and hides actual readings', () {
    final sim = ThermalSimulation()..connected = false;
    expect(() => sim.setSetpoint(28), throwsStateError);
    expect(() => sim.setMode(ControlMode.auto), throwsStateError);
    sim.advance(const Duration(seconds: 1));
    expect(sim.snapshot.temperature, isNull);
    sim.connected = true;
    expect(sim.snapshot.setpoint, 25);
    expect(sim.snapshot.mode, ControlMode.off);
    expect(sim.snapshot.temperature, isNotNull);
  });
  test('controller restart resets settings without resetting the plant', () {
    final sim = ThermalSimulation()..setSetpoint(28)..setMode(ControlMode.auto);
    sim.advance(const Duration(seconds: 1));
    final temperature = sim.snapshot.temperature;
    sim.restartController();
    expect(sim.snapshot.mode, ControlMode.off);
    expect(sim.snapshot.setpoint, 25);
    expect(sim.snapshot.temperature, temperature);
  });
}
