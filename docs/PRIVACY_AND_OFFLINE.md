# Privacy And Offline Design

Mixelith is designed for local artistic photo filtering. Images stay on the device, and the app does not need a backend to work.

## Privacy Defaults

- No account.
- No backend.
- No analytics.
- No ads.
- No cloud inference.
- No runtime model downloads.
- No `android.permission.INTERNET`.

## Image Handling

Photos selected or captured by the user are copied into app-private cache before editing. The original file is not modified.

Exports are re-encoded before being saved to the gallery. Because the export is produced from pixels, original image metadata is not copied into the saved result.

## Android Permissions

Expected:

- `android.permission.CAMERA`, used for still-photo capture.
- Android media read permissions may be declared by platform media dependencies for compatibility across Android versions.

Forbidden:

- `android.permission.INTERNET`
- `android.permission.RECORD_AUDIO`
- `android.permission.ACCESS_NETWORK_STATE`
- location permissions
- `android.permission.WRITE_EXTERNAL_STORAGE`

## Local ONNX Files

The 0.1.0 release supports user-provided compatible ONNX files through local import. Imported files stay on the device and are copied into app-private storage.

Public builds do not bundle ONNX model binaries and do not download models.

## Manual Privacy Checks

Before publishing a build:

```bash
flutter build apk --release
```

Then verify:

- the release APK has no `INTERNET` permission;
- the release APK has no audio or location permissions;
- the release APK contains no `.onnx`, `.ort`, `.tflite`, `.pt`, or `.pth` files;
- exported images are generated through the app export flow, not copied from the original source file.
