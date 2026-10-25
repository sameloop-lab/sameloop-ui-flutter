// SPDX-License-Identifier: MIT
import 'dart:math' as math;

enum ControlMode { off, auto }

/// Immutable sample exposed to the UI. Null means not available, never zero.
class LoopSnapshot {
  const LoopSnapshot({
    required this.temperature, required this.setpoint, required this.mode,
    required this.requestedDuty, required this.appliedDuty, required this.rpm,
    required this.sensorValid, required this.age, required this.connected,
    required this.overtemperature, required this.sensorUnavailable,
  });
  final double? temperature;
  final double setpoint;
  final ControlMode mode;
  final double? requestedDuty, appliedDuty;
  final int? rpm;
  final bool? sensorValid, overtemperature;
  final Duration? age;
  final bool connected, sensorUnavailable;
  bool get fresh => connected && !sensorUnavailable;
}

/// Deterministic local demo, deliberately independent of Flutter and transport.
class ThermalSimulation {
  double _temperature = 32.4;
  double _setpoint = 25;
  double _requested = 0, _applied = 0, _rpm = 0;
  ControlMode _mode = ControlMode.off;
  Duration _now = Duration.zero;
  Duration? _lastValid;
  double? _measurement;
  bool? _alarm;
  bool sensorValid = true;
  bool paused = false;
  bool connected = true;
  bool heatBoost = false;

  bool get _unavailable => !sensorValid || _lastValid == null ||
      _now - _lastValid! >= const Duration(seconds: 1);

  LoopSnapshot get snapshot => LoopSnapshot(
    temperature: connected ? _measurement : null,
    setpoint: _setpoint, mode: _mode,
    requestedDuty: connected ? _requested : null,
    appliedDuty: connected && _measurement != null ? _applied : null,
    rpm: connected && _measurement != null ? _rpm.round() : null,
    sensorValid: connected && _measurement != null ? sensorValid : null,
    age: _lastValid == null ? null : _now - _lastValid!,
    connected: connected,
    overtemperature: connected ? _alarm : null,
    sensorUnavailable: !connected || _unavailable,
  );

  void _requireConnection() {
    if (!connected) throw StateError('Simulator disconnected; request rejected.');
  }

  void setSetpoint(double value) {
    _requireConnection();
    if (!value.isFinite || value < 15 || value > 40) {
      throw ArgumentError('Setpoint must be between 15 and 40 °C.');
    }
    _setpoint = value;
  }

  void setMode(ControlMode value) {
    _requireConnection();
    _mode = value;
    if (value == ControlMode.off) _requested = 0;
  }

  void restartController() {
    _mode = ControlMode.off;
    _setpoint = 25;
    _requested = 0;
  }

  void injectOvertemperature() { _temperature = 55; }

  /// Advances virtual time in <=100 ms steps. Published samples are local only.
  void advance(Duration elapsed) {
    if (elapsed.isNegative) throw ArgumentError('Time must advance forward.');
    var remaining = elapsed.inMicroseconds;
    while (remaining > 0) {
      final micros = math.min(remaining, 100000);
      remaining -= micros;
      final dt = micros / 1000000.0;
      _now += Duration(microseconds: micros);
      if (!paused) {
        _measurement = _temperature;
        if (sensorValid) {
          _lastValid = _now;
          _alarm = _temperature > 50;
        }
      }
      // Proportional-only cooling: intentional steady-state error, no PID claim.
      _requested = _mode == ControlMode.auto && !_unavailable
          ? ((_measurement! - _setpoint) * 20).clamp(0.0, 100.0).toDouble()
          : 0;
      _applied += (_requested - _applied) * (1 - math.exp(-dt / 0.6));
      _rpm += (_applied * 40 - _rpm) * (1 - math.exp(-dt / 0.8));
      final heating = heatBoost ? 1.2 : 0.18;
      // Passive cooling + fan cooling toward a fixed 20 °C ambient.
      final loss = (0.015 + 0.12 * _applied / 100) * (_temperature - 20);
      _temperature = (_temperature + dt * (heating - loss))
          .clamp(-40.0, 150.0).toDouble();
    }
  }
}
