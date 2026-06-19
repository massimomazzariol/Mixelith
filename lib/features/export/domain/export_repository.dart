import 'export_save_result.dart';
import 'export_settings.dart';

abstract class ExportRepository {
  Future<ExportSaveResult> saveImage({
    required String filePath,
    required String fileName,
    required ExportFormat format,
  });
}
