import 'dart:io';

import 'package:gal/gal.dart';

import '../domain/export_repository.dart';
import '../domain/export_save_result.dart';
import '../domain/export_settings.dart';

class GalExportRepository implements ExportRepository {
  const GalExportRepository({this.albumName = 'Mixelith'});

  final String albumName;

  @override
  Future<ExportSaveResult> saveImage({
    required String filePath,
    required String fileName,
    required ExportFormat format,
  }) async {
    try {
      final galleryFilePath = await _copyWithExportName(
        filePath: filePath,
        fileName: fileName,
        format: format,
      );
      await Gal.putImage(galleryFilePath, album: albumName);
      return ExportSaveResult.success(
        savedPath: galleryFilePath,
        message: 'Saved to gallery.',
      );
    } on GalException catch (error) {
      return ExportSaveResult.failure(message: _messageForGalError(error));
    } on FileSystemException {
      return const ExportSaveResult.failure(
        message: 'Unable to prepare the gallery file.',
      );
    } catch (_) {
      return const ExportSaveResult.failure(
        message: 'Unable to save image to gallery.',
      );
    }
  }

  Future<String> _copyWithExportName({
    required String filePath,
    required String fileName,
    required ExportFormat format,
  }) async {
    final source = File(filePath);
    final sanitizedName = _sanitizeFileName(fileName);
    final target = File(
      '${source.parent.path}${Platform.pathSeparator}$sanitizedName.${format.fileExtension}',
    );

    if (source.path == target.path) {
      return source.path;
    }

    await source.copy(target.path);
    return target.path;
  }

  String _sanitizeFileName(String fileName) {
    final sanitized = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    if (sanitized.isEmpty) {
      return 'mixelith_export';
    }
    return sanitized;
  }

  String _messageForGalError(GalException error) {
    return switch (error.type) {
      GalExceptionType.accessDenied =>
        'Gallery access was denied. Please allow access and try again.',
      GalExceptionType.notEnoughSpace =>
        'There is not enough storage space to save this export.',
      GalExceptionType.notSupportedFormat =>
        'This export format is not supported by the gallery.',
      GalExceptionType.unexpected => 'Unable to save image to gallery.',
    };
  }
}
