# Duplicate Symbol Fix

This package fixes the Codemagic linker error where both `ZGPookingEngine.o` and `ZGPredictionEngine.o` define the same `zg::PredictionEngine` functions.

The cause is usually that `project.yml` used a whole-folder source entry like:

```yaml
- path: src
```

That makes XcodeGen compile every `.cpp` / `.mm` file in `src`, including old renamed copies such as `ZGPredictionEngine.cpp`.

The fixed `project.yml` lists only the real implementation files:

```yaml
- path: src/ZGPookingOverlayController.mm
- path: src/ZGPookingEngine.cpp
- path: src/ZGPookingFrameScanner.cpp
- path: bridges/ZGPookingOverlayExports.mm
```

Keep only one implementation of `zg::PredictionEngine` in the framework target.
