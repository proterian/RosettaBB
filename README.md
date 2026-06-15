<p align="center">
  <img src="Assets/icon-master.png" width="160" alt="RosettaBB">
</p>

<h1 align="center">RosettaBB</h1>

[![Release](https://img.shields.io/github/v/release/proterian/RosettaBB)](https://github.com/proterian/RosettaBB/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-lightgrey)](https://github.com/proterian/RosettaBB/releases/latest)

Утилита для Apple Silicon Mac: сканирует установленные приложения и показывает,
какие из них **Intel-only** — то есть требуют Rosetta и перестанут работать,
начиная с macOS 28 (см. [Apple Support 102527](https://support.apple.com/ru-ru/102527)).

## Возможности (MVP)

- Сканирует `/Applications`, `/Applications/Utilities` и `~/Applications`.
- Читает Mach-O-заголовок главного бинарника каждого `.app`.
- Классифицирует: **Intel** / **Universal** / **Apple**.
- Фильтр «только Intel», счётчики, открытие приложения в Finder.
- Проверка обновлений для Intel-приложений (App Store, Sparkle appcast,
  Homebrew Cask) — по кнопке, статус прямо в строке списка.

## Сборка и запуск

Требуется macOS 14+ и Swift 6 (Xcode 16+).

```bash
swift run RosettaBB
```

## Тесты

```bash
swift test
```

## Сборка приложения и DMG

```bash
bash scripts/generate-icons.sh   # один раз: иконки из Assets/
bash scripts/package-dmg.sh      # → dist/RosettaBB.app и dist/RosettaBB-1.0.dmg
```

Бандл подписывается ad-hoc (требование запуска arm64); без Developer ID и
нотаризации. При первом запуске из DMG откройте приложение через
правый клик → «Открыть».

## Архитектура

- `RosettaBBCore` — чистое ядро без UI: `MachOInspector` (парсинг Mach-O),
  `AppScanner` (обход файловой системы), `AppClassifier` (вердикт). Покрыто тестами.
- `RosettaBB` — SwiftUI-оболочка: `ScanViewModel` + `ContentView`.

## Статус

Рабочее приложение: аудит архитектур + проверка обновлений Intel-приложений.

## Лицензия

[MIT](LICENSE).
