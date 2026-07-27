#!/bin/zsh
set -euo pipefail

ROOT_DIR="/Users/mini/Documents/时钟桌面显示app"
DIST_DIR="$ROOT_DIR/dist"
APP_NAME="PressureClock.app"
APP_PATH="$DIST_DIR/$APP_NAME"
DMG_PATH="$DIST_DIR/PressureClock-macOS-universal.dmg"
STAGING_DIR="$DIST_DIR/.dmg-root"
BACKGROUND_PATH="$DIST_DIR/dmg-background.png"
BACKGROUND_SCRIPT="$ROOT_DIR/scripts/generate_dmg_background.swift"
VOLUME_NAME="PressureClock"

echo "==> Building latest universal Release package"
zsh "$ROOT_DIR/scripts/package_release.sh"

echo "==> Preparing DMG staging folder"
rm -rf "$STAGING_DIR" "$DMG_PATH" "$BACKGROUND_PATH"
mkdir -p "$STAGING_DIR"
ditto "$APP_PATH" "$STAGING_DIR/$APP_NAME"
swift "$BACKGROUND_SCRIPT" "$BACKGROUND_PATH"

echo "==> Creating styled DMG"
create-dmg \
  --volname "$VOLUME_NAME" \
  --background "$BACKGROUND_PATH" \
  --window-pos 180 120 \
  --window-size 640 420 \
  --text-size 14 \
  --icon-size 128 \
  --icon "$APP_NAME" 160 245 \
  --hide-extension "$APP_NAME" \
  --app-drop-link 480 245 \
  --format UDZO \
  --hdiutil-quiet \
  "$DMG_PATH" \
  "$STAGING_DIR"

rm -rf "$STAGING_DIR" "$BACKGROUND_PATH"
rm -f "$DIST_DIR"/rw.*.dmg "$DIST_DIR"/.PressureClock-temp.dmg

echo
echo "Done."
echo "DMG: $DMG_PATH"
