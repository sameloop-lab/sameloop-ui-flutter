# Simulation v0.1

This is a proposed UI demonstration model, not a validated physical plant. It
implements a subset of the draft SameLoop functional contract in umbrella commit
`17ba26fc93594d86b7d7ade3200ab9c0f0ccc3a8`. It does not change that repository.

## Model

Initial temperature: 32.4 °C; ambient: 20 °C; mode: OFF; setpoint: 25 °C.
Provider updates occur every 100 ms through a Flutter Timer. A monotonic Stopwatch
supplies elapsed time. The engine integrates elapsed time in steps no larger than
100 ms. Timer delivery is not hard real-time; UI samples can be coalesced after
process stalls. Do not use the UI refresh interval as a middleware benchmark.

For AUTO with fresh valid measurements:

`requestedDuty = clamp(20 * (measuredTemperature - setpoint), 0, 100)`

OFF or unavailable sensor: requested duty is zero. This demo policy is not a
physical safety policy. Actual duty follows the request with a 0.6 s first-order
time constant; fan speed follows `40 * actualDuty` rpm with a 0.8 s time constant.
Both first-order updates use `1 - exp(-dt / tau)`.

The temperature update uses Euler integration:

`dT/dt = heat - (0.015 + 0.12 * actualDuty / 100) * (T - 20)`

Heat is 0.18 °C/s normally, 1.2 °C/s with extra heat enabled. Temperature is bounded
to [-40, 150] °C. This proportional-only controller has steady-state error and cannot
cool below ambient. Exact target tracking is not claimed. No randomness is used.

## Fault semantics

- Values are unknown until the first sample; unknown is not zero.
- Invalid sensor: the displayed measurement is marked unavailable; control stops.
- Paused sensor: last value is retained, age increases, unavailable at >= 1 second.
- Overtemperature: above 50 °C on valid samples; no latch/hysteresis. Last alarm is
  preserved internally during sensor loss but the UI displays Unknown.
- UI disconnect: plant/controller keep running; feedback is hidden and commands
  are rejected. Mode/setpoint are labeled last known while disconnected. Reconnect
  simply reveals current local state, not a tested network resubscription.
- Restart controller: OFF, 25 °C, requested duty zero; plant temperature persists.

The control algorithm is embedded in the simulator for this first UI-only build.
A real backend must own its controller; do not run this control algorithm in
parallel with a remote controller.

## Scope limitations

No CAN/DBC, persisted configuration, real hardware, user roles, auth enforcement,
request correlation/event log, durable alarms or transport recovery is implemented.
Settings are immediately accepted locally; fan dynamics demonstrate the distinction
between requested and applied output. This is not full F01–F09 conformance.
