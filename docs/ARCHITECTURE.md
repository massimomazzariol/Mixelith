# Architecture Specification: Mixelith

Mixelith follows a feature-first structure with clear boundaries between UI, domain, and technical adapters.

## Project Structure

```text
lib/
|-- main.dart
|-- app/
|   |-- app.dart
|   `-- providers.dart
|-- core/
|   |-- errors/
|   |-- policy/
|   `-- utils/
|-- features/
|   |-- camera/
|   |   |-- domain/
|   |   |-- data/
|   |   |-- presentation/
|   |   `-- providers/
|   |-- import/
|   |   |-- domain/
|   |   |-- presentation/
|   |   `-- providers/
|   |-- editor/
|   |   |-- domain/
|   |   |-- presentation/
|   |   `-- providers/
|   `-- export/
|       |-- domain/
|       |-- presentation/
|       `-- providers/
|-- filters/
|   |-- domain/
|   |-- engines/
|   |-- ml/
|   |-- presets/
|   `-- registry/
|-- media/
|   |-- domain/
|   `-- data/
`-- storage/
    |-- domain/
    `-- data/
```

## UI Isolation Rule

The UI must not directly import:

- `photo_manager`
- `image`
- `gal`
- `saver_gallery`
- `color_filter_extension`
- Experimental GPU or mosaic filter libraries.

The UI communicates with abstractions via Riverpod. External packages must remain behind dedicated repositories, services, or engines.

## Modules

### `app/`

Contains `MixelithApp`, the theme, `MaterialApp`, and minimal global providers.

### `media/`

Abstraction for local gallery access.

- Domain: `MediaRepository`, `MediaAsset`, `MediaAssetAvailability`, `MediaPermissionStatus`.
- Data: Concrete Android implementation with `photo_manager` and a development repository for Windows previews.

### `storage/`

Abstraction for local cache.

- Domain: `CacheService`.
- Data: `PathProviderCacheService`.
- Default cache folder: `mixelith_cache`.

### `filters/`

Autonomous filter system.

- Domain: Preset, parameters, result, engine type.
- Engines: `CpuFilterEngine`, future color matrix engine, other future engines.
- ML: Local-only TensorFlow Lite spike under `filters/ml/`, isolated from UI and disabled when local model files are missing.
- Registry: `DefaultFilterRegistry` for initial presets.
- The filtered preview is written to the local cache and does not modify the original preview.

### `features/import`

Minimal custom gallery on top of `MediaRepository`.

- Domain: `ImportGalleryState`.
- Future 0.1.0 Domain: Multi-select state and a queue of selected assets.
- Domain service: `WorkingImageImportService`, coordinating file resolution, cache copying, and preview generation.
- Providers: `ImportGalleryController`, domain-level thumbnail provider, and import controller.
- Presentation: Gallery screen, 3-column grid, thumbnail tile, and permission states.
- 0.1.0: Separate but coherent flows for `Open photo` and `More photos`.
- UI does not import `photo_manager` and does not receive `AssetEntity`.
- On Windows, the same UI uses placeholder assets via `DevMediaRepository`.

### `features/camera`

Real camera capture for 0.1.0, isolated from the rest of the UI.

- Domain: Captured photo model and capture result.
- Data: `CameraService`, adapter to the official Flutter `camera` package.
- Providers: `CameraCaptureController`, handoff to `WorkingImageImportService`.
- Presentation: `CameraCaptureScreen` with preview, loading, error, and still-photo capture states.
- Expected Android permission: `android.permission.CAMERA`.
- Forbidden permission even with camera: `android.permission.RECORD_AUDIO`.
- The camera only captures photos, not video.
- `image_picker` is not the main shortcut unless a new explicit decision is made.
- On Windows desktop previews, the home screen shows an informative fallback and does not initialize the camera plugin.

### `features/editor`

Image preview, `WorkingImage`, filter stack, essential parameters, and processing state.

- Domain: `WorkingImage`, session model for the image ready for editing.
- Domain: `EditorState`, state of the original preview, filter stack, and processed result.
- Expected 0.1.0 Domain: `AppliedFilter` and an ordered list `filterStack`.
- Providers: `EditorController`, managing selected filters, loading, and discarding obsolete results.
- Presentation: Editor with visible cache preview, filter rail, minimal stack view, and `Clear all filters`.
- 0.1.0 Compare Mode: Non-invasive toggle or swipe between original and stack result.
- Export must always use the full stack, not the compare state.

### `features/export`

Format selection, JPEG quality, dimension policy, and saving to the gallery.

- Domain: `ExportSettings`, `ExportRepository`, `ExportSaveResult`, `ExportState`.
- Domain service: `ExportService`, generating the final re-encoded file in the cache.
- Data: `GalExportRepository` for Android and `DevExportRepository` for Windows preview.
- Providers: `ExportController`, repository provider, and service provider.
- Presentation: Export bottom sheet in the editor.
- 0.1.0: `ExportSettings` must include an explicit metadata option.
- Current decision: `removeMetadata` default is ON; OFF is unavailable until real metadata preservation exists.
- The UI does not import `gal` and does not import `image`.

## Core Models

```dart
enum MediaAssetAvailability {
  localAvailable,
  unavailableCloudOnly,
  permissionDenied,
  unsupportedFormat,
}
```

```dart
enum MediaPermissionStatus {
  notDetermined,
  authorized,
  limited,
  denied,
  restricted,
}
```

```dart
abstract class MediaRepository {
  Future<MediaPermissionStatus> getPermissionStatus();
  Future<MediaPermissionStatus> requestPermissionStatus();
  Future<List<MediaAsset>> getRecentAssets({int page, int pageSize});
  Future<Uint8List?> getThumbnailData(MediaAsset asset);
  Future<MediaAssetFile?> getOriginalFile(MediaAsset asset);
}
```

```dart
class MediaAssetFile {
  final String path;
  final String extension;
  final int width;
  final int height;
  final MediaAssetAvailability availability;
}
```

```dart
class WorkingImage {
  final String sourceAssetId;
  final String originalTempPath;
  final String previewPath;
  final int originalWidth;
  final int originalHeight;
  final int previewWidth;
  final int previewHeight;
}
```

```dart
class AppliedFilter {
  final String presetId;
  final Map<String, double> parameterValues;
  final DateTime appliedAt;
}
```

```dart
class EditorState {
  final WorkingImage? workingImage;
  final List<AppliedFilter> filterStack;
  final String? filteredPreviewPath;
  final CompareMode compareMode;
}
```

```dart
enum CompareMode {
  modified,
  original,
}
```

```dart
abstract class FilterEngine {
  Future<FilterResult> apply({
    required String inputPath,
    required FilterPreset preset,
    Map<String, double> parameterValues,
  });
}
```

```dart
class ImageSizePolicy {
  static const double previewMaxLongSide = 1080.0;
  static const double exportMaxLongSideDefault = 4096.0;
  static const double warningThreshold = 6000.0;
}
```

```dart
enum ExportFormat { jpeg, png }
```

```dart
class ExportSettings {
  final ExportFormat format;
  final int jpegQuality;
  final bool removeMetadata;
}
```

```dart
abstract class ExportRepository {
  Future<ExportSaveResult> saveImage({
    required String filePath,
    required String fileName,
    required ExportFormat format,
  });
}
```

## Data Pipeline

```text
photo_manager AssetEntity
  -> MediaRepository
  -> Verify permissions and local availability
  -> MediaAssetFile
  -> WorkingImageImportService
  -> Copy original to local cache
  -> JPEG preview max 1080px in local cache
  -> WorkingImage
  -> Filter stack
  -> EditorController
  -> CpuFilterEngine
  -> Preview stack result in local cache
  -> FilterResult
  -> ExportSettings
  -> ExportService
  -> Decode pixels from original in cache
  -> Secure resize if necessary
  -> Full stack
  -> Re-encode JPEG/PNG with removeMetadata default ON
  -> ExportRepository
  -> GalExportRepository on Android
  -> Android gallery
