#!/bin/bash
set -e

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SRC_DIR")"
APP_NAME="NSWPORTIOS"
APP_BUNDLE="$BASE_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "Compilando binario de NSWPORTIOS con swiftc..."
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS" "$RESOURCES"

swiftc -parse-as-library \
    -target arm64-apple-macosx14.0 \
    -O \
    "$SRC_DIR/NSWPORTIOS_App.swift" \
    -o "$MACOS/$APP_NAME"

cat << 'PLIST' > "$CONTENTS/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>es</string>
    <key>CFBundleExecutable</key>
    <string>NSWPORTIOS</string>
    <key>CFBundleIdentifier</key>
    <string>org.nswportios.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>NSWPORTIOS</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST

chmod +x "$MACOS/$APP_NAME"
echo "✓ Aplicación creada con éxito en: $APP_BUNDLE"
