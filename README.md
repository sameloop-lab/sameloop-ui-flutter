# SameLoop UI — Flutter

**Bind & Seek — Same Control Loop, Different Embedded Stacks.**

`sameloop-ui-flutter` is the first desktop interface for **SameLoop Lab**.
It implements the light touch-panel design (proposal 4): temperature, setpoint,
OFF/AUTO controls, fan request versus applied feedback, and system health.

Version: **0.1.0, source prototype**. The only implemented backend is a local
simulator. No AFB, KUKSA, OpenHarmony or webOS connection is made. Their names are
shown as planned integrations, not as selectable working backends.

## Requirements

Linux desktop session, Flutter SDK and native Linux build dependencies. This
project targets Flutter **3.35.7 / Dart 3.9** as a reproducible starting point, not
a claim about the newest available release. The Linux runner templates come from
that Flutter tag. See [validation status](VALIDATION.md) before relying on it.

Fedora dependencies (requires administrator rights on your PC):

```sh
sudo dnf install git curl unzip xz clang cmake ninja-build pkgconf-pkg-config gtk3-devel libstdc++-devel
```

If Flutter is not installed, install the SDK as your normal user in a new directory:

```sh
mkdir -p "$HOME/development"
git clone --depth 1 --branch 3.35.7 https://github.com/flutter/flutter.git "$HOME/development/flutter"
export PATH="$HOME/development/flutter/bin:$PATH"
flutter doctor -v
flutter devices
```

Do not overwrite an existing Flutter checkout. Add the PATH export to your shell
configuration if desired. No Android SDK or Android Studio is needed for this
Linux-only project. Initial dependency/tool downloads require internet access.
The Linux toolchain reported by `flutter doctor` must be healthy.

Official setup reference: <https://docs.flutter.dev/platform-integration/linux/setup>.
The Fedora packages above are the corresponding Fedora package names rather than
the Debian package names used in that guide.

## Run

From the extracted project root (the directory containing `pubspec.yaml`):

```sh
flutter pub get
flutter run -d linux
```

The Linux runner is included; `flutter create` is not required. The application
starts in OFF with an accepted 25 °C setpoint. The first sample arrives after
approximately 100 ms. Click AUTO to start cooling, and +/- to adjust the setpoint
in 0.5 °C steps. Scroll on smaller windows to see all panels.

Expand **Simulation controls** to inject heat, mark the sensor invalid, pause
measurements, disconnect the UI link, inject 55 °C or restart the controller.
These are local demo controls, not production APIs. The simulator continues while
the UI link is disconnected; operator commands are rejected, not queued. On
reconnection the current state becomes visible again.

## Check and build

```sh
flutter pub get
flutter analyze
flutter test
flutter build linux --release
```

On an x86_64 machine, launch the release with:

```sh
./build/linux/x64/release/bundle/sameloop_ui_flutter
```

On ARM64 the corresponding directory is `build/linux/arm64/release/bundle`.
Distribute the entire **bundle** directory, including `lib/` and `data/`, not only
the executable. Build on the target distribution or a suitably compatible build
base; this is not a statically linked universal Linux binary. RPM/OBS packaging is
not part of this first version.

After the first successful `flutter pub get`, commit the generated `pubspec.lock`
to pin the transitive application dependencies. A lockfile is intentionally not
fabricated in this source generation. Capture `flutter --version` with results.

## Code layout

| Path | Responsibility |
| --- | --- |
| `lib/main.dart` | Application lifecycle and simulator ownership |
| `lib/src/app.dart` | Responsive Flutter dashboard and test controls |
| `lib/src/backend.dart` | Backend abstraction and simulator timer |
| `lib/src/simulation.dart` | Deterministic plant and proportional control |
| `linux/` | GTK desktop runner and CMake integration |
| `test/` | Simulation behavior and widget tests |
| [docs/simulation.md](docs/simulation.md) | Equations, parameters and limitations |
| [docs/integration.md](docs/integration.md) | Connection to the umbrella project and future adapters |

No third-party runtime Dart package is used beyond Flutter. Do not confuse the
in-process demo's timings with real middleware measurements. Authorization,
network reconnection and full SameLoop acceptance coverage are future work.

## Git repository

Suggested GitHub repository name: **sameloop-ui-flutter**.
Suggested description: **Flutter desktop UI for SameLoop Lab, with a local thermal-control simulator.**

To publish into a new empty remote after reviewing the sources:

```sh
git init -b main
git add .
git commit -m "feat: add initial Flutter thermal-control demo"
git remote add origin git@github.com:YOUR_ACCOUNT/sameloop-ui-flutter.git
git push -u origin main
```

Replace `YOUR_ACCOUNT`. No repository has been created or pushed for you.

## License

Original code: [MIT](LICENSE). Flutter-derived Linux runner files retain the
upstream BSD license; see [NOTICE](NOTICE) and [third_party/FLUTTER-LICENSE](third_party/FLUTTER-LICENSE).
