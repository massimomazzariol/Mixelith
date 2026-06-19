class OnnxStyleTransferModel {
  const OnnxStyleTransferModel({
    required this.id,
    required this.displayName,
    required this.assetPath,
    required this.sourceUrl,
    required this.license,
    required this.sizeBytes,
  });

  final String id;
  final String displayName;
  final String assetPath;
  final String sourceUrl;
  final String license;
  final int sizeBytes;
}

const localStyleModel1OnnxModel = OnnxStyleTransferModel(
  id: 'local_style_model_1',
  displayName: 'Local Style Model 1',
  assetPath: 'assets/models/local_style_model_1.onnx',
  sourceUrl: 'user-provided local file',
  license: 'user-provided; not redistributed by Mixelith',
  sizeBytes: 0,
);

const localStyleModel2OnnxModel = OnnxStyleTransferModel(
  id: 'local_style_model_2',
  displayName: 'Local Style Model 2',
  assetPath: 'assets/models/local_style_model_2.onnx',
  sourceUrl: 'user-provided local file',
  license: 'user-provided; not redistributed by Mixelith',
  sizeBytes: 0,
);

const localStyleModel3OnnxModel = OnnxStyleTransferModel(
  id: 'local_style_model_3',
  displayName: 'Local Style Model 3',
  assetPath: 'assets/models/local_style_model_3.onnx',
  sourceUrl: 'user-provided local file',
  license: 'user-provided; not redistributed by Mixelith',
  sizeBytes: 0,
);

const localStyleModel4OnnxModel = OnnxStyleTransferModel(
  id: 'local_style_model_4',
  displayName: 'Local Style Model 4',
  assetPath: 'assets/models/local_style_model_4.onnx',
  sourceUrl: 'user-provided local file',
  license: 'user-provided; not redistributed by Mixelith',
  sizeBytes: 0,
);

const onnxStyleTransferCandidates = <OnnxStyleTransferModel>[
  localStyleModel1OnnxModel,
  localStyleModel2OnnxModel,
  localStyleModel3OnnxModel,
  localStyleModel4OnnxModel,
];
