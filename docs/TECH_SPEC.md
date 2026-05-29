# Technical Specification: Mixelith

This document defines the technical constraints of Mixelith for the Android 0.1.0 milestone.

## 1. Platform and Identifiers

- 0.1.0 Target: Android.
- Minimum SDK: Configured by the Flutter project, compatible with Android 5.0+.
- Flutter Project Name: `mixelith`.
- Android Package, Namespace, and applicationId: `com.mixelith`.
- GitHub Repository: `https://github.com/massimomazzariol/Mixelith.git`.
- Android remains the product target for 0.1.0.
- Windows desktop is a development/preview target for quick UI checks with placeholder assets.
- iOS, web, Linux, and macOS are not active priorities for 0.1.0, though Flutter scaffolds can remain in the repository.

## 2. No-Network

Mixelith must function entirely without network access. The `android.permission.INTERNET` permission must be absent from both source manifests and merged manifests.

Mandatory checks after Android builds:

- `build/app/intermediates/merged_manifests/debug/processDebugManifest/AndroidManifest.xml`
- `build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml`

If the generated paths change with a newer Gradle/Flutter version, the equivalent merged manifests must be found and documented in the worklog.

## 3. Android Permissions

0.1.0 uses `photo_manager 3.9.0` behind `MediaRepository`.

Declared permissions:

- Android <= 12 / API <= 32: `READ_EXTERNAL_STORAGE` with `android:maxSdkVersion="32"`.
- Android 13 / API 33+: `READ_MEDIA_IMAGES`.
- Android 13 / API 33+: `READ_MEDIA_VIDEO`, technically required by `photo_manager` even for image queries.
- Android 14 / API 34+: `READ_MEDIA_VISUAL_USER_SELECTED`.

Forbidden permissions:

- `android.permission.INTERNET`
- `android.permission.RECORD_AUDIO`
- `android.permission.ACCESS_FINE_LOCATION`
- `android.permission.ACCESS_COARSE_LOCATION`
- `android.permission.WRITE_EXTERNAL_STORAGE`
- `android.permission.ACCESS_MEDIA_LOCATION`

Mixelith only queries images via `RequestType.image`. The technical presence of `READ_MEDIA_VIDEO` does not enable video features in 0.1.0.

0.1.0 Camera Permission:

- `android.permission.CAMERA` is expected for `Take photo`.
- The camera must be photo-only.
- `RECORD_AUDIO` remains forbidden even after camera introduction.
- The official Flutter `camera` package remains isolated behind `features/camera/`.
- Unwanted transitive permissions from the camera plugin, such as `RECORD_AUDIO` or `WRITE_EXTERNAL_STORAGE`, must be explicitly removed from the merged manifest.

## 4. Cloud-Only Assets

The app must verify whether the selected asset is available locally. If a photo requires download from the cloud, Mixelith must not attempt network access and must show a clear message.

Reference message:

> This photo is stored in the cloud and is not available offline on this device. Please select a photo that has been downloaded locally.

## 5. Local Cache

- The cache uses `PathProviderCacheService`.
- Dedicated cache folder: `mixelith_cache`.
- The cache contains only local temporary files.
- Operations must exist for file writing, clearing expired files, and complete cache purging.
- No temporary files must be uploaded to external services.

## 6. Image Policy

Values in `ImageSizePolicy`:

- Preview max long side: `1080.0`.
- Export max long side default: `4096.0`.
- Warning threshold: `6000.0`.

The preview must use a downscaled copy to protect RAM and the UI thread. The export can use higher resolutions within explicit limits, showing a warning when necessary.

## 7. Export and EXIF

0.1.0 Formats:

- JPEG, recommended default, quality 90.
- PNG, optional for graphic effects with sharp edges.

The current export decodes pixels and re-encodes the final file. No original EXIF tags are copied.

0.1.0 must introduce an explicit `removeMetadata` option:

- Default is ON;
- OFF is unavailable until a real metadata preservation strategy exists;
- No UI should promise metadata preservation if it is not implemented.

## 8. Performance

- Heavy CPU filters must run outside the UI thread via `compute` or isolates.
- Sliders must use a debounce, typically 150-250ms.
- Obsolete results must be discarded if a new job arrives.
- Do not promise a constant 60fps for complex CPU filters.

## 9. Runtime Dependencies

Approved dependencies:

- `flutter_riverpod`
- `camera`
- `photo_manager`
- `image`
- `path_provider`
- `color_filter_extension`
- `gal`

Any new dependency must be approved in `docs/DEPENDENCY_DECISIONS.md` before use.

The camera uses `enableAudio: false` and does not enable video capture.
