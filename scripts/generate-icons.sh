#!/usr/bin/env bash
#
# Генерирует полный набор иконок приложения из мастер-изображения:
#   Assets/AppIcon.iconset/  — все размеры PNG (16…1024)
#   Assets/AppIcon.icns      — скомпилированная иконка для бандла
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

ASSETS="$ROOT/Assets"
ICONSET="$ASSETS/AppIcon.iconset"
MASTER="$ASSETS/icon-master.png"

mkdir -p "$ASSETS"

echo "==> Отрисовка мастер-иконки 1024×1024"
swift "$ROOT/scripts/make-icon.swift" "$MASTER"

echo "==> Генерация iconset (все размеры)"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"

# size:filename
sizes=(
  "16:icon_16x16.png"
  "32:icon_16x16@2x.png"
  "32:icon_32x32.png"
  "64:icon_32x32@2x.png"
  "128:icon_128x128.png"
  "256:icon_128x128@2x.png"
  "256:icon_256x256.png"
  "512:icon_256x256@2x.png"
  "512:icon_512x512.png"
  "1024:icon_512x512@2x.png"
)
for entry in "${sizes[@]}"; do
  px="${entry%%:*}"
  name="${entry##*:}"
  sips -z "$px" "$px" "$MASTER" --out "$ICONSET/$name" >/dev/null
done

echo "==> Компиляция AppIcon.icns"
iconutil -c icns "$ICONSET" -o "$ASSETS/AppIcon.icns"

echo
echo "==> Готово:"
echo "    $ICONSET ($(ls "$ICONSET" | wc -l | tr -d ' ') файлов)"
echo "    $ASSETS/AppIcon.icns"
ls -lh "$ASSETS/AppIcon.icns"
