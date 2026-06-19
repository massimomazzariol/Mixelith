# Architecture

Mixelith is an Android-first Flutter app organized around local photo import, editing, export, and optional user-provided local ONNX model experiments.

The architecture keeps platform APIs, storage, image processing, and UI concerns separated so the app can stay offline-first and easy to audit.

## Project Structure

```text
lib/
|-- app/        # app shell, theme, global providers
|-- core/       # shared policy and utility code
|-- features/   # home, camera, import, editor, batch, export, local models
|-- filters/    # procedural filters and local ONNX adapters
|-- media/      # Android media/photo access abstractions
|-- shared/     # reusable UI widgets
`-- storage/    # app-private cache handling
```

## Core Principles

- UI code talks to app abstractions, not directly to Android media, camera, export, or ONNX runtime APIs.
- Procedural filters remain available without any model files.
- Imported photos are copied into app-private cache before editing.
- Exports are re-encoded before saving to the gallery.
- Public builds do not bundle model binaries.
- The app must not require network access.

## Main Flows

### Open Photo

```text
Android picker/document result
  -> app-private cache copy
  -> working image
  -> editor
  -> procedural filter stack or local ONNX run
  -> export re-encode
  -> Android gallery
```

### Take Photo

```text
camera capture
  -> temporary local file
  -> working image import
  -> editor
```

Camera support is photo-only. `CAMERA` is expected; `RECORD_AUDIO` is forbidden.

### Batch Export

```text
multi-photo picker
  -> app-private cache copies
  -> queue
  -> selected procedural filter or compatible local ONNX model
  -> one-at-a-time exports
```

Batch items are processed sequentially so one failed image does not stop the whole queue.

## Local ONNX Support

Mixelith can import compatible ONNX files selected by the user on Android. Imported files are copied into app-private storage and validated before use.

The public release has important limits:

- No ONNX models are bundled.
- No model download flow is included.
- Fixed-size or incompatible models may be rejected.
- ONNX output must preserve the source aspect ratio.
- No square crop, tiling, or upscale path is used for ONNX processing.

## Export Model

Exports are generated from pixels and written as JPEG or PNG. This avoids copying original files and prevents original image metadata from being carried into the saved result.

## Platform Scope

Android is the product target for 0.1.0. Windows is useful for development checks, but Android is the platform used for real picker, camera, gallery, and permission validation.
