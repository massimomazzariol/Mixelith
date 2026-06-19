import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../data/local_onnx_model_repository.dart';
import '../domain/local_onnx_model.dart';

final localOnnxModelRepositoryProvider = Provider<LocalOnnxModelRepository>(
  (ref) => MethodChannelLocalOnnxModelRepository(
    cacheService: ref.watch(cacheServiceProvider),
  ),
);

final localOnnxModelControllerProvider =
    NotifierProvider<LocalOnnxModelController, LocalOnnxModelState>(
      LocalOnnxModelController.new,
    );

class LocalOnnxModelController extends Notifier<LocalOnnxModelState> {
  @override
  LocalOnnxModelState build() => const LocalOnnxModelState();

  Future<void> load() async {
    state = state.copyWith(status: LocalOnnxModelLoadStatus.loading);
    try {
      final models = await ref
          .read(localOnnxModelRepositoryProvider)
          .loadModels();
      state = state.copyWith(
        status: LocalOnnxModelLoadStatus.loaded,
        models: models,
        errorMessage: null,
      );
    } catch (_) {
      state = state.copyWith(
        status: LocalOnnxModelLoadStatus.error,
        errorMessage: 'Unable to load local ONNX models.',
      );
    }
  }

  Future<void> importModel() async {
    if (state.isImporting) {
      return;
    }

    state = state.copyWith(isImporting: true, errorMessage: null);
    try {
      final model = await ref
          .read(localOnnxModelRepositoryProvider)
          .importModel();
      if (model == null) {
        state = state.copyWith(isImporting: false);
        return;
      }

      state = state.copyWith(
        status: LocalOnnxModelLoadStatus.loaded,
        models: [...state.models, model],
        isImporting: false,
        errorMessage: null,
      );
    } catch (_) {
      state = state.copyWith(
        status: LocalOnnxModelLoadStatus.error,
        isImporting: false,
        errorMessage: 'Unable to import this ONNX model.',
      );
    }
  }
}

enum LocalOnnxModelLoadStatus { idle, loading, loaded, error }

class LocalOnnxModelState {
  const LocalOnnxModelState({
    this.status = LocalOnnxModelLoadStatus.idle,
    this.models = const [],
    this.isImporting = false,
    this.errorMessage,
  });

  final LocalOnnxModelLoadStatus status;
  final List<LocalOnnxModel> models;
  final bool isImporting;
  final String? errorMessage;

  List<LocalOnnxModel> get usableModels {
    return models.where((model) => model.isUsable).toList(growable: false);
  }

  bool get hasUsableModels => usableModels.isNotEmpty;

  LocalOnnxModelState copyWith({
    LocalOnnxModelLoadStatus? status,
    List<LocalOnnxModel>? models,
    bool? isImporting,
    String? errorMessage,
  }) {
    return LocalOnnxModelState(
      status: status ?? this.status,
      models: models ?? this.models,
      isImporting: isImporting ?? this.isImporting,
      errorMessage: errorMessage,
    );
  }
}
