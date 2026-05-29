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

- Advanced batch processing.
- Stack reordering.
- Removal of individual filters from the stack.
- Full parameter sliders.
- Share sheet.
- GPU/shader spike.
- Machine learning only in the remote future, not for 0.1.0.
- iOS.
