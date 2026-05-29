# Third-Party License Review: Mixelith

This document records third-party license decisions for assets, model files, and external components that require explicit redistribution review before they can be committed to the public repository.

## License Gate Policy

Mixelith must not commit third-party binaries, model files, reference images, generated assets from third-party sources, or downloaded artifacts unless all of the following are known and documented:

1. Exact source URL.
2. Exact license.
3. Public GitHub redistribution permission.
4. App use permission.
5. Attribution and notice requirements.
6. File size.
7. No runtime download requirement.
8. No unclear mirror or unknown source.

If any item remains unclear, the file must not be committed.

## Reviewed Components

| Component | Source URL | License | Redistribution allowed | App use allowed | Attribution required | File committed | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| TensorFlow examples style transfer Android sample code | https://github.com/tensorflow/examples/tree/master/lite/examples/style_transfer/android | Apache-2.0 for repository code | Yes for code, subject to Apache-2.0 | Yes for code | Apache-2.0 notice retention | No | Useful implementation reference only. This does not by itself license the model binaries for redistribution. |
| TensorFlow examples `download_model.gradle` | https://raw.githubusercontent.com/tensorflow/examples/master/lite/examples/style_transfer/android/app/download_model.gradle | Apache-2.0 for the Gradle script | Yes for script, subject to Apache-2.0 | Yes for script | Apache-2.0 notice retention | No | Official script downloads the selected model files during sample builds. The script license does not independently prove model binary redistribution terms. |
| TFLite style prediction int8 model | https://storage.googleapis.com/download.tensorflow.org/models/tflite/task_library/style_transfer/android/magenta_arbitrary-image-stylization-v1-256_int8_prediction_1.tflite | Unknown for the binary | Unknown | Unknown | Unknown | No | Exact size observed by HTTP HEAD: 2,828,838 bytes. Do not commit until binary license and redistribution terms are confirmed. |
| TFLite style transfer int8 model | https://storage.googleapis.com/download.tensorflow.org/models/tflite/task_library/style_transfer/android/magenta_arbitrary-image-stylization-v1-256_int8_transfer_1.tflite | Unknown for the binary | Unknown | Unknown | Unknown | No | Exact size observed by HTTP HEAD: 284,398 bytes. Do not commit until binary license and redistribution terms are confirmed. |
| TFLite style prediction fp16 model | https://storage.googleapis.com/download.tensorflow.org/models/tflite/task_library/style_transfer/android/magenta_arbitrary-image-stylization-v1-256_fp16_prediction_1.tflite | Unknown for the binary | Unknown | Unknown | Unknown | No | Exact size observed by HTTP HEAD: 4,708,350 bytes. Not part of the first spike target. |
| TFLite style transfer fp16 model | https://storage.googleapis.com/download.tensorflow.org/models/tflite/task_library/style_transfer/android/magenta_arbitrary-image-stylization-v1-256_fp16_transfer_1.tflite | Unknown for the binary | Unknown | Unknown | Unknown | No | Exact size observed by HTTP HEAD: 422,086 bytes. Not part of the first spike target. |
| Kaggle model metadata schema | https://github.com/Kaggle/kaggle-api/blob/main/docs/models_metadata.md | Documentation repository license applies to the docs; target model license not retrieved from this schema | Not applicable | Not applicable | Not applicable | No | The schema supports `licenseName`, but the public page available during this gate did not expose a clear license value for the target model binaries. |

## Phase 1J-A Decision

The license gate did **not** pass. The official TensorFlow Lite style transfer model pair remains the best technical candidate, but Mixelith must not commit the model files or add a runtime dependency until the exact binary license and redistribution terms are confirmed from an authoritative source.
