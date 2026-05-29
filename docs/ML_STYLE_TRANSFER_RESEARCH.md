# On-Device Style Transfer Research: Mixelith

This document records a controlled research spike for offline artistic style transfer models. It does not make machine learning filters product-ready, does not replace the existing procedural filters, and does not authorize runtime downloads or cloud inference.

## Research Goal

Mixelith needs stronger artistic looks than the current procedural filters can provide. The desired direction includes neon, pop, watercolor, mosaic, poster, and oil/starry-style effects that run fully on device.

Hard requirements:

- Offline Android execution.
- No runtime model downloads.
- No `android.permission.INTERNET`.
- No cloud inference.
- No backend, login, analytics, ads, Firebase, or share sheet.
- No model binaries committed unless source, license, and size are documented.
- No public product labels based on artist names.
- Machine learning code must stay isolated from UI.

## Candidate Matrix

| Candidate name | Source URL | Source type | Runtime | Offline capable | Android ready | Model file available | License found | Approx model size | Expected quality | Integration risk | Verdict | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| TensorFlow Lite Artistic Style Transfer, int8 | [TFLite overview](https://www.tensorflow.org/lite/examples/style_transfer/overview), [TensorFlow blog](https://blog.tensorflow.org/2020/04/optimizing-style-transfer-to-run-on-mobile-with-tflite.html), [Android example](https://github.com/tensorflow/examples/tree/master/lite/examples/style_transfer/android) | Official | TFLite | Yes | Yes | Yes | Sample code Apache-2.0; model binary license not independently verified in this spike | Prediction 2.83 MB, transfer 0.28 MB by HTTP HEAD | Promising arbitrary style transfer, mobile optimized | Medium | Try now after model-license approval | Best technical fit. Uses style prediction plus style transfer model. Needs style reference assets or precomputed style embeddings. |
| TensorFlow Lite Artistic Style Transfer, fp16 | [TensorFlow blog](https://blog.tensorflow.org/2020/04/optimizing-style-transfer-to-run-on-mobile-with-tflite.html) | Official | TFLite | Yes | Yes, especially with GPU delegate | Yes | Sample code Apache-2.0; model binary license not independently verified in this spike | Prediction 4.71 MB, transfer 0.42 MB by HTTP HEAD | Potentially better than int8 | Medium-high | Research later | Larger and likely better with GPU delegate. CPU-first int8 is the safer first spike. |
| TensorFlow Hub / Kaggle arbitrary image stylization | [TF Hub handle in TensorFlow overview](https://www.tensorflow.org/lite/examples/style_transfer/overview) | TF Hub / Kaggle | TF Hub SavedModel or TFLite handles | Yes if downloaded and bundled | TFLite variant appears Android-ready | Yes | Unclear from accessible model page in this spike | Same TFLite sizes when using the lite handles | Promising | Medium | Try after license confirmation | Useful source for model download handles. Do not fetch at runtime. |
| TensorFlow examples Android app | [GitHub example](https://github.com/tensorflow/examples/tree/master/lite/examples/style_transfer/android), [README](https://raw.githubusercontent.com/tensorflow/examples/master/lite/examples/style_transfer/android/README.md), [license](https://raw.githubusercontent.com/tensorflow/examples/master/LICENSE) | Official GitHub | Native Android TFLite | Yes | Yes | Gradle downloads models | Example code Apache-2.0; model binary license still needs confirmation | Not directly committed by the sample | Good reference implementation | Medium | Use as implementation reference | Confirms Android flow, two-model pipeline, background execution, and physical-device expectation. |
| `tflite_flutter` | [pub.dev package](https://pub.dev/packages/tflite_flutter) | Flutter package | TFLite | Yes | Yes | No model included | Apache-2.0 | Package only | Depends on selected model | Medium | Added for local-only isolated spike | Published by `tensorflow.org`, supports Android execution without cloud inference. Model files remain uncommitted. |
| `fast_style_transfer_flutter` | [pub.dev package](https://pub.dev/packages/fast_style_transfer_flutter) | Flutter package | TFLite | Yes | Claimed | No model included | MIT | Package only | Unknown | High | Reject as dependency | Low adoption and unverified uploader. May be useful as a read-only reference, but not as a dependency. |
| Hugging Face `leonelhs/arbitrary-image-stylization-v1` | [Model card](https://huggingface.co/leonelhs/arbitrary-image-stylization-v1) | Hugging Face | TF-Keras | Yes after download | No direct mobile artifact | Keras model available | MIT listed | Unknown | Potentially good | High | Research later | Not immediately TFLite-ready for Mixelith. Would require conversion and validation. |
| Hugging Face style-transfer listings and Spaces | [Style-transfer model listing](https://huggingface.co/models?other=style-transfer) | Hugging Face | Mostly PyTorch, Spaces, or unknown | Unknown | No | Usually no mobile-ready TFLite artifact | Varies or unclear | Often unknown or large | Varies | High | Reject for now | Most findings are not immediately offline Android-ready. |
| ONNX Model Zoo Fast Neural Style Transfer | [ONNX model card](https://huggingface.co/onnxmodelzoo/udnie-9), [ONNX models repo](https://github.com/onnx/models) | ONNX / GitHub | ONNX | Yes | Not without ONNX runtime integration | Yes | Apache-2.0 listed on model card | Around 6.6 MB per fixed style | Good fixed-style examples | High | Research later | Secondary path only if TFLite blocks. Would require ONNX Runtime dependency and Android validation. |
| MicroAST | [Paper](https://arxiv.org/abs/2211.15313), [GitHub](https://github.com/EndyWon/MicroAST) | Paper / GitHub | PyTorch | Yes after local packaging | No direct mobile artifact | PyTorch code/weights path, not TFLite | MIT code license | Unknown for deployable mobile artifact | Promising on paper | High | Research later | Interesting lightweight architecture, but not Android-ready without conversion and validation. |

## Primary Spike Target

Primary target: **TensorFlow Lite Artistic Style Transfer, int8 arbitrary-image-stylization model**.

Reasons:

- Official TensorFlow Lite source and Android sample.
- Designed for mobile on-device execution.
- Small model pair based on measured response headers:
  - prediction model: 2,828,838 bytes;
  - transfer model: 284,398 bytes.
- No network is needed if the models are bundled as assets.
- Two-stage architecture allows future optimization by precomputing style embeddings for fixed Mixelith styles.
- It aligns with Mixelith's privacy rule: all processing remains local.

## Why Integration Did Not Proceed Yet

The first research spike did **not** add `tflite_flutter`, did **not** commit model binaries, and did **not** expose an experimental filter.

Reason: the official sample code license is clear, but this spike did not find an independently clear license page for the model binary files themselves that is suitable for committing them to this repository. The model source URLs and sizes are documented, but the binary license must be confirmed before adding model files.

## Phase 1J-A License Gate

The Phase 1J-A license gate re-checked the official TensorFlow Lite arbitrary image stylization int8 model pair before any model or dependency integration.

Exact int8 model URLs reviewed:

- Prediction model: `https://storage.googleapis.com/download.tensorflow.org/models/tflite/task_library/style_transfer/android/magenta_arbitrary-image-stylization-v1-256_int8_prediction_1.tflite`
- Transfer model: `https://storage.googleapis.com/download.tensorflow.org/models/tflite/task_library/style_transfer/android/magenta_arbitrary-image-stylization-v1-256_int8_transfer_1.tflite`

Findings:

- The TensorFlow blog confirms the model is intended for mobile TensorFlow Lite use and that int8 and fp16 versions are available through TensorFlow Hub.
- The official TensorFlow examples Android sample includes a Gradle download script for these exact storage URLs.
- The TensorFlow examples repository and the Gradle script are Apache-2.0 licensed.
- The accessible Kaggle model metadata documentation confirms that Kaggle model records support a `licenseName` field, but the public target model page did not expose a clear license value for the exact `.tflite` binaries during this gate.
- The binary files were reachable and their sizes were confirmed by HTTP HEAD:
  - int8 prediction: 2,828,838 bytes;
  - int8 transfer: 284,398 bytes.

Gate result: **blocked**.

Reason: the sample code license and model hosting are official, but the exact binary license, public GitHub redistribution permission, app-use permission, and attribution requirements for the model files are still not explicit enough to satisfy Mixelith's repository policy.

No model file, style reference asset, ML dependency, inference code, or experimental ML filter was added.

## Phase 1J-B Local-Only Spike

Phase 1J-B adds a license-safe local testing path without committing model binaries.

What changed:

- `tflite_flutter` was added as an isolated dependency for a local developer spike.
- Model binaries are ignored by Git under `assets/models/style_transfer/`.
- `scripts/download_style_transfer_models.ps1` can download the official int8 model pair locally.
- The app does not download models at runtime.
- The app still builds and runs when model files are missing.
- Project-owned abstract style references were generated under `assets/style_references/`.
- ML runtime code is isolated under `lib/filters/ml/`.
- No UI imports TensorFlow Lite.
- No experimental ML filters are exposed in the normal UI until local inference is verified.

Local model assets:

```text
assets/models/style_transfer/style_prediction_int8.tflite
assets/models/style_transfer/style_transfer_int8.tflite
```

These files must remain untracked. They are suitable only for local evaluation until binary redistribution and app-use terms are confirmed.

Style reference assets:

```text
assets/style_references/neon_heat_style.png
assets/style_references/watercolor_wash_style.png
assets/style_references/mosaic_tiles_style.png
assets/style_references/oil_night_style.png
```

These are project-generated abstract images and do not use third-party artwork or public artist labels.

Inference status:

- Minimal two-model pipeline code exists in `MlStyleTransferEngine`.
- If models are missing, it returns a controlled unavailable result.
- If models are present on Android, the engine attempts style prediction, style transfer, and cache output.
- This has not yet been validated with local model files on a device in this repository state.
- Experimental ML filters are not exposed in UI.

Export status:

- Existing procedural export remains unchanged.
- ML export is not productized.
- If a local caller receives a cached ML output, it is only a preview-spike artifact unless export behavior is separately validated.

Next safe steps:

1. Obtain an authoritative license statement for the exact TFLite model binaries, or explicit approval from the rights holder/source.
2. If acceptable, download the int8 prediction and transfer models into `assets/models/style_transfer/`.
3. Run the local download script and validate inference on Android.
4. Inspect tensor summaries if inference fails.
5. Keep the feature experimental until Android performance and output quality are validated.

## Phase 1J-C Local Validation

Phase 1J-C validated the ignored local model workflow on an Android emulator without committing model binaries.

Local model download:

- `scripts/download_style_transfer_models.ps1` downloaded the official int8 model pair into `assets/models/style_transfer/`.
- `style_prediction_int8.tflite` was present locally at 2,828,838 bytes.
- `style_transfer_int8.tflite` was present locally at 284,398 bytes.
- Both `.tflite` files remained ignored by Git and were not committed.

Tensor inspection:

| Model | Tensor | Type | Shape | Bytes |
| :--- | :--- | :--- | :--- | ---: |
| Prediction input | `style_image` | `float32` | `[1, 256, 256, 3]` | 786,432 |
| Prediction output | `mobilenet_conv/Conv/BiasAdd` | `float32` | `[1, 1, 1, 100]` | 400 |
| Transfer input | `content_image` | `float32` | `[1, 384, 384, 3]` | 1,769,472 |
| Transfer input | `mobilenet_conv/Conv/BiasAdd` | `float32` | `[1, 1, 1, 100]` | 400 |
| Transfer output | `transformer/expand/conv3/conv/Sigmoid` | `float32` | `[1, 384, 384, 3]` | 1,769,472 |

Validation result:

- Inference ran through the isolated `MlStyleTransferEngine` on `emulator-5554`.
- The validation app generated a local test content image, ran style prediction with the project-owned `neon_heat_style.png` reference, ran style transfer, and wrote a cached JPEG output.
- Output was created at 384x384 and decoded successfully.
- The output differed from the input with mean absolute RGB difference `56.527`.
- Debug emulator processing time reported by the app was approximately `11.47s`.
- The `flutter run` wrapper timed out while attaching to the debug service, but Android logcat contained the successful validation output. Treat this as a local spike result, not a product benchmark.

Quality observation:

- The output is visibly stylized, so the model path is technically viable.
- The first `neon_heat_style.png` result was painterly and strongly transformed, but muddy/green rather than the desired warm neon/pop direction.
- Style reference design and possible embedding calibration are required before exposing any ML look to users.

Decision:

- Keep experimental ML filters hidden.
- Do not expose ML filters as product-ready.
- Do not implement ML export yet.
- Continue only as a tuning/research track unless licensing, quality, and performance improve.

## Proposed Architecture If Approved

```text
assets/models/style_transfer/
  -> bundled TFLite model files
  -> ML style transfer engine
  -> cache output
  -> editor preview only if inference succeeds
```

Expected files:

```text
lib/filters/ml/
|-- ml_style_transfer_engine.dart
|-- ml_style_transfer_model_info.dart
`-- ml_style_transfer_result.dart
```

Rules:

- `tflite_flutter` must not be imported by UI code.
- The ML engine must run outside the UI thread.
- Windows preview must degrade gracefully if native TFLite libraries are unavailable.
- Android remains the product target.
- No runtime downloads.
- No network permissions.
- Existing procedural filters must stay available.

## Open Risks

- Model binary redistribution/license must be confirmed.
- Style reference images or precomputed style embeddings need their own source/license audit.
- App size increases by at least the bundled model size and any style assets.
- Inference speed must be tested on a mid-range Android device.
- Output quality must be tested on real photos, not only sample images.
- TFLite desktop support may need native library setup on Windows; Android-only execution may be safer for the first implementation.
- Arbitrary style transfer may not perfectly match Mixelith's desired named looks without carefully chosen style references or embeddings.

## Current Decision

Do not ship bundled model files yet. The local-only spike proves that the int8 model pair can run on Android through the isolated engine, but the first style reference output needs visual tuning and the binary redistribution license remains unresolved. The recommended next action is to tune project-owned style references and test real photos locally while separately obtaining a clean license source or explicit written approval before any public model bundling.

See `docs/THIRD_PARTY_LICENSES.md` for the license gate ledger.
