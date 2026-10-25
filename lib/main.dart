// SPDX-License-Identifier: MIT
import 'package:flutter/material.dart';
import 'src/app.dart';
import 'src/backend.dart';

void main() => runApp(const _OwnedApplication());

class _OwnedApplication extends StatefulWidget {
  const _OwnedApplication();
  @override
  State<_OwnedApplication> createState() => _OwnedApplicationState();
}

class _OwnedApplicationState extends State<_OwnedApplication> {
  final SimulationBackend backend = SimulationBackend();
  @override
  void dispose() {
    backend.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => SameLoopApp(backend: backend);
}
