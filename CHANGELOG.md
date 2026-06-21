# Changelog

## 0.1.1

- Added HEIC and HEIF photo import support on Android.
- Added HEIC and HEIF export options when supported by the device.
- Preserved HEIC and HEIF as the default export format for matching source photos when available.
- Added a JPEG fallback with a user-facing message when HEIC export is unavailable.
- Kept original source files untouched by processing app-private working copies.
- Kept public builds offline-first with no `INTERNET` permission.

## 0.1.0

- Added the first public Android release of Mixelith.
- Added local photo import, camera capture, and single-photo editing.
- Added procedural artistic filters and filter stacking.
- Added batch export for multiple local photos.
- Added JPEG and PNG export through the local re-encode flow.
- Added local ONNX model import support for user-provided compatible files.
- Kept public builds offline-first with no account, backend, analytics, ads, or `INTERNET` permission.
- Kept model binaries out of the repository and APK.
