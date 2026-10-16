#!/bin/bash
# Builds WidgetStudio.app into ./dist
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="Widget Studio"
EXECUTABLE="WidgetStudio"
BUNDLE_ID="com.alexpogyl.widgetstudio"
VERSION="1.0.0"
BUILD_CONFIG="release"

echo "==> Building ($BUILD_CONFIG)…"
swift build -c "$BUILD_CONFIG"

BIN_PATH="$(swift build -c "$BUILD_CONFIG" --show-bin-path)"
DIST="dist"
APP="$DIST/$APP_NAME.app"

echo "==> Assembling $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_PATH/$EXECUTABLE" "$APP/Contents/MacOS/$EXECUTABLE"

if [ -f "Resources/AppIcon.icns" ]; then
  cp "Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
  ICON_ENTRY='<key>CFBundleIconFile</key><string>AppIcon</string>'
else
  ICON_ENTRY=''
fi

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key><string>ru</string>
    <key>CFBundleExecutable</key><string>$EXECUTABLE</string>
    <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
    <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
    <key>CFBundleName</key><string>Widget Studio</string>
    <key>CFBundleDisplayName</key><string>Widget Studio</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundleVersion</key><string>$VERSION</string>
    $ICON_ENTRY
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><false/>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key><true/>
</dict>
</plist>
PLIST

echo "==> Signing (ad-hoc)"
codesign --force --sign - --timestamp=none "$APP" >/dev/null 2>&1 || \
  echo "   (codesign skipped)"

echo "==> Done: $APP"
echo "    Запуск: open \"$APP\""
