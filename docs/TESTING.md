# Testing: Mixelith

This guide covers development preview and Android gallery testing.

## Windows Preview

Windows desktop is a development preview target. It uses placeholder media through the development repository, so it does not exercise Android photo permissions or the real device gallery.

```bash
flutter run -d windows
```

Use Windows preview for:

- app startup;
- Android-only camera fallback message;
- dark UI layout;
- minimal gallery grid;
- placeholder tile selection;
- working image import from placeholder assets;
- preview cache rendering in the editor placeholder;
- applying default artistic filters to placeholder previews;
- quick widget flow checks.

Windows desktop builds require Visual Studio with the Desktop development with C++ workload.

## Android Emulator or Device

Real gallery behavior and photo permissions must be tested on Android.

```bash
flutter devices
flutter emulators
flutter emulators --launch <emulator_id>
flutter run -d <device_id>
```

Use Android for:

- camera permission prompts;
- camera preview and capture;
- media permission prompts;
- full photo access;
- denied photo access;
- limited photo access on Android 14;
- real gallery thumbnails;
- scrolling large libraries;
- selecting real images;
- opening the editor placeholder with a cached preview;
- applying default artistic filters to the cached preview;
- cloud-only behavior when reproducible.

## Phase 1I Checklist

### Windows Preview

- App opens from the home screen.
- Tapping `Take photo` shows the Android-only fallback.
- The camera plugin is not initialized on Windows.
- `Open photo` still opens the placeholder gallery.

### Android Emulator or Device

- App opens from the home screen.
- Tapping `Take photo` opens the camera screen.
- Android requests `android.permission.CAMERA` if needed.
- `android.permission.RECORD_AUDIO` is not requested.
- Camera preview appears or a clear no-camera/permission error appears.
- Capture creates a still photo only.
- The captured file is not saved automatically to the public gallery.
- Captured photo is copied into `mixelith_cache`.
- Preview max long side remains 1080px.
- Editor opens with the captured preview.
- Filters and export still work from the captured image.
- If emulator camera is unavailable, repeat on a real Android device.

## Phase 1C Checklist

- App opens.
- Permission flow appears on Android.
- Full access loads the grid.
- Denied access shows a clear message.
- Limited access shows either selected photos or the dedicated fallback if Android does not return selected assets.
- Grid scrolls without obvious jank.
- Thumbnails load.
- Tapping an image shows the selected image placeholder.
- Cloud-only asset behavior is checked if reproducible.

## Phase 1D Checklist

### Windows Preview

- App opens with the development placeholder grid.
- Tapping a placeholder shows a loading overlay.
- The editor placeholder opens.
- A real preview image is visible.
- Original and preview dimensions are shown.
- Returning from the editor goes back to the gallery.

### Android Emulator or Device

- App opens and permission flow still works.
- Full access loads local images.
- Denied access shows the permission message.
- Limited access on Android 14 keeps the limited access banner or shows the dedicated fallback if no selected assets are returned.
- Tapping a local image creates a working image.
- The editor placeholder opens with the cached preview.
- Large images are downscaled to a preview with max long side 1080px.
- Cloud-only or unresolved images show the offline message without crashing.

## Phase 1E Checklist

### Windows Preview

- App opens with the development placeholder grid.
- Tapping a placeholder opens the editor preview.
- Filter chips are visible: Original, Neon Pop, Watercolor, Mosaic, Starry Oil, Graphic Poster.
- Each filter shows a loading state and updates the preview.
- Rapid filter changes do not show stale older results after a newer filter finishes.
- Original returns to the unfiltered cached preview.

### Android Emulator or Device

- A real photo opens in the editor preview.
- Each default filter applies to the cached preview.
- The original gallery file is not modified.
- No export, save or share flow appears in this older phase.
- Large previews remain responsive enough for basic interaction.

## Phase 1F Checklist

### Windows Preview

- App opens from the home screen.
- Placeholder gallery opens.
- Tapping a placeholder opens the editor.
- A default filter can be applied.
- Export bottom sheet opens from the editor.
- JPEG export succeeds with the development preview success message.
- PNG export succeeds with the development preview success message.
- Large-image warning is visible when dimensions exceed the warning threshold.
- No share or batch flow appears. Camera capture is covered by the Phase 1I checklist.

### Android Emulator or Device

- A real photo opens in the editor.
- Export is disabled while a filter is still processing.
- Selected filter is used for export.
- Original selected exports an unfiltered but re-encoded image.
- JPEG export saves to gallery.
- PNG export saves to gallery.
- Exported files are re-encoded and do not preserve original EXIF metadata.
- Large images are resized to the safe export max long side.
- Airplane mode export works without network errors.
- No new forbidden permission appears in merged manifests.

## Phase 1G Validation Notes

### Emulator Session: Android 16 API 36

Validated on `sdk gphone64 x86 64` (`emulator-5554`):

- app startup;
- denied photo permission state;
- full photo access;
- real gallery thumbnail loading;
- tapping a real image;
- editor preview from cache;
- all default filters on a real image;
- original vs modified compare;
- JPEG export to gallery;
- PNG export to gallery;
- JPEG export in airplane mode;
- basic metadata scrub check by confirming the exported JPEG has no `Exif` marker.

Pending from this session:

- cloud-only asset behavior was not reproducible on the emulator;
- metadata scrub should be confirmed with a dedicated EXIF inspection tool before release.

