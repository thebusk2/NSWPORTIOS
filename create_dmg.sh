#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DMG_NAME="NSWPORTIOS_macOS.dmg"
DMG_PATH="$DIR/$DMG_NAME"
TMP_DIR="/tmp/nswportios_dmg_root"

echo "Preparando estructura del DMG..."
rm -rf "$TMP_DIR" "$DMG_PATH"
mkdir -p "$TMP_DIR"

# Copiar la App limpia sin AppleDouble
cp -R "$DIR/NSWPORTIOS.app" "$TMP_DIR/"
dot_clean "$TMP_DIR/NSWPORTIOS.app"

# Crear enlace simbolico a /Applications
ln -s /Applications "$TMP_DIR/Applications"

# Copiar scripts y README
cp "$DIR/README.md" "$TMP_DIR/LEEME.txt"

echo "Creando imagen de disco DMG con hdiutil..."
hdiutil create -volname "NSWPORTIOS" -srcfolder "$TMP_DIR" -ov -format UDZO "$DMG_PATH"
rm -rf "$TMP_DIR"

echo "✓ DMG creado con éxito en: $DMG_PATH"
