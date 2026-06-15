<p align="center">
  <img src="Assets/icon-master.png" width="160" alt="RosettaBB">
</p>

<h1 align="center">RosettaBB</h1>

<p align="center">
  <a href="https://github.com/proterian/RosettaBB/releases/latest"><img src="https://img.shields.io/github/v/release/proterian/RosettaBB" alt="Release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT"></a>
  <a href="https://github.com/proterian/RosettaBB/releases/latest"><img src="https://img.shields.io/badge/platform-macOS%2014%2B-lightgrey" alt="Platform"></a>
</p>

<p align="center"><b>English</b> · <a href="README.ru.md">Русский</a></p>

A utility for Apple Silicon Macs that scans your installed apps and shows which
ones are **Intel-only** — i.e. require Rosetta and will stop working starting
with macOS 28 (see [Apple Support 102527](https://support.apple.com/en-us/102527)).

## Features

- Scans `/Applications`, `/Applications/Utilities` and `~/Applications`.
- Reads the Mach-O header of each app's main binary.
- Classifies every app: **Intel** / **Universal** / **Apple**.
- "Intel only" filter, counters, "Show in Finder".
- Update checking for Intel apps (App Store, Sparkle appcast, Homebrew Cask) —
  on demand, with the result shown right in the list.
- Localized interface: English and Russian (follows the system language).

## Download

Grab the latest **RosettaBB.dmg** from the
[Releases](https://github.com/proterian/RosettaBB/releases/latest) page and drag
the app into Applications. The app is not notarized, so on first launch use
right-click → **Open**. Requires macOS 14+ (Apple Silicon).

## Build & run

Requires macOS 14+ and Swift 6 (Xcode 16+).

```bash
swift run RosettaBB
```

## Tests

```bash
swift test
```

## Building the app & DMG

```bash
bash scripts/generate-icons.sh   # once: icons from Assets/
bash scripts/package-dmg.sh      # → dist/RosettaBB.app and dist/RosettaBB-1.0.dmg
```

The bundle is ad-hoc signed (required to launch arm64 binaries); without a
Developer ID certificate and notarization there is no point signing it for
wider distribution.

## Architecture

- `RosettaBBCore` — pure, UI-free core: `MachOInspector` (Mach-O parsing),
  `AppScanner` (filesystem walk), `AppClassifier` (verdict). Covered by tests.
- `RosettaBB` — SwiftUI shell: `ScanViewModel` + `ContentView`.

## License

[MIT](LICENSE).
