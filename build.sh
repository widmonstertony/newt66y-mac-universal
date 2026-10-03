#!/bin/zsh
set -euo pipefail

ROOT_DIR="${0:A:h}"
APP_NAME="小草 Mac 浏览器"
APP_DIR="$ROOT_DIR/dist/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
EXECUTABLE="$MACOS_DIR/NewT66yIntel"
ZIP_PATH="$ROOT_DIR/dist/NewT66y-Mac-Universal-v1.3.0.zip"
SDK_PATH="$(xcrun --sdk macosx --show-sdk-path)"
MODULE_CACHE_DIR="$ROOT_DIR/.build/ModuleCache"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR" "$MODULE_CACHE_DIR"

xcrun clang \
  -arch x86_64 \
  -arch arm64 \
  -mmacosx-version-min=12.0 \
  -fobjc-arc \
  -fmodules \
  -Wall -Wextra -Werror \
  -fmodules-cache-path="$MODULE_CACHE_DIR" \
  -isysroot "$SDK_PATH" \
  "$ROOT_DIR/Sources/main.m" \
  -framework AppKit \
  -framework WebKit \
  -framework Security \
  -framework MediaPlayer \
  -framework AVFoundation \
  -framework CoreMedia \
  -o "$EXECUTABLE"

cp "$ROOT_DIR/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$ROOT_DIR/Resources/BrowserBridge.js" "$RESOURCES_DIR/BrowserBridge.js"
cp "$ROOT_DIR/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
ditto "$ROOT_DIR/Resources/IOSUI" "$RESOURCES_DIR/IOSUI"
printf 'APPL????' > "$CONTENTS_DIR/PkgInfo"

if ! lipo "$EXECUTABLE" -verify_arch x86_64 ||
   ! lipo "$EXECUTABLE" -verify_arch arm64; then
  print -u2 "error: output executable is not Universal 2 (x86_64 + arm64)"
  exit 1
fi

codesign --force --deep --sign - "$APP_DIR"
codesign --verify --deep --strict --verbose=2 "$APP_DIR"

rm -f "$ZIP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$ZIP_PATH"

print "Built: $APP_DIR"
print "Archive: $ZIP_PATH"
file "$EXECUTABLE"
shasum -a 256 "$ZIP_PATH"
