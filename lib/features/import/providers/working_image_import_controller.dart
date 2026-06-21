import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../data/android_image_normalizer.dart';
import '../../../media/domain/media_asset.dart';
import '../domain/working_image_import_service.dart';
import '../domain/working_image_import_state.dart';

final imageNormalizerProvider = Provider<AndroidImageNormalizer>(
  (ref) => const AndroidImageNormalizer(),
);

final workingImageImportServiceProvider = Provider<WorkingImageImportService>((
  ref,
) {
  return WorkingImageImportService(
    mediaRepository: ref.watch(mediaRepositoryProvider),
    cacheService: ref.watch(cacheServiceProvider),
    imageNormalizer: ref.watch(imageNormalizerProvider),
  );
});

final workingImageImportControllerProvider =
    NotifierProvider<WorkingImageImportController, WorkingImageImportState>(
      WorkingImageImportController.new,
    );

class WorkingImageImportController extends Notifier<WorkingImageImportState> {
  @override
  WorkingImageImportState build() => const WorkingImageImportState.idle();

  WorkingImageImportService get _service =>
      ref.read(workingImageImportServiceProvider);

  Future<WorkingImageImportState> importAsset(MediaAsset asset) async {
    state = const WorkingImageImportState(
      status: WorkingImageImportStatus.importing,
    );

    try {
      final workingImage = await _service.importAsset(asset);
      state = WorkingImageImportState(
        status: WorkingImageImportStatus.imported,
        workingImage: workingImage,
      );
    } on WorkingImageImportException catch (error) {
      state = WorkingImageImportState(
        status: error.failure == WorkingImageImportFailure.unavailableCloudOnly
            ? WorkingImageImportStatus.unavailableCloudOnly
            : WorkingImageImportStatus.error,
        message: error.message,
      );
    } catch (_) {
      state = const WorkingImageImportState(
        status: WorkingImageImportStatus.error,
        message: 'Unable to prepare the preview.',
      );
    }

    return state;
  }

  void reset() {
    state = const WorkingImageImportState.idle();
  }
}
