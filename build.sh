#!/bin/bash
# Builds "Widget Studio.app" (with the WidgetKit extension inside) into ./dist
#
#     ./build.sh              собрать приложение
#     ./build.sh --register   ещё и зарегистрировать в системе (lsregister + pluginkit),
#                             чтобы системный виджет сразу появился в галерее
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
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" "$APP/Contents/PlugIns"
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
    <key>NSHumanReadableCopyright</key><string>MIT License</string>
    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLName</key><string>com.alexpogyl.widgetstudio.action</string>
            <key>CFBundleURLSchemes</key>
            <array><string>widgetstudio</string></array>
        </dict>
    </array>
</dict>
</plist>
PLIST

echo "==> Building the WidgetKit extension"
./tools/build-widget-extension.sh >/dev/null
cp -R "build/widgets/WidgetStudioWidgets.appex" "$APP/Contents/PlugIns/"

echo "==> Signing (ad-hoc)"
# The extension must keep its App Sandbox entitlement: macOS refuses to load
# unsandboxed plug-ins. Sign the nested bundle first, the app last.
codesign --force --sign - --timestamp=none \
  --entitlements WidgetExtension/WidgetStudioWidgets.entitlements \
  "$APP/Contents/PlugIns/WidgetStudioWidgets.appex" >/dev/null 2>&1 || \
  echo "   (extension codesign skipped)"
codesign --force --sign - --timestamp=none "$APP" >/dev/null 2>&1 || \
  echo "   (codesign skipped)"

if ! codesign -d --entitlements - "$APP/Contents/PlugIns/WidgetStudioWidgets.appex" 2>/dev/null | grep -q app-sandbox; then
  echo "   ⚠️  the widget extension lost its sandbox entitlement"
fi

echo "==> Done: $APP"

if [ "${1:-}" = "--register" ]; then
  echo "==> Registering with the system (widget gallery)"
  LSR=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
  "$LSR" -f "$PWD/$APP" || true
  pluginkit -a "$PWD/$APP/Contents/PlugIns/WidgetStudioWidgets.appex" || true
  echo "    Откройте приложение один раз, затем: правый клик по рабочему столу → «Изменить виджеты…»"
fi

echo "    Запуск: open \"$APP\""
