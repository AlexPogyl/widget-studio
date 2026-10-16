#!/bin/bash
# Builds the WidgetKit extension (WidgetStudioWidgets.appex) without Xcode.
#
#     tools/build-widget-extension.sh [output-directory]
#
# The extension reuses the rendering code of the app, so the system widget looks
# exactly like the ones the app draws on the desktop.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

SDK="$(xcrun --show-sdk-path)"
ARCH="$(uname -m)"
TARGET="${ARCH}-apple-macos14.0"
OUT="${1:-build/widgets}"
APPEX="$OUT/WidgetStudioWidgets.appex"
EXECUTABLE="WidgetStudioWidgets"
BUNDLE_ID="com.alexpogyl.widgetstudio.widgets"
VERSION="1.0.0"

SOURCES=(
    Sources/WidgetStudio/App/Localization.swift
    Sources/WidgetStudio/Model/SettingValue.swift
    Sources/WidgetStudio/Model/SettingDescriptor.swift
    Sources/WidgetStudio/Model/SettingsBag.swift
    Sources/WidgetStudio/Model/PhotoStore.swift
    Sources/WidgetStudio/Model/WidgetAction.swift
    Sources/WidgetStudio/Model/WidgetStyle.swift
    Sources/WidgetStudio/Model/CommonSettings.swift
    Sources/WidgetStudio/Model/WidgetDefinition.swift
    Sources/WidgetStudio/Widgets/ClockWidget.swift
    Sources/WidgetStudio/Widgets/CalendarWidget.swift
    Sources/WidgetStudio/Widgets/PhotoWidget.swift
    Sources/WidgetStudio/Widgets/NoteWidget.swift
    Sources/WidgetStudio/Views/WidgetSurface.swift
    WidgetExtension/WidgetStudioWidgets.swift
)

echo "==> Compiling widget extension ($TARGET)"
rm -rf "$APPEX"
mkdir -p "$APPEX/Contents/MacOS"

xcrun swiftc \
    -sdk "$SDK" \
    -target "$TARGET" \
    -application-extension \
    -parse-as-library \
    -swift-version 5 \
    -O \
    -module-name "$EXECUTABLE" \
    -Xlinker -e -Xlinker _NSExtensionMain \
    "${SOURCES[@]}" \
    -o "$APPEX/Contents/MacOS/$EXECUTABLE"

cat > "$APPEX/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key><string>ru</string>
    <key>CFBundleExecutable</key><string>$EXECUTABLE</string>
    <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
    <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
    <key>CFBundleName</key><string>Widget Studio Widgets</string>
    <key>CFBundleDisplayName</key><string>Widget Studio</string>
    <key>CFBundlePackageType</key><string>XPC!</string>
    <key>CFBundleShortVersionString</key><string>$VERSION</string>
    <key>CFBundleVersion</key><string>$VERSION</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>NSExtension</key>
    <dict>
        <key>NSExtensionPointIdentifier</key><string>com.apple.widgetkit-extension</string>
    </dict>
</dict>
</plist>
PLIST

echo "==> Signing widget extension (ad-hoc + App Sandbox)"
codesign --force --sign - --timestamp=none \
    --entitlements WidgetExtension/WidgetStudioWidgets.entitlements \
    "$APPEX" 2>&1 | tail -2 || true
codesign --verify --verbose=1 "$APPEX" 2>&1 | tail -3 || true

echo "==> Done: $APPEX"