### Limited Photo Access Policy

On Android 14+ and API 36, limited photo access can grant `READ_MEDIA_VISUAL_USER_SELECTED` while the current `photo_manager` integration returns no selected assets. For 0.1.0, Mixelith treats this as circumscribed, not fully supported:

- Full photo access is the supported custom gallery flow.
- If limited access returns assets, the gallery can show them with the limited access banner.
- If limited access returns no assets, the app shows a dedicated message instead of a generic empty gallery.
- The user is guided to retry with Full photo access.
- Android Photo Picker native integration can be evaluated later for true limited/single-photo selection without full gallery access.

## Metadata Validation Before Release

The current export pipeline decodes image pixels and re-encodes JPEG/PNG output instead of copying the original file. Before any release candidate is declared ready, run a dedicated metadata validation pass:

- Export at least one JPEG and one PNG from a real Android photo.
- Copy the exported files from the device to a desktop inspection environment.
- Inspect the files with a dedicated EXIF/metadata tool available in that environment.
- Confirm that GPS, camera model, device identifiers, timestamps from the original file and other sensitive original metadata are absent.
- Repeat the check for both `Original` export and at least one filtered export.
- Do not treat the app as release-ready until this validation is complete.

The earlier emulator check only confirmed that an exported JPEG did not contain an `Exif` marker. That is a useful smoke check, not a full metadata audit.

## Future On-Device Style Transfer Validation

If an offline style transfer spike is approved later, validate it before any product exposure:

- Confirm source and redistribution terms for every model binary.
- Confirm every model is bundled as an asset, not downloaded at runtime.
- Confirm `android.permission.INTERNET` remains absent.
- Confirm Windows preview either works or fails gracefully without breaking the app.
- Run tensor-shape inspection before attempting full inference.
- Run a small-image inference test.
- Test output quality on several real Android photos.
- Measure processing time and memory on a mid-range Android device.
- Verify export still re-encodes output without copying original metadata.
- Keep procedural filters available as fallback.

## V0.1.0 Checklist

0.1.0 stable requires validation beyond the current technical MVP.

### Camera Capture

- Camera screen opens from `Take photo`.
- Android asks for `android.permission.CAMERA` only when needed.
- `android.permission.RECORD_AUDIO` is absent from merged manifests.
- No video mode is exposed.
- Captured photo opens in the editor through the same cache/preview pipeline.
- Airplane mode camera capture works.

### Multi-Photo

- `More photos` opens a real multi-select flow.
- Multiple local photos can be selected.
- Selection state is clear.
- The selected set can be cancelled without side effects.
- The same filter stack can be applied to selected photos.
- Export multiple saves all expected files.

### Filter Stack

- Tapping filters adds them to the stack.
- Stack order is reflected in the preview.
- `Original` shows the base image without stack.
- `Clear all filters` empties the stack in one action.
- Export uses the full stack.
- Reorder and single-filter removal are not required for 0.1.0.

### Filter Readability

- Each filter thumbnail is visible and distinct.
- Neon Pop reads as neon.
- Watercolor Wash reads as watercolor.
- Mosaic Tiles reads as mosaic.
- Starry Oil reads as painterly/texture.
- Graphic Poster reads as poster/stamp.
- Results are checked on several real photos.

### Compare

- The previous drag-comparison prompt is absent.
- Compare uses a non-invasive toggle or swipe.
- The currently visible version is clear.
- Export result is independent from compare mode.

### Export Metadata Toggle

- Export sheet shows `Remove metadata` or equivalent.
- Default is ON.
- OFF is disabled or unavailable until real metadata preservation exists.
- The app does not imply metadata preservation unless it is implemented and tested.
- JPEG and PNG exports pass dedicated metadata inspection before release.

### Privacy and Manifest

- `android.permission.INTERNET` absent.
- `android.permission.RECORD_AUDIO` absent.
- `android.permission.CAMERA` present for still-photo capture.
- No backend, login, analytics, ads, Firebase or machine learning.

### Device Matrix

- Android emulator API 36.
- Real Android 14/15 device.
- Mid-range Android device for filter/export performance.
- Windows desktop preview for layout smoke checks only.

## Android Manifest Checks

After Android builds, inspect the merged manifests:

```bash
flutter build apk --debug
flutter build apk --release
```

Expected merged manifest paths:

```text
build/app/intermediates/merged_manifests/debug/processDebugManifest/AndroidManifest.xml
build/app/intermediates/merged_manifests/release/processReleaseManifest/AndroidManifest.xml
```

Forbidden permissions:

- `android.permission.INTERNET`
- `android.permission.RECORD_AUDIO`
- `android.permission.ACCESS_FINE_LOCATION`
- `android.permission.ACCESS_COARSE_LOCATION`
- `android.permission.WRITE_EXTERNAL_STORAGE`

Camera permission policy:

- `android.permission.CAMERA` is expected after Phase 1I;
- `android.permission.CAMERA` is used only for still-photo capture;
- `android.permission.RECORD_AUDIO` must remain absent.

Expected media permissions from `photo_manager`:

- `android.permission.READ_EXTERNAL_STORAGE` with `maxSdkVersion="32"`
- `android.permission.READ_MEDIA_IMAGES`
- `android.permission.READ_MEDIA_VIDEO`
- `android.permission.READ_MEDIA_VISUAL_USER_SELECTED`
