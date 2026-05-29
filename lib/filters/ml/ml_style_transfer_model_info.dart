class MlTensorInfo {
  const MlTensorInfo({
    required this.name,
    required this.type,
    required this.shape,
    required this.byteSize,
  });

  final String name;
  final String type;
  final List<int> shape;
  final int byteSize;

  @override
  String toString() {
    return '$name $type shape=$shape bytes=$byteSize';
  }
}

class MlStyleTransferModelInfo {
  const MlStyleTransferModelInfo({
    required this.predictionInputs,
    required this.predictionOutputs,
    required this.transferInputs,
    required this.transferOutputs,
  });

  final List<MlTensorInfo> predictionInputs;
  final List<MlTensorInfo> predictionOutputs;
  final List<MlTensorInfo> transferInputs;
  final List<MlTensorInfo> transferOutputs;

  String get summary {
    return [
      'prediction inputs: ${predictionInputs.join(', ')}',
      'prediction outputs: ${predictionOutputs.join(', ')}',
      'transfer inputs: ${transferInputs.join(', ')}',
      'transfer outputs: ${transferOutputs.join(', ')}',
    ].join('; ');
  }
}
