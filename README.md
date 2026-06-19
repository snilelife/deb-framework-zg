# ZGPredictionOverlayKit

Drop-in prediction overlay module with two supported package forms:

```text
ZGPredictionOverlay.dylib
  Auto-start dylib for your own signed app. When the app loads the dylib, the overlay waits for a UIKit window and starts.

ZGPredictionOverlay.framework
  Auto-start dynamic framework zip for signers that require a .zip containing a .framework folder.

ZGPredictionOverlayKit.framework
  Manual dynamic framework for source-owned app integration. The host app calls the public API.
```

The overlay itself is the same in both forms: floating `ZG` menu, cue line, pocket/object path, bank/bounce paths, ghost ball, detected ball markers, centerlines, route/style cycling, manual pocket selection, bounce count, and line length controls.

## Files

```text
include/ZGPredictionOverlayController.h   Objective-C public API
include/ZGPredictionOverlayExports.h      Exported helper function prototypes
include/ZGPredictionEngine.hpp            C++ prediction engine API
include/ZGOverlayTypes.hpp                C++ data types
src/ZGPredictionOverlayController.mm      UIKit menu + overlay renderer
src/ZGPredictionOverlayAutoStart.mm       Auto-start window attach layer for dylib builds
src/ZGPredictionEngine.cpp                Aim prediction engine
bridges/ZGPredictionOverlayExports.mm     Exported C ABI helpers for dylib/framework builds
project.yml                               XcodeGen auto-framework + manual-framework + dylib project
CMakeLists.txt                            CMake auto-framework + manual-framework + dylib targets
scripts/build_ios_dylib.sh                Raw auto-start dylib build helper
scripts/build_ios_framework.sh            Xcode build helper
scripts/package_deb.sh                    Substrate-style deb package helper
scripts/package_artifacts.sh              Zip helper for dylib/framework/bundle outputs
examples/HostAppUsage.mm                  Minimal integration example
cocos2dx/                                 Optional Cocos2d-x adapter source
```

## Build Auto-Start Dylib

This is the main artifact for an IPA signer that supports adding and loading a dylib:

```bash
sudo xcode-select -s /Applications/Xcode.app
chmod +x scripts/build_ios_dylib.sh
scripts/build_ios_dylib.sh
```

Output:

```text
build/Release-iphoneos/ZGPredictionOverlay.dylib
```

Once your signer loads that dylib into your own app, the constructor runs and starts the overlay with the app.

## Build Dynamic Framework

From this folder:

```bash
chmod +x scripts/build_ios_framework.sh
scripts/build_ios_framework.sh
```

The build output is under:

```text
build/Build/Products/Release-iphoneos/
```

To create a zip:

```bash
scripts/package_artifacts.sh
```

Output:

```text
artifacts/ZGPredictionOverlayKit.framework.zip
```

For the signer screen that says it expects a zip containing a `.framework` or `.bundle` folder, use:

```text
artifacts/ZGPredictionOverlay.framework.zip
```

That is the auto-start framework. Do not upload the full source kit zip to the signer.

## Build Deb

Build the dylib first, then package for your app bundle id:

```bash
scripts/build_ios_dylib.sh
scripts/package_deb.sh com.yourcompany.yourapp
```

Output:

```text
artifacts/ZGPredictionOverlay_1.0.0_iphoneos-arm64.deb
```

## Host App Start Call

In the host app source:

```objc
#import "ZGPredictionOverlayController.h"

[ZGPredictionOverlayController startInWindow:self.window];
```

Then feed live table geometry whenever the cue/balls/guide line changes:

```objc
[ZGPredictionOverlayController updateTable:table
                                   cueBall:cue
                                hasCueBall:YES
                                     balls:balls
                                     count:ballCount
                                     guide:guide];
```

The overlay recomputes immediately on every `updateTable(...)` call. This clean kit only contains the menu, renderer, prediction engine, and exported start/update helpers.

## Exported Dylib-Friendly Functions

`include/ZGPredictionOverlayExports.h` and `bridges/ZGPredictionOverlayExports.mm` expose simple exported symbols:

```objc
#import "ZGPredictionOverlayExports.h"

ZGPredictionOverlayStartInWindow(window);
ZGPredictionOverlayStartInView(view);
ZGPredictionOverlayStop();
ZGPredictionOverlaySetVisible(YES);
ZGPredictionOverlayUpdateTable(table, cue, YES, balls, ballCount, guide);
ZGPredictionOverlayAutoAttachNow();
ZGPredictionOverlayAutoStartSetEnabled(YES);
```

These are included in both dynamic outputs and are useful from mixed Objective-C++ code in your own host app.

## Menu Features

- Draggable `ZG` bubble.
- Overlay ON/OFF.
- Cue prediction line ON/OFF.
- Pocket/object path ON/OFF.
- Bank/bounce paths ON/OFF.
- Route cycling:
  - Auto Hybrid
  - Guide Lock
  - Ball Geometry
  - Corner Lock
- Style cycling:
  - Simple
  - Advanced
  - Pro Video
- Auto/manual pocket selection.
- Bounce count.
- Line length.
- Ghost ball toggle.
- Detected balls toggle.
- Table centerline toggle.
- Dark floating menu with `created by zav G` footer.

## Important

A `.dylib` or dynamic framework will not run inside an app by itself. Your app/signing flow must actually load it. This package provides the auto-start overlay code inside the dylib; it does not patch binaries or bypass app security.

Detailed packaging notes are in:

```text
docs/AUTOSTART_DYLIB_AND_DEB.md
```
