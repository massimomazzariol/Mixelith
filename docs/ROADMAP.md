# Project Roadmap: Mixelith

The roadmap guides Mixelith toward a real, stable **0.1.0 release**, not just a technical MVP. Android is the product target; Windows remains a development preview.

## Status Summary

```text
Phase 0  Documentation and local setup                     Completed
Phase 1A Initial dependencies and architectural skeleton    Completed
Phase 1B MediaRepository and cache foundation               Completed
Phase 1C Minimal custom gallery                            Completed
Phase 1D Working image import and preview cache            Completed
Phase 1E First 5 default filters                           Completed
Phase 1E.1 Visual UI Alignment                             Completed
Phase 1F Export JPEG/PNG, re-encode, and gal               Completed
Phase 1G Android emulator validation on API 36             Completed
Phase 1H 0.1.0 scope realignment                           Completed
Phase 1I Camera capture                                    Completed
Phase 1J-A ML style transfer license gate                  Blocked
Phase 1J-B Local style transfer experiment                 Experimental
Phase 1J-C Local style transfer validation                 Experimental
Phase 1J Multi-photo selection                             Next
Phase 1K Filter stack and clear all                        Planned
Phase 1L Filter calibration and thumbnails                  Planned
Phase 1M Non-invasive compare toggle/swipe                  Planned
Phase 1N Export metadata toggle                             Planned
Phase 1O 0.1.0 release candidate validation                 Planned
```

## Completed Phases

### Phase 1C: Minimal Custom Gallery

Objective: Show an essential local gallery on top of `MediaRepository`.

Completed Deliverables:

- Permission status management.
- Lazy-loaded grid of images.
- Loading/empty/error states.
- Permission-denied and limited fallback handling.

### Phase 1D: Working Image and Preview Cache

Objective: Import a real photo, copy it to the cache, and generate a secure preview.

Completed Deliverables:

- Working image model.
- Temporary original copy.
- Max 1080px preview.
- Handling of assets not available locally.

### Phase 1E: First 5 Default Filters

Objective: Implement initial presets.

Completed Deliverables:

- Neon Pop.
- Watercolor Wash.
- Mosaic Tiles.
- Starry Oil.
- Graphic Poster.
- Discarding of obsolete results.

### Phase 1E.1: Visual UI Alignment

Objective: Align the Flutter UI with Mixelith's visual identity.

Completed Deliverables:

- Centralized dark theme.
- Home screen with CTA.
- Refined gallery and editor.
- Filter rail with thumbnails.

### Phase 1F: Export

Objective: Save JPEG/PNG to gallery with metadata scrubbing via re-encoding.

Completed Deliverables:

- Export settings.
- JPEG quality slider.
- PNG support.
- Re-encoding without original metadata.
- `gal` adapter.
- Large-image warnings.

### Phase 1G: Android Validation

Objective: Validate the technical MVP flow on Android emulator API 36.

Completed Deliverables:

- Full access, denied access, and limited fallback verified according to the limited access policy.
- Real gallery, import, filters, compare, JPEG/PNG export, and airplane mode validated on emulator API 36.
- Limited photo access circumscribed: not fully supported if Android does not return selected assets.

### Phase 1H: 0.1.0 Scope Realignment

Objective: Redefine what Mixelith 0.1.0 stable actually means.

Deliverables:

- Realigned product specification.
- Updated 0.1.0 roadmap.
- Updated backlog.
- Planned architecture for camera, multi-photo, filter stack, compare, and metadata toggle.
- Updated 0.1.0 testing checklist.

## Phase 1I: Camera Capture

Objective: Make `Take photo` a real feature.

Completed Deliverables:

- Integrated official Flutter `camera` package.
- Mixelith camera screen with preview, back button, and capture button.
- `android.permission.CAMERA` permission expected and verified.
- `android.permission.RECORD_AUDIO` absent.
- `enableAudio: false` in camera controller.
- Captured photo in the same `WorkingImage` pipeline.
- Windows preview shows informative fallback without initializing camera.

Acceptance:

- No video.
- No audio.
- No `INTERNET`.
- No `image_picker` as the main shortcut.

## Phase 1J: Multi-Photo Selection

Objective: Make `More photos` a real flow.

Deliverables:

- Multi-select in custom gallery.
- Multi-selection state management.
- Selected photo queue.
- Application of the same filter stack to multiple photos.
- Multiple export to the gallery.

