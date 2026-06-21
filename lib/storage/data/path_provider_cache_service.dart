import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/cache_service.dart';

typedef TempDirectoryProvider = Future<Directory> Function();

class PathProviderCacheService implements CacheService {
  PathProviderCacheService({
    TempDirectoryProvider? tempDirectoryProvider,
    this.cacheDirectoryName = 'mixelith_cache',
    this.expirationAge = const Duration(hours: 1),
  }) : _tempDirectoryProvider = tempDirectoryProvider ?? getTemporaryDirectory;

  final TempDirectoryProvider _tempDirectoryProvider;
  final String cacheDirectoryName;
  final Duration expirationAge;
  int _sequence = 0;

  @override
  Future<String> writeTempFile(List<int> bytes, String extension) async {
    try {
      final file = File(await reserveTempFilePath(extension));

      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } on FileSystemException catch (error) {
      throw CacheServiceException('Unable to write cache file.', error);
    }
  }

  @override
  Future<String> reserveTempFilePath(String extension) async {
    try {
      final directory = await _ensureCacheDirectory();
      final normalizedExtension = _normalizeExtension(extension);
      final filename = _createFilename(normalizedExtension);
      return _joinPath(directory.path, filename);
    } on FileSystemException catch (error) {
      throw CacheServiceException('Unable to create cache file path.', error);
    }
  }

  @override
  Future<String> copyTempFileFromPath(
    String sourcePath,
    String extension,
  ) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        throw FileSystemException(
          'Source cache file does not exist.',
          sourcePath,
        );
      }

      final directory = await _ensureCacheDirectory();
      final normalizedExtension = _normalizeExtension(extension);
      final filename = _createFilename(normalizedExtension);
      final targetFile = File(_joinPath(directory.path, filename));

      await sourceFile.copy(targetFile.path);
      return targetFile.path;
    } on FileSystemException catch (error) {
      throw CacheServiceException('Unable to copy cache file.', error);
    }
  }

  @override
  Future<void> clearExpiredCache() async {
    try {
      final directory = await _ensureCacheDirectory();
      final now = DateTime.now();

      await for (final entity in directory.list(followLinks: false)) {
        final stat = await entity.stat();
        if (now.difference(stat.modified) > expirationAge) {
          await _deleteEntity(entity);
        }
      }
    } on FileSystemException catch (error) {
      throw CacheServiceException(
        'Unable to clear expired cache files.',
        error,
      );
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      final directory = await _cacheDirectory();
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    } on FileSystemException catch (error) {
      throw CacheServiceException('Unable to clear cache directory.', error);
    }
  }

  Future<Directory> _ensureCacheDirectory() async {
    final directory = await _cacheDirectory();
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<Directory> _cacheDirectory() async {
    final tempDirectory = await _tempDirectoryProvider();
    return Directory(_joinPath(tempDirectory.path, cacheDirectoryName));
  }

  Future<void> _deleteEntity(FileSystemEntity entity) async {
    if (await entity.exists()) {
      await entity.delete(recursive: true);
    }
  }

  String _normalizeExtension(String extension) {
    final normalized = extension.trim().toLowerCase().replaceFirst(
      RegExp(r'^\.+'),
      '',
    );

    if (normalized.isEmpty ||
        normalized.contains('/') ||
        normalized.contains(r'\')) {
      throw ArgumentError.value(extension, 'extension', 'Invalid extension');
    }

    return normalized;
  }

  String _createFilename(String normalizedExtension) {
    final sequence = _sequence++;
    return '${DateTime.now().microsecondsSinceEpoch}_$sequence.$normalizedExtension';
  }

  String _joinPath(String parent, String child) {
    final separator = Platform.pathSeparator;
    return parent.endsWith(separator)
        ? '$parent$child'
        : '$parent$separator$child';
  }
}

class CacheServiceException implements Exception {
  const CacheServiceException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() {
    if (cause == null) {
      return 'CacheServiceException: $message';
    }
    return 'CacheServiceException: $message ($cause)';
  }
}
