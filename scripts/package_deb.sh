#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

BUNDLE_ID="${1:-${ZG_TARGET_BUNDLE_ID:-}}"
DYLIB_PATH="${2:-$ROOT_DIR/build/Release-iphoneos/ZGPredictionOverlay.dylib}"

if [[ -z "$BUNDLE_ID" ]]; then
  echo "Usage: scripts/package_deb.sh <target.bundle.id> [path/to/ZGPredictionOverlay.dylib]"
  echo "Example: scripts/package_deb.sh com.yourcompany.yourapp"
  exit 1
fi

if [[ ! -f "$DYLIB_PATH" ]]; then
  echo "Missing dylib: $DYLIB_PATH"
  echo "Build it first with: scripts/build_ios_dylib.sh"
  exit 1
fi

if ! command -v dpkg-deb >/dev/null 2>&1; then
  echo "dpkg-deb is required to build .deb packages."
  echo "Install it with: brew install dpkg"
  exit 1
fi

PACKAGE_ID="${ZG_PACKAGE_ID:-com.zg.predictionoverlay}"
PACKAGE_NAME="${ZG_PACKAGE_NAME:-ZG Prediction Overlay}"
PACKAGE_VERSION="${ZG_PACKAGE_VERSION:-1.0.0}"
ARCHITECTURE="${ZG_PACKAGE_ARCH:-iphoneos-arm64}"
ROOTLESS="${ZG_DEB_ROOTLESS:-0}"

PKG_ROOT="$ROOT_DIR/build/deb-root"
OUT_DIR="$ROOT_DIR/artifacts"
OUT_DEB="$OUT_DIR/ZGPredictionOverlay_${PACKAGE_VERSION}_${ARCHITECTURE}.deb"

if [[ "$ROOTLESS" == "1" ]]; then
  SUBSTRATE_DIR="var/jb/Library/MobileSubstrate/DynamicLibraries"
else
  SUBSTRATE_DIR="Library/MobileSubstrate/DynamicLibraries"
fi

rm -rf "$PKG_ROOT"
mkdir -p "$PKG_ROOT/DEBIAN" "$PKG_ROOT/$SUBSTRATE_DIR" "$OUT_DIR"

cp "$DYLIB_PATH" "$PKG_ROOT/$SUBSTRATE_DIR/ZGPredictionOverlay.dylib"

cat > "$PKG_ROOT/$SUBSTRATE_DIR/ZGPredictionOverlay.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Filter</key>
  <dict>
    <key>Bundles</key>
    <array>
      <string>${BUNDLE_ID}</string>
    </array>
  </dict>
</dict>
</plist>
PLIST

cat > "$PKG_ROOT/DEBIAN/control" <<CONTROL
Package: ${PACKAGE_ID}
Name: ${PACKAGE_NAME}
Version: ${PACKAGE_VERSION}
Architecture: ${ARCHITECTURE}
Description: Auto-starting ZG prediction overlay for the configured app bundle.
Maintainer: zav G
Author: zav G
Section: Tweaks
Priority: optional
CONTROL

dpkg-deb --root-owner-group -b "$PKG_ROOT" "$OUT_DEB"
echo "Built: $OUT_DEB"

