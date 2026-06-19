#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "xcodegen is required. Install with: brew install xcodegen"
  exit 1
fi

rm -rf build generated ZGPredictionOverlayKit.xcodeproj
mkdir -p generated build

xcodegen generate --spec project.yml

for SCHEME in ZGPredictionOverlayFramework ZGPredictionOverlayKit; do
  xcodebuild \
    -project ZGPredictionOverlayKit.xcodeproj \
    -scheme "$SCHEME" \
    -configuration Release \
    -sdk iphoneos \
    -destination 'generic/platform=iOS' \
    -derivedDataPath build \
    build \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY="" \
    DEVELOPMENT_TEAM=""
done

echo "Built products:"
find build/Build/Products/Release-iphoneos -maxdepth 2 -print

echo
echo "Use this signer-ready framework zip after running scripts/package_artifacts.sh:"
echo "  artifacts/ZGPredictionOverlay.framework.zip"
echo
echo "For the auto-start raw dylib, run:"
echo "  scripts/build_ios_dylib.sh"
