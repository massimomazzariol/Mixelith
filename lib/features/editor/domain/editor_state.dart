import '../../../filters/domain/filter_preset.dart';
import '../../../filters/presets/default_filter_presets.dart';
import 'applied_filter.dart';
import 'working_image.dart';

class EditorState {
  const EditorState({
    required this.presets,
    required this.selectedFilterId,
    required this.filterStack,
    required this.isApplyingFilter,
    this.workingImage,
    this.filteredPreviewPath,
    this.errorMessage,
    this.activeMode = EditorOutputMode.procedural,
    this.isApplyingOnnx = false,
    this.selectedOnnxModelId,
    this.selectedOnnxModelLabel,
    this.onnxResult,
    this.onnxErrorMessage,
  });

  const EditorState.initial()
    : presets = const [],
      selectedFilterId = originalFilterId,
      filterStack = const [],
      isApplyingFilter = false,
      workingImage = null,
      filteredPreviewPath = null,
      errorMessage = null,
      activeMode = EditorOutputMode.procedural,
      isApplyingOnnx = false,
      selectedOnnxModelId = null,
      selectedOnnxModelLabel = null,
      onnxResult = null,
      onnxErrorMessage = null;

  final WorkingImage? workingImage;
  final List<FilterPreset> presets;
  final String selectedFilterId;
  final List<AppliedFilter> filterStack;
  final bool isApplyingFilter;
  final String? filteredPreviewPath;
  final String? errorMessage;
  final EditorOutputMode activeMode;
  final bool isApplyingOnnx;
  final String? selectedOnnxModelId;
  final String? selectedOnnxModelLabel;
  final OnnxEditorResult? onnxResult;
  final String? onnxErrorMessage;

  bool get isReady => workingImage != null;

  bool get hasFilters => filterStack.isNotEmpty;

  bool get hasActiveOnnxResult =>
      activeMode == EditorOutputMode.onnx && onnxResult != null;

  bool get isBusy => isApplyingFilter || isApplyingOnnx;

  bool get canExport => !isBusy && (hasFilters || hasActiveOnnxResult);

  String? get visiblePreviewPath {
    if (hasActiveOnnxResult) {
      return onnxResult!.outputPath;
    }
    if (filteredPreviewPath != null) {
      return filteredPreviewPath;
    }
    return workingImage?.previewPath;
  }

  EditorState copyWith({
    WorkingImage? workingImage,
    List<FilterPreset>? presets,
    String? selectedFilterId,
    List<AppliedFilter>? filterStack,
    bool? isApplyingFilter,
    Object? filteredPreviewPath = _sentinel,
    Object? errorMessage = _sentinel,
    EditorOutputMode? activeMode,
    bool? isApplyingOnnx,
    Object? selectedOnnxModelId = _sentinel,
    Object? selectedOnnxModelLabel = _sentinel,
    Object? onnxResult = _sentinel,
    Object? onnxErrorMessage = _sentinel,
  }) {
    return EditorState(
      workingImage: workingImage ?? this.workingImage,
      presets: presets ?? this.presets,
      selectedFilterId: selectedFilterId ?? this.selectedFilterId,
      filterStack: filterStack ?? this.filterStack,
      isApplyingFilter: isApplyingFilter ?? this.isApplyingFilter,
      filteredPreviewPath: identical(filteredPreviewPath, _sentinel)
          ? this.filteredPreviewPath
          : filteredPreviewPath as String?,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      activeMode: activeMode ?? this.activeMode,
      isApplyingOnnx: isApplyingOnnx ?? this.isApplyingOnnx,
      selectedOnnxModelId: identical(selectedOnnxModelId, _sentinel)
          ? this.selectedOnnxModelId
          : selectedOnnxModelId as String?,
      selectedOnnxModelLabel: identical(selectedOnnxModelLabel, _sentinel)
          ? this.selectedOnnxModelLabel
          : selectedOnnxModelLabel as String?,
      onnxResult: identical(onnxResult, _sentinel)
          ? this.onnxResult
          : onnxResult as OnnxEditorResult?,
      onnxErrorMessage: identical(onnxErrorMessage, _sentinel)
          ? this.onnxErrorMessage
          : onnxErrorMessage as String?,
    );
  }
}

enum EditorOutputMode { procedural, onnx }

class OnnxEditorResult {
  const OnnxEditorResult({
    required this.modelId,
    required this.modelLabel,
    required this.outputPath,
    required this.inputWidth,
    required this.inputHeight,
    required this.outputWidth,
    required this.outputHeight,
    required this.usedPreviewSource,
    required this.sourceLabel,
    required this.originalWidth,
    required this.originalHeight,
    this.processingTime,
  });

  final String modelId;
  final String modelLabel;
  final String outputPath;
  final int inputWidth;
  final int inputHeight;
  final int outputWidth;
  final int outputHeight;
  final bool usedPreviewSource;
  final String sourceLabel;
  final int originalWidth;
  final int originalHeight;
  final Duration? processingTime;

  bool get dimensionsMatchInput =>
      inputWidth == outputWidth && inputHeight == outputHeight;

  String get inputSizeLabel => '$inputWidth x $inputHeight';

  String get outputSizeLabel => '$outputWidth x $outputHeight';

  String get originalSizeLabel => '$originalWidth x $originalHeight';

  String get processingTimeLabel {
    final time = processingTime;
    if (time == null) {
      return 'Unknown';
    }
    return '${time.inMilliseconds} ms';
  }
}

const Object _sentinel = Object();
