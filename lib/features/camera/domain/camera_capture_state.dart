import '../../editor/domain/working_image.dart';

enum CameraCaptureStatus { idle, importing, imported, error }

class CameraCaptureState {
  const CameraCaptureState({
    required this.status,
    this.workingImage,
    this.message,
  });

  const CameraCaptureState.idle()
    : status = CameraCaptureStatus.idle,
      workingImage = null,
      message = null;

  final CameraCaptureStatus status;
  final WorkingImage? workingImage;
  final String? message;

  bool get isImporting => status == CameraCaptureStatus.importing;
}
