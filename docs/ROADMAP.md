# Roadmap

Mixelith 0.1.0 is the first public release of the app. The product direction stays focused: local Android photo filtering, offline processing, and careful support for compatible local model experiments.

## Current Release

- Android-first Flutter app.
- Camera capture.
- Android photo picker import.
- Single-photo editor.
- Procedural filter stack.
- Batch export.
- JPEG and PNG export.
- Local ONNX model import for user-provided compatible models.
- No bundled model binaries.
- No network permission.

## Near-Term Work

- Improve procedural filter calibration on real photos.
- Improve editor polish, comparison tools, and filter management.
- Refine batch export and repeat-workflow controls.
- Expand local ONNX compatibility notes for project-owned style models.
- Keep ONNX support behind local import, compatibility checks, and explicit user selection.

## Future Development

- Continue the Forjyn companion pipeline for training, exporting, and validating project-owned ONNX style models.
- Add clearer model validation reporting for users testing their own local files.
- Tune more procedural looks around real-world photo sets.
- Prepare cleaner release packaging after the 0.1.0 release.

## Out Of Scope For 0.1.0

- Account system.
- Backend service.
- Analytics.
- Ads.
- Runtime model downloads.
- Bundled ONNX models.
- Cloud processing.
- iOS production release.
