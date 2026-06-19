#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v xcrun >/dev/null 2>&1; then
  echo "xcrun is required. Install full Xcode, then run: sudo xcode-select -s /Applications/Xcode.app"
  exit 1
fi

SDK_PATH="$(xcrun --sdk iphoneos --show-sdk-path 2>/dev/null || true)"
if [[ -z "$SDK_PATH" || ! -d "$SDK_PATH" ]]; then
  echo "iPhoneOS SDK was not found."
  echo "Install full Xcode, open it once, then run:"
  echo "  sudo xcode-select -s /Applications/Xcode.app"
  exit 1
fi

OUT_DIR="$ROOT_DIR/build/Release-iphoneos"
OUT_DYLIB="$OUT_DIR/ZGPredictionOverlay.dylib"

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

xcrun --sdk iphoneos clang++ \
  -dynamiclib \
  -arch arm64 \
  -miphoneos-version-min=13.0 \
  -isysroot "$SDK_PATH" \
  -std=c++17 \
  -stdlib=libc++ \
  -fobjc-arc \
  -fvisibility=hidden \
  -fno-exceptions \
  -fno-rtti \
  -DZG_PREDICTION_OVERLAY_ENABLE_CONSTRUCTOR=1 \
  -I"$ROOT_DIR/include" \
  "$ROOT_DIR/src/ZGPredictionEngine.cpp" \
  "$ROOT_DIR/src/ZGPredictionOverlayController.mm" \
  "$ROOT_DIR/src/ZGPredictionOverlayAutoStart.mm" \
  "$ROOT_DIR/bridges/ZGPredictionOverlayExports.mm" \
  -framework Foundation \
  -framework UIKit \
  -framework QuartzCore \
  -framework CoreGraphics \
  -install_name "@rpath/ZGPredictionOverlay.dylib" \
  -o "$OUT_DYLIB"

echo "Built: $OUT_DYLIB"
if command -v file >/dev/null 2>&1; then
  file "$OUT_DYLIB"
fi

