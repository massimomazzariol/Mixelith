import '../../editor/domain/working_image.dart';

enum WorkingImageImportStatus {
  idle,
  importing,
  imported,
  unavailableCloudOnly,
  error,
}

class WorkingImageImportState {
  const WorkingImageImportState({
    required this.status,
    this.workingImage,
    this.message,
  });

  const WorkingImageImportState.idle()
    : status = WorkingImageImportStatus.idle,
      workingImage = null,
      message = null;

  final WorkingImageImportStatus status;
  final WorkingImage? workingImage;
  final String? message;

  bool get isImporting => status == WorkingImageImportStatus.importing;
}
