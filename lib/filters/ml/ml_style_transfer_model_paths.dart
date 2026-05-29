class MlStyleTransferModelPaths {
  const MlStyleTransferModelPaths._();

  static const directory = 'assets/models/style_transfer';

  static const predictionAsset =
      '$directory/style_prediction_int8.tflite';
  static const transferAsset = '$directory/style_transfer_int8.tflite';

  static const predictionSourceUrl =
      'https://storage.googleapis.com/download.tensorflow.org/models/tflite/task_library/style_transfer/android/magenta_arbitrary-image-stylization-v1-256_int8_prediction_1.tflite';
  static const transferSourceUrl =
      'https://storage.googleapis.com/download.tensorflow.org/models/tflite/task_library/style_transfer/android/magenta_arbitrary-image-stylization-v1-256_int8_transfer_1.tflite';

  static const predictionExpectedBytes = 2828838;
  static const transferExpectedBytes = 284398;

  static const allModelAssets = [
    predictionAsset,
    transferAsset,
  ];
}
