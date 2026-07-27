#!/bin/zsh
set -euo pipefail

ROOT_DIR="/Users/mini/Documents/时钟桌面显示app"
PROJECT_PATH="$ROOT_DIR/DesktopTimePressureClock.xcodeproj"
SCHEME_NAME="DesktopTimePressureClock"
DERIVED_DATA_DIR="$HOME/Library/Developer/Xcode/DerivedData/DesktopTimePressureClock-affctcaowqxtzjgnyxzspgfkksxh"
RELEASE_APP_PATH="$DERIVED_DATA_DIR/Build/Products/Release/PressureClock.app"
DIST_DIR="$ROOT_DIR/dist"
ZIP_PATH="$DIST_DIR/PressureClock-macOS-universal.zip"

mkdir -p "$DIST_DIR"
rm -rf "$DIST_DIR/PressureClock.app" "$ZIP_PATH"

echo "==> Building universal Release app"
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME_NAME" \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  ARCHS='arm64 x86_64' \
  ONLY_ACTIVE_ARCH=NO \
  build

echo "==> Copying app into dist"
ditto "$RELEASE_APP_PATH" "$DIST_DIR/PressureClock.app"

echo "==> Creating distributable zip"
ditto -c -k --sequesterRsrc --keepParent "$DIST_DIR/PressureClock.app" "$ZIP_PATH"

echo
echo "Done."
echo "App: $DIST_DIR/PressureClock.app"
echo "Zip: $ZIP_PATH"
echo "Architecture:"
file "$DIST_DIR/PressureClock.app/Contents/MacOS/PressureClock"
echo
echo "Code signature:"
codesign -dv --verbose=2 "$DIST_DIR/PressureClock.app" 2>&1 | sed -n '1,20p'
