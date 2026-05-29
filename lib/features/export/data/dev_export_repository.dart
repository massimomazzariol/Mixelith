import '../domain/export_repository.dart';
import '../domain/export_save_result.dart';
import '../domain/export_settings.dart';
import '../../../storage/domain/cache_service.dart';

class DevExportRepository implements ExportRepository {
  const DevExportRepository({required CacheService cacheService})
    : _cacheService = cacheService;

  final CacheService _cacheService;

  @override
  Future<ExportSaveResult> saveImage({
    required String filePath,
    required String fileName,
    required ExportFormat format,
  }) async {
    try {
      final savedPath = await _cacheService.copyTempFileFromPath(
        filePath,
        format.fileExtension,
      );
      return ExportSaveResult.success(
        savedPath: savedPath,
        message: 'Export saved in development preview.',
      );
    } catch (_) {
      return const ExportSaveResult.failure(
        message: 'Unable to save export in development preview.',
      );
    }
  }
}
