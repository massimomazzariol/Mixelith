import 'dart:io';

import 'package:mixelith/storage/domain/cache_service.dart';

class FakeCacheService implements CacheService {
  FakeCacheService(this.baseDirectory);

  final Directory baseDirectory;
  int _counter = 0;

  @override
  Future<String> copyTempFileFromPath(
    String sourcePath,
    String extension,
  ) async {
    final target = File(_nextPath(extension));
    await File(sourcePath).copy(target.path);
    return target.path;
  }

  @override
  Future<String> writeTempFile(List<int> bytes, String extension) async {
    final target = File(_nextPath(extension));
    await target.writeAsBytes(bytes, flush: true);
    return target.path;
  }

  @override
  Future<void> clearAll() async {}

  @override
  Future<void> clearExpiredCache() async {}

  String _nextPath(String extension) {
    final normalizedExtension = extension.replaceFirst(RegExp(r'^\.+'), '');
    final filename = 'cache_${_counter++}.$normalizedExtension';
    return '${baseDirectory.path}${Platform.pathSeparator}$filename';
  }
}
