#!/usr/bin/env bash
#
# Собирает RosettaBB.app (релизный бандл) и упаковывает в DMG.
# Подпись — ad-hoc (требуется для запуска arm64 на Apple Silicon),
# без Developer ID / нотаризации.
#
set -euo pipefail

APP_NAME="RosettaBB"
BUNDLE_ID="com.proterian.RosettaBB"
VERSION="1.0"
BUILD_NUMBER="1"
MIN_MACOS="14.0"

# Корень репозитория — на уровень выше каталога scripts/
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

DIST="$ROOT/dist"
APP="$DIST/$APP_NAME.app"
DMG="$DIST/$APP_NAME-$VERSION.dmg"

echo "==> Релизная сборка"
swift build -c release
BIN_PATH="$(swift build -c release --show-bin-path)"
EXECUTABLE="$BIN_PATH/$APP_NAME"
[ -x "$EXECUTABLE" ] || { echo "Не найден бинарник: $EXECUTABLE" >&2; exit 1; }

echo "==> Сборка бандла $APP_NAME.app"
rm -rf "$DIST"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$EXECUTABLE" "$APP/Contents/MacOS/$APP_NAME"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>               <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>        <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>         <string>$BUNDLE_ID</string>
    <key>CFBundleExecutable</key>         <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>           <string>AppIcon</string>
    <key>CFBundleVersion</key>            <string>$BUILD_NUMBER</string>
    <key>CFBundleShortVersionString</key> <string>$VERSION</string>
    <key>CFBundlePackageType</key>        <string>APPL</string>
    <key>CFBundleInfoDictionaryVersion</key> <string>6.0</string>
    <key>LSMinimumSystemVersion</key>     <string>$MIN_MACOS</string>
    <key>LSApplicationCategoryType</key>  <string>public.app-category.utilities</string>
    <key>NSHighResolutionCapable</key>    <true/>
    <key>NSPrincipalClass</key>           <string>NSApplication</string>
</dict>
</plist>
PLIST

ICNS="$ROOT/Assets/AppIcon.icns"
if [ -f "$ICNS" ]; then
    echo "==> Иконка приложения"
    cp "$ICNS" "$APP/Contents/Resources/AppIcon.icns"
else
    echo "==> Иконка не найдена ($ICNS) — соберите её: bash scripts/generate-icons.sh" >&2
fi

echo "==> Ad-hoc подпись бандла"
codesign --force --sign - --timestamp=none "$APP"
codesign --verify --verbose "$APP"

echo "==> Сборка DMG (hdiutil)"
rm -f "$DMG"
STAGING="$DIST/staging"
rm -rf "$STAGING"
mkdir -p "$STAGING"
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGING" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGING"

echo
echo "==> Готово:"
echo "    Бандл: $APP"
echo "    DMG:   $DMG"
ls -lh "$DMG"
