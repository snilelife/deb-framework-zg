#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ARTIFACTS_DIR="$ROOT_DIR/artifacts"
rm -rf "$ARTIFACTS_DIR"
mkdir -p "$ARTIFACTS_DIR"

DYLIB_PATH="$ROOT_DIR/build/Release-iphoneos/ZGPredictionOverlay.dylib"
AUTO_FRAMEWORK_PATH="$ROOT_DIR/build/Build/Products/Release-iphoneos/ZGPredictionOverlay.framework"
FRAMEWORK_PATH="$ROOT_DIR/build/Build/Products/Release-iphoneos/ZGPredictionOverlayKit.framework"

if [[ -f "$DYLIB_PATH" ]]; then
  (cd "$(dirname "$DYLIB_PATH")" && zip -qry "$ARTIFACTS_DIR/ZGPredictionOverlay.dylib.zip" "$(basename "$DYLIB_PATH")")
fi

if [[ -d "$AUTO_FRAMEWORK_PATH" ]]; then
  (cd "$(dirname "$AUTO_FRAMEWORK_PATH")" && zip -qry "$ARTIFACTS_DIR/ZGPredictionOverlay.framework.zip" "$(basename "$AUTO_FRAMEWORK_PATH")")
fi

if [[ -d "$FRAMEWORK_PATH" ]]; then
  (cd "$(dirname "$FRAMEWORK_PATH")" && zip -qry "$ARTIFACTS_DIR/ZGPredictionOverlayKit.framework.zip" "$(basename "$FRAMEWORK_PATH")")
fi

if [[ -d "$ROOT_DIR/artifacts_bundle" ]]; then
  rm -rf "$ROOT_DIR/artifacts_bundle"
fi
mkdir -p "$ROOT_DIR/artifacts_bundle"

[[ -f "$DYLIB_PATH" ]] && cp "$DYLIB_PATH" "$ROOT_DIR/artifacts_bundle/"
[[ -d "$AUTO_FRAMEWORK_PATH" ]] && cp -R "$AUTO_FRAMEWORK_PATH" "$ROOT_DIR/artifacts_bundle/"
[[ -d "$FRAMEWORK_PATH" ]] && cp -R "$FRAMEWORK_PATH" "$ROOT_DIR/artifacts_bundle/"
cp -R include docs README.md "$ROOT_DIR/artifacts_bundle/"

(cd "$ROOT_DIR" && zip -qry "$ARTIFACTS_DIR/ZGPredictionOverlay_AUTO_START_BUNDLE.zip" artifacts_bundle)
rm -rf "$ROOT_DIR/artifacts_bundle"

echo "Artifacts:"
find "$ARTIFACTS_DIR" -maxdepth 1 -type f -print
