# Privacy & Offline Policy: Mixelith

Mixelith is designed to process personal images locally. Privacy is not an optional feature: it is an architectural constraint.

## No-Network

The `android.permission.INTERNET` permission must be absent from:

- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/debug/AndroidManifest.xml`
- `android/app/src/profile/AndroidManifest.xml`
- Debug and release merged manifests.

Mixelith must not make HTTP calls, DNS requests, cloud SDK calls, or remote submissions.

## Camera Permissions

For 0.1.0, `Take photo` is a product requirement and is implemented using an internal camera view:

- `android.permission.CAMERA` is an expected permission on Android;
- The permission must be documented in the merged manifests;
- The camera must capture photos only;
- `android.permission.RECORD_AUDIO` remains forbidden;
- Video capture remains out of scope;
- The original shot is not automatically saved to the public gallery;
- The shot goes into the temporary cache first and then into the editor;
- Any audio/storage permissions declared transitively by the camera plugin must be explicitly removed from the final manifest;
- No images must be uploaded or sent off the device.

## No Identity, No Tracking, No Ads

The following are forbidden:

- Login or registration;
- Firebase or cloud services;
- Analytics and telemetry;
- Remote crash reporting;
- Advertising SDKs;
- Integrated social sharing in 0.1.0.

## Cloud-Only Assets

If a photo is visible in the gallery but is not available locally, Mixelith must not attempt to download it. It must halt the flow and show a clear message.

Reference message:

> This photo is stored in the cloud and has not been downloaded to this device. Mixelith works entirely offline to protect your privacy. Please select an image saved locally.

## EXIF Scrubbing

During the current export flow:

- The final image is reconstructed from pixels via decode and re-encode;
- The original file is not copied to the gallery;
- Original EXIF metadata is not preserved;
- GPS coordinates, device models, and original timestamps are removed because the final file is encoded from scratch;
- JPEG and PNG files are saved starting from the temporary file generated in the cache.

This policy protects the user's privacy. It is not intended to bypass moderation systems or detectors.

## Metadata Toggle 0.1.0

0.1.0 must show a discrete export control for metadata:

- Expected label: `Remove metadata`;
- Default is ON;
- OFF must not be available until a real strategy for metadata preservation is implemented;
- The app must not pretend to preserve EXIF if the export continues to only encode pixels;
- If OFF is implemented in the future, it must be validated with a dedicated EXIF tool.

## Airplane Mode Acceptance Test

Each candidate build must pass a manual test in airplane mode.

| Step | Action | Expected Result |
| :--- | :--- | :--- |
| 1 | Enable airplane mode | No data connectivity |
| 2 | Start Mixelith | App starts without network errors |
| 3 | Open custom gallery | Local photos visible |
| 4 | Select cloud-only asset | Clear message, no crash |
| 5 | Select local photo | Editor opens with preview |
| 6 | Apply filter | Preview updates without blocking the UI |
| 7 | Export JPEG | File saved to gallery |
| 8 | Export PNG | File saved to gallery |
| 9 | Inspect saved files | No original EXIF metadata |
| 10 | Verify camera 0.1.0 | `CAMERA` present for photos only, `RECORD_AUDIO` absent |

The test is only passed if all steps are positive.
