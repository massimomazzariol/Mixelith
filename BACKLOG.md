# Backlog

Current Phase: **Phase 1J-C: local ML style transfer validation**.

## Must For 0.1.0

- Phase 1H: 0.1.0 scope realignment. Completed by this documentation pass.
- Phase 1I: real camera capture with Mixelith UI. Completed.
- Phase 1J: multi-photo selection from custom gallery.
- Phase 1K: ordered filter stack and `Clear all filters`.
- Phase 1L: filter thumbnails and filter calibration on real photos.
- Phase 1M: non-invasive compare via toggle or simple swipe.
- Phase 1N: export metadata toggle with clear decision.
- Phase 1O: 0.1.0 release candidate validation.
- `Take photo` must be a real feature, not a placeholder.
- `More photos` must be a real flow, not a placeholder.
- JPEG/PNG export must use the full stack.
- Validation on real Android 14/15 device.
- Official Mixelith launcher icon.
- Keep `android.permission.INTERNET` absent.
- Keep `android.permission.RECORD_AUDIO` absent.

## Already Built Foundation

- Phase 1C: minimal custom gallery on top of `MediaRepository`. Completed.
- Phase 1D: working image import and preview cache. Completed.
- Phase 1E: first 5 default filters. Completed.
- Phase 1E.1: visual UI alignment. Completed.
- Phase 1F: JPEG/PNG export, metadata scrub re-encode, and `gal` integration. Completed.
- Phase 1G: Android emulator validation on API 36 according to limited access policy. Completed.
- Phase 1I: real camera capture, cache import, and editor handoff. Completed.
- Limited photo access Android API 36: circumscribed with dedicated UX when the system grants limited access but the media backend returns no assets.
- Windows development preview support. Completed.
- Android emulator testing guide. Completed.

## Should

- Confirm redistribution terms for the official TensorFlow Lite style transfer model files before committing any model binary. Phase 1J-A rechecked this and the gate remains blocked.
- Run local-only style transfer testing with ignored model files using `scripts/download_style_transfer_models.ps1`.
- Validate the isolated `tflite_flutter` spike on additional real Android photos after the first local emulator validation.
- Tune project-owned style references before exposing any ML filter.
- Evaluate whether on-device style transfer changes the 0.1.0 scope or remains a later track.
- Evaluate native Android Photo Picker for true limited/single-photo access.
- Validate metadata scrub with dedicated EXIF tool on exported JPEG and PNG.
- Test filter/export performance on a mid-range Android device with large photos.
- Improve empty/error states where real cases emerge.
- Validate cloud-only assets with a real media library.
- Verify merged manifest during every major build.

## Later

- On-device style transfer filters if the TensorFlow Lite spike proves acceptable in quality, size, performance, and licensing.
- Product ML exposure remains blocked until model redistribution is resolved and visual quality is approved.
- Advanced batch processing with complex presets.
- Reordering of the filter stack.
- Removal of a single filter from the stack.
- Full parameter sliders.
- Share sheet.
- GPU/shader spike.
- Machine learning only in the remote future, not for 0.1.0.
- iOS.