```

## Local ML Spike Pipeline

```text
ignored local TFLite model files
  -> MlStyleTransferEngine under filters/ml/
  -> project-generated style reference
  -> content preview image
  -> local TensorFlow Lite inference on Android if models are present
  -> cache output for spike validation
```

Rules:

- Model files under `assets/models/style_transfer/` are ignored by Git.
- The app never downloads models at runtime.
- UI code must not import TensorFlow Lite.
- Windows preview must continue to work without native TensorFlow Lite runtime setup.
- Procedural filters remain the product fallback.

## Camera Pipeline 0.1.0

```text
camera plugin
  -> CameraCaptureController
  -> Temporary local photo file
  -> WorkingImageImportService
  -> Cache and preview
  -> Editor
```

The camera pipeline must not introduce audio, video, uploads, or network permissions.

## Multi-Photo Pipeline 0.1.0

```text
MediaRepository
  -> Multi-select
  -> List of MediaAsset
  -> WorkingImage import/queue
  -> Shared filter stack
  -> Multiple export
  -> Android gallery
```

0.1.0 does not require photo reordering or advanced individual editing in the queue.

## Concurrency and UI

- Sliders must use a debounce.
- Filter jobs must be cancelable or discardable if obsolete.
- The UI thread must not execute heavy processing.
- Every asynchronous result must be associated with the request that generated it.
