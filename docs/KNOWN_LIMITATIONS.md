# Known Limitations

Mixelith 0.1.0 is usable, but still intentionally small.

## Platform

- Android is the product target.
- Windows is only a development target.
- iOS is not part of the 0.1.0 release.

## Filters

- Procedural filters are included and offline.
- Visual tuning will continue after more real-photo testing.
- Filter stack reordering and per-filter removal are not included yet.

## Batch Export

- Batch export is sequential and simple.
- Per-photo custom settings inside a batch are not included yet.

## Local ONNX Support

- No ONNX models are bundled.
- Users must provide compatible local ONNX files themselves.
- Fixed-size or incompatible models may be rejected.
- Runtime behavior depends on the model and device.
- ONNX and procedural stacks are not combined yet.

## Release Packaging

- The GitHub release is available as a local APK download.
- Store packaging is outside the 0.1.0 release scope.
