import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../import/domain/working_image_import_service.dart';
import '../../import/providers/working_image_import_controller.dart';
import '../data/camera_service.dart';
import '../domain/camera_capture_state.dart';
import '../domain/captured_image.dart';

final cameraServiceProvider = Provider<CameraService>(
  (ref) => const CameraService(),
);

final cameraCaptureControllerProvider =
    NotifierProvider<CameraCaptureController, CameraCaptureState>(
      CameraCaptureController.new,
    );

class CameraCaptureController extends Notifier<CameraCaptureState> {
  @override
  CameraCaptureState build() => const CameraCaptureState.idle();

  Future<CameraCaptureState> importCapturedImage(CapturedImage image) async {
    state = const CameraCaptureState(status: CameraCaptureStatus.importing);

    try {
      final workingImage = await ref
          .read(workingImageImportServiceProvider)
          .importFromFilePath(
            sourcePath: image.path,
            sourceAssetId: 'camera_${image.capturedAt.microsecondsSinceEpoch}',
            extension: image.extension,
          );

      state = CameraCaptureState(
        status: CameraCaptureStatus.imported,
        workingImage: workingImage,
      );
    } on WorkingImageImportException catch (error) {
      state = CameraCaptureState(
        status: CameraCaptureStatus.error,
        message: error.message,
      );
    } catch (_) {
      state = const CameraCaptureState(
        status: CameraCaptureStatus.error,
        message: 'Unable to prepare the capture.',
      );
    }

    return state;
  }

  void reset() {
    state = const CameraCaptureState.idle();
  }
}
