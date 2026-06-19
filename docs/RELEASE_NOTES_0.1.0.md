# Mixelith 0.1.0 Release Notes

Mixelith 0.1.0 is an offline-first Android photo filtering app built with Flutter.

## Highlights

- Open a local photo through Android picker/document APIs.
- Capture a new still photo with the camera flow.
- Apply included procedural artistic filters.
- Stack filters and clear the stack.
- Export JPEG or PNG results.
- Batch export multiple selected photos.
- Import compatible user-provided local ONNX models for on-device testing.

## Privacy

- No account.
- No backend.
- No analytics.
- No ads.
- No `android.permission.INTERNET`.
- Images and imported model files stay on the device.

## Model Policy

No ONNX, ORT, TFLite, PyTorch, or other model binaries are bundled in this release.

## Manual Review Checklist

- Install the release APK on an Android device.
- Open a local photo and apply at least one procedural filter.
- Capture a photo and verify it opens in the editor.
- Export JPEG and PNG results.
- Run a small batch export.
- Open the Local models screen and confirm the no-model state is clear.