Out of Scope for 0.1.0:

- Advanced batch processing.
- Reordering photos.
- Advanced individual editing in batch mode.

## Phase 1J-A: ML Style Transfer License Gate

Objective: Confirm whether the official TensorFlow Lite arbitrary image stylization model pair can be safely committed and used as an offline Android spike.

Status: Blocked.

Findings:

- The official TensorFlow Lite model pair remains the best technical candidate for on-device artistic style transfer.
- The exact model files and sizes are documented in `docs/ML_STYLE_TRANSFER_RESEARCH.md`.
- The sample code license is clear, but the model binary redistribution and app-use terms remain unclear.
- No `tflite_flutter` dependency, model binary, style reference asset, inference code, or experimental filter was added.

Next action:

- Obtain an authoritative license statement or explicit approval for the exact model binaries before starting an implementation spike.

## Phase 1J-B: Local Style Transfer Experiment

Objective: Allow local developer testing of the official TensorFlow Lite int8 style transfer model pair without committing model binaries.

Status: Experimental.

Deliverables:

- `tflite_flutter` added behind `lib/filters/ml/`.
- Model binaries ignored by Git.
- Local PowerShell download script for the official int8 model pair.
- Project-generated abstract style references.
- Missing-model fallback that keeps procedural filters working.
- No experimental ML filters exposed in normal UI until inference is locally validated.

Product rule:

- Public release with bundled models remains blocked until redistribution and app-use terms are confirmed.

## Phase 1J-C: Local Style Transfer Validation

Objective: Validate whether the ignored local TensorFlow Lite style transfer model pair can actually run and produce output on Android.

Status: Experimental.

Findings:

- Local model download succeeded and the `.tflite` files stayed ignored by Git.
- Tensor inspection matched the expected prediction-plus-transfer model pipeline.
- Android emulator validation produced a cached 384x384 style transfer output.
- The output differed significantly from the input, but the first style reference was not visually aligned with Mixelith's desired warm neon/pop direction.
- Experimental ML filters remain hidden.

Product rule:

- Continue only as research/tuning until licensing, quality, and performance are all acceptable.

## Phase 1K: Filter Stack and Clear All

Objective: Transform filters from a single choice to an ordered stack.

Deliverables:

- `EditorState` with ordered list of applied filters.
- New filter applied on top of the previous result.
- `Original` as base image without stack.
- Mandatory `Clear all filters` button.
- Export of the full stack.

Out of Scope for 0.1.0:

- Reordering the stack.
- Single-filter removal.

## Phase 1L: Filter Calibration and Thumbnails

Objective: Make filters readable and convincing on real photos.

Deliverables:

- Clear miniature previews for each filter.
- Neon Pop actually looks neon.
- Watercolor Wash looks more like watercolor.
- Mosaic Tiles immediately recognizable.
- Starry Oil has a more painterly/textured feel.
- Graphic Poster looks more like a print/poster.
- Replacement or calibration of unconvincing filters.

## Phase 1M: Non-Invasive Compare

Objective: Replace the invasive compare tool.

Deliverables:

- Remove drag-comparison helper text.
- `Original` / `Modified` toggle/icon or simple swipe.
- Clear visible state of the shown version.
- Export results independent of compare mode.

## Phase 1N: Export Metadata Toggle

Objective: Replace the long text in export sheet with a clear control.

Current Decision:

- `Remove metadata` toggle.
- Default ON.
- OFF unavailable until real metadata preservation exists.
- No false promises of EXIF preservation.

## Phase 1O: 0.1.0 Release Candidate Validation

Objective: Validate 0.1.0 on real devices.

Deliverables:

- Real Android 14/15 device testing.
- Manifest check: no `INTERNET`, no `RECORD_AUDIO`, no forbidden permissions.
- `CAMERA` present for still-photo capture.
- JPEG/PNG stack export.
- Metadata validation with dedicated tool.
- Performance testing on mid-range Android device.
- Official launcher icon.

## Future

- On-device artistic style transfer after license approval, model bundling validation, Android performance testing, and explicit product-scope approval.
- Advanced batch processing.
- Stack reordering.
- Removal of individual filters from the stack.
- Full parameter sliders.
- Share sheet.
- GPU/shader spike.
- Machine learning only in the remote future, not for 0.1.0.
- iOS.
