// SPDX-License-Identifier: MIT
import 'package:flutter/material.dart';
import 'backend.dart';
import 'simulation.dart';

const _blue = Color(0xFF1762F5);
const _ink = Color(0xFF10244A);
const _muted = Color(0xFF65758E);
const _line = Color(0xFFE4EAF4);

class SameLoopApp extends StatelessWidget {
  const SameLoopApp({super.key, required this.backend});
  final LoopBackend backend;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SameLoop Lab — Bind & Seek',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: _blue),
      scaffoldBackgroundColor: const Color(0xFFF3F6FB),
      fontFamily: 'sans-serif',
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: _ink, fontSize: 15),
        titleLarge: TextStyle(color: _ink, fontSize: 22, fontWeight: FontWeight.w700),
      ),
    ),
    home: Dashboard(backend: backend),
  );
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key, required this.backend});
  final LoopBackend backend;
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  bool _busy = false;
  String? _error;

  Future<void> _command(Future<void> Function() action) async {
    setState(() { _busy = true; _error = null; });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.backend,
    builder: (context, _) {
      final s = widget.backend.snapshot;
      final enabled = s.connected && !_busy;
      return Scaffold(
        body: SafeArea(
          child: LayoutBuilder(builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            return SingleChildScrollView(
              padding: EdgeInsets.all(compact ? 16 : 32),
              child: Center(child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  _header(),
                  const SizedBox(height: 24),
                  if (!s.connected) ...[
                    _notice('Disconnected · readings unavailable. Controls are disabled.', Icons.link_off, Colors.orange.shade800),
                    const SizedBox(height: 16),
                  ],
                  if (_error != null) ...[
                    _notice(_error!, Icons.error_outline, Colors.red.shade700),
                    const SizedBox(height: 16),
                  ],
                  if (compact) ...[
                    _temperature(s),
                    const SizedBox(height: 16),
                    _controls(s, enabled),
                  ] else Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _temperature(s)),
                    const SizedBox(width: 20),
                    Expanded(child: _controls(s, enabled)),
                  ]),
                  const SizedBox(height: 20),
                  _fan(s),
                  const SizedBox(height: 20),
                  _health(s),
                  const SizedBox(height: 20),
                  if (widget.backend is SimulationBackend)
                    _simulationControls(widget.backend as SimulationBackend),
                  const SizedBox(height: 20),
                  const Text('Bind & Seek  /  Same Control Loop, Different Embedded Stacks',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _muted, fontSize: 13)),
                ]),
              )),
            );
          }),
        ),
      );
    },
  );

  Widget _header() => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 24, runSpacing: 16,
    children: [
      const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('SameLoop Lab', style: TextStyle(color: _ink, fontSize: 28, fontWeight: FontWeight.w800)),
        SizedBox(height: 4),
        Text('THERMAL CONTROL BENCH', style: TextStyle(color: _muted, fontSize: 11, letterSpacing: 2)),
      ]),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 10, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          const Chip(label: Text('SIMULATION'), avatar: Icon(Icons.science_outlined, size: 18)),
          Text(widget.backend.name, style: const TextStyle(color: _blue, fontWeight: FontWeight.w600)),
        ]),
        const Text('Planned: redpesk · AGL · OpenHarmony · webOS',
          style: TextStyle(color: _muted, fontSize: 12)),
      ]),
    ],
  );

  Widget _temperature(LoopSnapshot s) => _Panel(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _Label(icon: Icons.thermostat_outlined, text: 'Chamber temperature'),
      const SizedBox(height: 30),
      SizedBox(height: 104, child: Align(
        alignment: Alignment.centerLeft,
        child: FittedBox(fit: BoxFit.scaleDown, child: Text(
          s.temperature == null ? '— °C' : '${s.temperature!.toStringAsFixed(1)} °C',
          key: const Key('temperature'),
          style: TextStyle(fontSize: 78, fontWeight: FontWeight.w700,
            color: s.fresh ? _ink : _muted, letterSpacing: -3),
        )),
      )),
      Text(s.fresh ? 'Live measurement' : 'Unavailable / last known measurement',
        style: TextStyle(color: s.fresh ? _muted : Colors.orange.shade800)),
      const SizedBox(height: 22),
      const Divider(color: _line),
      const SizedBox(height: 12),
      Text(s.connected ? 'Target (accepted setpoint)' : 'Last known setpoint',
        style: const TextStyle(color: _muted)),
      const SizedBox(height: 6),
      Text('${s.setpoint.toStringAsFixed(1)} °C',
        style: const TextStyle(fontSize: 28, color: _blue, fontWeight: FontWeight.w700)),
    ]),
  );

  Widget _controls(LoopSnapshot s, bool enabled) => Column(children: [
    _Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const _Label(icon: Icons.tune, text: 'Temperature setpoint'),
      const SizedBox(height: 22),
      Row(children: [
        _stepButton('Decrease setpoint', Icons.remove,
          enabled && s.setpoint > 15 ? () => _command(() => widget.backend.setSetpoint(s.setpoint - 0.5)) : null),
        Expanded(child: FittedBox(fit: BoxFit.scaleDown, child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('${s.setpoint.toStringAsFixed(1)} °C', key: const Key('setpoint'),
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: _ink)),
        ))),
        _stepButton('Increase setpoint', Icons.add,
          enabled && s.setpoint < 40 ? () => _command(() => widget.backend.setSetpoint(s.setpoint + 0.5)) : null),
      ]),
      const SizedBox(height: 12),
      const Text('15–40 °C  ·  0.5 °C steps', style: TextStyle(color: _muted, fontSize: 12)),
    ])),
    const SizedBox(height: 16),
    _Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _Label(icon: Icons.power_settings_new,
        text: s.connected ? 'Control mode' : 'Last known mode'),
      const SizedBox(height: 18),
      SegmentedButton<ControlMode>(
        segments: const [
          ButtonSegment(value: ControlMode.off, label: Text('OFF')),
          ButtonSegment(value: ControlMode.auto, label: Text('AUTO')),
        ],
        selected: {s.mode},
        onSelectionChanged: enabled ? (v) => _command(() => widget.backend.setMode(v.first)) : null,
        style: const ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(80, 56))),
      ),
    ])),
  ]);

  Widget _stepButton(String label, IconData icon, VoidCallback? callback) =>
    IconButton.filledTonal(
      tooltip: label,
      onPressed: callback,
      icon: Icon(icon, size: 28),
      style: IconButton.styleFrom(minimumSize: const Size(56, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    );

  Widget _fan(LoopSnapshot s) => _Panel(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _Label(icon: Icons.air, text: 'Cooling fan · feedback'),
      const SizedBox(height: 20),
      Wrap(spacing: 48, runSpacing: 24, children: [
        _metric('Requested', s.requestedDuty == null ? '—' : '${s.requestedDuty!.toStringAsFixed(0)} %'),
        _metric('Applied', s.appliedDuty == null ? '—' : '${s.appliedDuty!.toStringAsFixed(0)} %'),
        _metric('Measured speed', s.rpm == null ? '—' : '${s.rpm} rpm'),
      ]),
      const SizedBox(height: 20),
      Semantics(label: 'Applied fan duty', child: LinearProgressIndicator(
        value: (s.appliedDuty ?? 0) / 100,
        minHeight: 6, color: _blue, backgroundColor: _line,
      )),
    ],
  ));

  Widget _metric(String label, String value) => SizedBox(width: 180, child:
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: _muted, fontSize: 13)),
      const SizedBox(height: 6),
      Text(value, style: const TextStyle(color: _ink, fontSize: 28, fontWeight: FontWeight.w700)),
    ]));

  Widget _health(LoopSnapshot s) => _Panel(child: Column(
    crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _Label(icon: Icons.monitor_heart_outlined, text: 'System status'),
      const SizedBox(height: 20),
      Wrap(spacing: 24, runSpacing: 20, children: [
        _status('Sensor valid', s.sensorValid == null ? 'Unknown' : s.sensorValid! ? 'Yes' : 'Invalid',
          s.sensorValid == null ? null : s.sensorValid! && s.fresh),
        _status('Data freshness', !s.connected || s.age == null ? 'Unavailable' : '${s.age!.inMilliseconds} ms', s.fresh),
        _status('Overtemperature', !s.fresh || s.overtemperature == null ? 'Unknown' : s.overtemperature! ? 'ACTIVE' : 'Inactive',
          s.fresh && s.overtemperature != null ? !s.overtemperature! : null),
        _status('Sensor unavailable', s.sensorUnavailable ? 'ACTIVE' : 'Inactive', !s.sensorUnavailable),
        _status('Simulator link', s.connected ? 'Connected' : 'Disconnected', s.connected),
      ]),
    ],
  ));

  Widget _status(String title, String value, bool? ok) => SizedBox(width: 180, child:
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: _muted, fontSize: 12)),
      const SizedBox(height: 8),
      Row(children: [
        Icon(Icons.circle, size: 9, color: ok == null ? _muted : ok ? const Color(0xFF20A775) : const Color(0xFFD46B10)),
        const SizedBox(width: 8),
        Flexible(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
      ]),
    ]));

  Widget _simulationControls(SimulationBackend b) => _Panel(
    child: ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: const Text('Simulation controls', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: const Text('Local test tools · no physical device is connected', style: TextStyle(fontSize: 12, color: _muted)),
      children: [
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Extra heat load'),
          value: b.simulation.heatBoost, onChanged: (v) => b.changeFault((s) => s.heatBoost = v)),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Invalid sensor'),
          value: !b.simulation.sensorValid, onChanged: (v) => b.changeFault((s) => s.sensorValid = !v)),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Pause sensor updates'),
          value: b.simulation.paused, onChanged: (v) => b.changeFault((s) => s.paused = v)),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Disconnect UI link'),
          value: !b.simulation.connected, onChanged: (v) => b.changeFault((s) => s.connected = !v)),
        Wrap(spacing: 12, runSpacing: 12, children: [
          OutlinedButton.icon(onPressed: () => b.changeFault((s) => s.injectOvertemperature()),
            icon: const Icon(Icons.local_fire_department_outlined), label: const Text('Inject 55 °C')),
          OutlinedButton.icon(onPressed: () => b.changeFault((s) => s.restartController()),
            icon: const Icon(Icons.restart_alt), label: const Text('Restart controller')),
        ]),
      ],
    ),
  );

  Widget _notice(String text, IconData icon, Color color) => _Panel(child: Row(children: [
    Icon(icon, color: color), const SizedBox(width: 12), Expanded(child: Text(text)),
  ]));
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: Colors.white,
      borderRadius: BorderRadius.circular(18), border: Border.all(color: _line)),
    child: child,
  );
}

class _Label extends StatelessWidget {
  const _Label({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: _blue, size: 21), const SizedBox(width: 10),
    Expanded(child: Text(text, style: const TextStyle(color: _ink, fontWeight: FontWeight.w600, fontSize: 16))),
  ]);
}
