# Integration with SameLoop Lab

Keep this repository separate as `sameloop-ui-flutter`. In the umbrella repository,
add its actual URL and immutable release commit to `ui/README.md` and the delivery
component index after publication. This generation does not invent a GitHub URL
or alter the uploaded umbrella archive. No submodule is required initially.

Future transport adapters implement `LoopBackend`: an observable `LoopSnapshot`
and asynchronous setting/mode requests. Keep transport details out of widgets.
The application owns and disposes the backend. A future non-simulation backend
must also replace the SIMULATION header and expose real connection metadata;
the current header intentionally describes only this source prototype.

The VSpec's Temperature.Value, Controller.Setpoint/Mode and Fan.DutyCycle/Speed
correspond to the snapshot fields. Sensor validity, local sample age and alarm
quality must remain explicit. Commands must never be treated as applied physical
state solely because a transport acknowledged them.

First candidates: redpesk AFB or AGL/KUKSA. Pin their protocol/API versions and
implement command outcomes, subscriptions, authorization and recovery before
marking them supported. No generic network retry should replay stale commands.

Before comparative experiments, agree on the simulation/control model with the
umbrella project and run the same fixtures in every implementation. Local Flutter
simulation measurements are not comparable to four real service stacks.
