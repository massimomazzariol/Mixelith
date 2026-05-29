# Dependency Decisions: Mixelith

This document records the approved dependencies and the rules for introducing new ones.

## Mandatory Criteria

Every new dependency must be evaluated before modifying `pubspec.yaml`.

1. Permissive license: MIT, BSD, or Apache 2.0.
2. No `android.permission.INTERNET` permission.
3. No analytics, tracking, remote crash logging, or telemetry.
4. No advertising SDKs.
5. No Firebase, cloud, or backend dependencies.
6. Transitive dependencies verified with `flutter pub deps`.
7. Merged manifest checked after Android builds.
8. Adapter mandatory when the library exposes infrastructural or rendering APIs.

## Approved Dependencies

| Package | Purpose | Status | Isolation |
| :--- | :--- | :--- | :--- |
| `flutter_riverpod` | State management and dependency injection | Approved | Providers in `app/` and features |
| `photo_manager` | Local gallery access on Android | Approved, mandatory | Only inside `media/data/` |
| `image` | Pure Dart CPU processing | Approved | Behind engines or services |
| `path_provider` | Local cache/temp paths | Approved | Only inside `storage/data/` |
| `color_filter_extension` | Fast color matrices | Approved | Behind color engines |
| `gal` | Gallery saving on Android | Approved | Behind export adapters |
| `camera` | Android camera capture | Approved in Phase 1I | Only inside `features/camera/` |

## Planned Dependencies for 0.1.0

No additional dependencies are planned before a subsequent technical decision.

Camera capture decision:

- `Take photo` is a 0.1.0 requirement.
- Package used: `camera`.
- Purpose: Android camera capture.
- Reason: Official Flutter package, controlled preview/capture inside Mixelith UI.
- Risks: Camera lifecycle, runtime permissions, and emulator/device behavior differences.
- Required Adapter: Yes, `CameraService` in `features/camera/data/`.
- Phase: 1I.
- The camera feature makes `android.permission.CAMERA` an expected permission.
- `android.permission.RECORD_AUDIO` remains forbidden.
- Video capture and audio remain out of scope.
- `CameraController` must use `enableAudio: false`.

## Proposed Dependency: `tflite_flutter`

Status: **researched, not added**.

- Purpose: Potential offline TensorFlow Lite inference for artistic style transfer.
- Proposed phase: Future isolated ML style transfer spike.
- Publisher: `tensorflow.org` on pub.dev.
- License: Apache-2.0 for the package.
- Why considered: It is the likely Flutter bridge for bundled TFLite models and supports Android execution without cloud inference.
- Required Adapter: Yes, under `lib/filters/ml/`.
- UI rule: No UI file may import `tflite_flutter`.
- Runtime rule: No model downloads at runtime and no `android.permission.INTERNET`.
- Phase 1J-A status: License gate still blocked.
- Current blocker: The exact model binary redistribution/license terms for the selected TFLite files remain unknown.
- Decision: Do not add the dependency until model files are approved and an isolated code spike is authorized.

## Excluded or Postponed Dependencies

| Package | Decision | Reason |
| :--- | :--- | :--- |
| `image_picker` | Do not use as architectural base | Does not support the 0.1.0 custom gallery |
| `wechat_assets_picker` | Out of scope for 0.1.0 | Pre-packaged UI and visual lock-in |
| `saver_gallery` | Future evaluation | Only useful if batch requirements arise |
| `flutter_mosaic` | Out of scope for 0.1.0 | Stability and premature integration risks |
| `flutter_image_filters` | Phase 6 or isolated spike | GPU/shader validation needed on Android hardware |

## Phase 1A Audit

- Approved initial dependencies added.
- Inspected dependencies with `flutter pub deps`.
- No Firebase, analytics, advertising, or tracking SDKs found.
- Tooling dependencies in the graph are not runtime telemetry or backend integrations.

## Phase 1B Audit

- No new dependencies added.
- `photo_manager` remains isolated inside `lib/media/data/`.
- `path_provider` remains isolated inside `lib/storage/data/`.
- `photo_manager 3.9.0` technically requires `READ_MEDIA_VIDEO` alongside `READ_MEDIA_IMAGES` on Android 13+, even if the query is only for images.
- Debug and release builds verified to be free of `INTERNET`, audio, location, or public storage write permissions; `CAMERA` was still absent at this stage as `Take photo` was not yet implemented.

## Phase 1I Audit

- Added `camera 0.12.0+1`.
- The package remains confined within `lib/features/camera/`.
- No use of `image_picker`, alternative camera wrappers, or `permission_handler`.
- `CameraController` is created with `enableAudio: false`.
- `android.permission.CAMERA` is expected in the merged manifests.
- `android.permission.RECORD_AUDIO` must remain absent in the merged manifests.
- `camera_android_camerax` also declares `RECORD_AUDIO` and `WRITE_EXTERNAL_STORAGE` transitively; the app manifest explicitly removes them using `tools:node="remove"`.
- `android.permission.INTERNET` must remain absent.

## Style Transfer Research Spike

- Evaluated official TensorFlow Lite artistic style transfer, TensorFlow Hub/Kaggle handles, TensorFlow examples, selected Flutter/GitHub wrappers, Hugging Face candidates, ONNX Model Zoo, and MicroAST.
- Primary target selected for a future code spike: official TensorFlow Lite arbitrary image stylization int8 model pair.
- Phase 1J-A re-checked the license gate and kept it blocked because the model binary license and redistribution terms were not explicit enough.
- No dependency was added.
- No model file was committed.
- No product filter was exposed.
- See `docs/ML_STYLE_TRANSFER_RESEARCH.md` and `docs/THIRD_PARTY_LICENSES.md`.

## Operational Rule

If any dependency introduces network features, logins, analytics, ads, Firebase, ML, or share sheets, it must be rejected for 0.1.0.
