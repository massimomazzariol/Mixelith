import 'package:mixelith/features/export/domain/export_repository.dart';
import 'package:mixelith/features/export/domain/export_save_result.dart';
import 'package:mixelith/features/export/domain/export_settings.dart';

class FakeExportRepository implements ExportRepository {
  FakeExportRepository({
    this.result = const ExportSaveResult.success(message: 'Saved to gallery.'),
  });

  ExportSaveResult result;
  final List<FakeExportSaveRequest> requests = [];

  @override
  Future<ExportSaveResult> saveImage({
    required String filePath,
    required String fileName,
    required ExportFormat format,
  }) async {
    requests.add(
      FakeExportSaveRequest(
        filePath: filePath,
        fileName: fileName,
        format: format,
      ),
    );
    return result;
  }
}

class FakeExportSaveRequest {
  const FakeExportSaveRequest({
    required this.filePath,
    required this.fileName,
    required this.format,
  });

  final String filePath;
  final String fileName;
  final ExportFormat format;
}
