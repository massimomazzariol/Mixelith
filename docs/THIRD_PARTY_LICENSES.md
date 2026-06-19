# Third-Party Licenses And Attribution

This document records public-facing third-party notes for Mixelith 0.1.0.

## App Dependencies

Mixelith uses Flutter/Dart packages and Android dependencies through `pubspec.yaml` and the Android Gradle project. Dependency licenses should be reviewed before any store release.

The 0.1.0 release includes a local ONNX Runtime Android dependency for user-imported compatible ONNX files:

| Component | Use | License note |
| --- | --- | --- |
| ONNX Runtime Android | Local Android inference for user-provided compatible ONNX files | ONNX Runtime is distributed under the MIT license. Preserve notices before broader redistribution. |

## Model Files

No ONNX, ORT, TFLite, PyTorch, or other model binaries are committed to this repository or bundled in the public APK.

User-provided local model files are imported through Android system file selection and copied into app-private storage. They are not redistributed by this repository.

## Demo Assets

The README screenshots use a generated demo image stored in:

```text
docs/screenshot_assets/demo_photo.png
```

The image is project-owned/generated for documentation and does not contain people, private photos, or downloaded third-party imagery.

## Future Model Policy

A model file may only be added to a public build if its exact source, license, redistribution permission, app-use permission, attribution requirements, file size, and runtime behavior are documented and approved.
