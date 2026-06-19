enum LocalOnnxModelStatus { usable, rejected, failedValidation }

class LocalOnnxModel {
  const LocalOnnxModel({
    required this.id,
    required this.displayLabel,
    required this.storedPath,
    required this.fileSizeBytes,
    required this.inputShape,
    required this.outputShape,
    required this.status,
    required this.importedAt,
    this.rejectionReason,
  });

  final String id;
  final String displayLabel;
  final String storedPath;
  final int fileSizeBytes;
  final List<int> inputShape;
  final List<int> outputShape;
  final LocalOnnxModelStatus status;
  final DateTime importedAt;
  final String? rejectionReason;

  bool get isUsable => status == LocalOnnxModelStatus.usable;

  String get statusLabel {
    return switch (status) {
      LocalOnnxModelStatus.usable => 'Usable',
      LocalOnnxModelStatus.rejected => 'Rejected',
      LocalOnnxModelStatus.failedValidation => 'Failed',
    };
  }

  String get inputShapeLabel => shapeLabel(inputShape);

  String get outputShapeLabel => shapeLabel(outputShape);

  String get fileSizeLabel {
    if (fileSizeBytes <= 0) {
      return 'Unknown size';
    }
    final megabytes = fileSizeBytes / (1024 * 1024);
    return '${megabytes.toStringAsFixed(1)} MB';
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'displayLabel': displayLabel,
      'storedPath': storedPath,
      'fileSizeBytes': fileSizeBytes,
      'inputShape': inputShape,
      'outputShape': outputShape,
      'status': status.name,
      'importedAt': importedAt.toIso8601String(),
      'rejectionReason': rejectionReason,
    };
  }

  factory LocalOnnxModel.fromJson(Map<String, Object?> json) {
    return LocalOnnxModel(
      id: json['id'] as String? ?? 'local-onnx-model',
      displayLabel: json['displayLabel'] as String? ?? 'Local ONNX model',
      storedPath: json['storedPath'] as String? ?? '',
      fileSizeBytes: _asInt(json['fileSizeBytes']) ?? 0,
      inputShape: _shape(json['inputShape']),
      outputShape: _shape(json['outputShape']),
      status: _status(json['status']),
      importedAt: _date(json['importedAt']),
      rejectionReason: json['rejectionReason'] as String?,
    );
  }

  LocalOnnxModel copyWith({
    String? id,
    String? displayLabel,
    String? storedPath,
    int? fileSizeBytes,
    List<int>? inputShape,
    List<int>? outputShape,
    LocalOnnxModelStatus? status,
    DateTime? importedAt,
    String? rejectionReason,
  }) {
    return LocalOnnxModel(
      id: id ?? this.id,
      displayLabel: displayLabel ?? this.displayLabel,
      storedPath: storedPath ?? this.storedPath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      inputShape: inputShape ?? this.inputShape,
      outputShape: outputShape ?? this.outputShape,
      status: status ?? this.status,
      importedAt: importedAt ?? this.importedAt,
      rejectionReason: rejectionReason,
    );
  }

  static String shapeLabel(List<int> shape) {
    if (shape.isEmpty) {
      return 'Unknown';
    }
    return shape
        .map((dimension) => dimension <= 0 ? 'dynamic' : '$dimension')
        .join(' x ');
  }

  static String? fixedInputRejection(List<int> inputShape) {
    if (inputShape.length < 4) {
      return 'ONNX input tensor shape must include batch, channel, height, and width.';
    }
    final height = inputShape[2];
    final width = inputShape[3];
    if (height <= 0 || width <= 0) {
      return null;
    }
    return 'ONNX model input is fixed to ${width}x$height; Mixelith requires dynamic full-frame input.';
  }

  static int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    return null;
  }

  static List<int> _shape(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value.whereType<num>().map((item) => item.round()).toList();
  }

  static LocalOnnxModelStatus _status(Object? value) {
    final name = value as String?;
    return LocalOnnxModelStatus.values.firstWhere(
      (status) => status.name == name,
      orElse: () => LocalOnnxModelStatus.failedValidation,
    );
  }

  static DateTime _date(Object? value) {
    final text = value as String?;
    if (text == null) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.tryParse(text) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
}
