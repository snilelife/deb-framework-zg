# Do This First

If your signer screen says it expects a `.framework` or `.bundle` folder inside the zip, upload this built artifact:

```text
artifacts/ZGPredictionOverlay.framework.zip
```

Build it on a Mac with full Xcode:

```bash
sudo xcode-select -s /Applications/Xcode.app
chmod +x scripts/build_ios_framework.sh scripts/package_artifacts.sh
scripts/build_ios_framework.sh
scripts/package_artifacts.sh
```

Do not upload the full source zip to the signer. That zip is for building.

If your signer supports raw dylibs, the artifact you want is:

```text
build/Release-iphoneos/ZGPredictionOverlay.dylib
```

Build the dylib on a Mac with full Xcode:

```bash
sudo xcode-select -s /Applications/Xcode.app
chmod +x scripts/build_ios_dylib.sh
scripts/build_ios_dylib.sh
```

Then add `ZGPredictionOverlay.dylib` in your signer. The dylib has an auto-start constructor, so once your signer loads it into your own app, the overlay starts with the app.

Optional package forms:

```bash
scripts/package_artifacts.sh
scripts/package_deb.sh com.yourcompany.yourapp
```

The overlay includes the floating menu, cue line, pocket path, bank/bounce paths, ghost ball, detected balls, centerlines, route cycling, style cycling, pocket selection, bounce count, and line length controls.
