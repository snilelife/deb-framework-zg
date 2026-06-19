# Dynamic Library Notes

On iOS, the easiest legal packaging is a dynamic framework:

```text
ZGPredictionOverlayKit.framework/ZGPredictionOverlayKit
```

The inner `ZGPredictionOverlayKit` binary is a Mach-O dynamic library. A host app can embed and link that framework when it is built from source.

The manual framework target intentionally does not include:

```text
binary patching
third-party app hooks
```

Expected integration model:

```text
host app source -> links framework -> calls [ZGPredictionOverlayController startInWindow:]
```

Build options:

```text
1. Codemagic: use codemagic.yaml
2. Local Xcode: run scripts/build_ios_framework.sh
3. CMake: use CMakeLists.txt as a dynamic framework target
```

The public entry point is:

```objc
#import "ZGPredictionOverlayController.h"

[ZGPredictionOverlayController startInWindow:self.window];
```

For a dylib-style build, `bridges/ZGPredictionOverlayExports.mm` also provides exported C symbols:

```objc
ZGPredictionOverlayStartInWindow(window);
ZGPredictionOverlayUpdateTable(table, cue, YES, balls, ballCount, guide);
ZGPredictionOverlayStop();
```

The `ZGPredictionOverlay.dylib` target additionally compiles `src/ZGPredictionOverlayAutoStart.mm` with its constructor enabled. When that dylib is intentionally loaded by your own signed app, it waits for a foreground `UIWindow` and starts the overlay automatically.

For packaging details, see:

```text
docs/AUTOSTART_DYLIB_AND_DEB.md
```
