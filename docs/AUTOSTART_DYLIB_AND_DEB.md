# Auto-Start Dylib and Deb Packaging

This kit now has two build modes:

```text
ZGPredictionOverlayKit.framework
  Manual framework. The host app calls the public API.

ZGPredictionOverlay.dylib
  Auto-start dylib. When the app intentionally loads the dylib, its constructor waits for a UIKit window and starts the overlay.

ZGPredictionOverlay.framework
  Auto-start framework for signers that require a zip containing a .framework folder.
```

## Build the Auto-Start Dylib

Install full Xcode and select it:

```bash
sudo xcode-select -s /Applications/Xcode.app
```

Then run:

```bash
chmod +x scripts/build_ios_dylib.sh
scripts/build_ios_dylib.sh
```

Output:

```text
build/Release-iphoneos/ZGPredictionOverlay.dylib
```

## Use With an IPA Signer

Add this dylib to your own app/signing flow:

```text
ZGPredictionOverlay.dylib
```

If the signer rejects that and says it expects a `.zip` containing a `.framework` or `.bundle` folder, build and upload:

```text
artifacts/ZGPredictionOverlay.framework.zip
```

Do not upload the full source package zip to the signer.

The signer must load the dylib into the app. When dyld loads it, the constructor runs, waits for the foreground `UIWindow`, and calls:

```objc
[ZGPredictionOverlayController startInWindow:window];
```

The overlay bubble/menu appears automatically. Real cue, pocket, bank, ball, and guide predictions become accurate when your app sends live geometry through:

```objc
ZGPredictionOverlayUpdateTable(table, cue, YES, balls, ballCount, guide);
```

Without live geometry, the dylib primes a safe default table so the overlay is visible immediately.

## Disable or Reattach at Runtime

The exported symbols are:

```objc
ZGPredictionOverlayAutoAttachNow();
ZGPredictionOverlayAutoStartSetEnabled(YES);
ZGPredictionOverlayAutoStartSetEnabled(NO);
```

You can also set these keys in the host app Info.plist or user defaults:

```text
ZGPredictionOverlayAutoStartEnabled = YES
ZGPredictionOverlayPrimeDefaultTable = YES
```

## Build a Framework Zip

For source-owned app integration:

```bash
chmod +x scripts/build_ios_framework.sh
scripts/build_ios_framework.sh
scripts/package_artifacts.sh
```

Output:

```text
artifacts/ZGPredictionOverlayKit.framework.zip
```

For signer upload:

```text
artifacts/ZGPredictionOverlay.framework.zip
```

## Build a Deb

For a jailbroken/Substrate-style package, build the dylib first, then package with your own target bundle identifier:

```bash
scripts/build_ios_dylib.sh
scripts/package_deb.sh com.yourcompany.yourapp
```

Output:

```text
artifacts/ZGPredictionOverlay_1.0.0_iphoneos-arm64.deb
```

For rootless layouts:

```bash
ZG_DEB_ROOTLESS=1 scripts/package_deb.sh com.yourcompany.yourapp
```
