import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mixelith/storage/data/path_provider_cache_service.dart';

void main() {
  late Directory baseDirectory;
  late PathProviderCacheService service;

  setUp(() async {
    baseDirectory = await Directory.systemTemp.createTemp(
      'mixelith_cache_test_',
    );
    service = PathProviderCacheService(
      tempDirectoryProvider: () async => baseDirectory,
      cacheDirectoryName: 'cache',
    );
  });

  tearDown(() async {
    if (await baseDirectory.exists()) {
      await baseDirectory.delete(recursive: true);
    }
  });

  test('writeTempFile writes bytes under dedicated cache directory', () async {
    final path = await service.writeTempFile([1, 2, 3], '.jpg');
    final file = File(path);

    expect(
      path,
      contains('${Platform.pathSeparator}cache${Platform.pathSeparator}'),
    );
    expect(path, endsWith('.jpg'));
    expect(await file.readAsBytes(), [1, 2, 3]);
  });

  test(
    'copyTempFileFromPath copies source under dedicated cache directory',
    () async {
      final source = File(
        '${baseDirectory.path}${Platform.pathSeparator}source.png',
      );
      await source.writeAsBytes([4, 5, 6]);

      final path = await service.copyTempFileFromPath(source.path, 'png');
      final copiedFile = File(path);

      expect(
        path,
        contains('${Platform.pathSeparator}cache${Platform.pathSeparator}'),
      );
      expect(path, endsWith('.png'));
      expect(await copiedFile.readAsBytes(), [4, 5, 6]);
      expect(await source.exists(), isTrue);
    },
  );

  test('copyTempFileFromPath fails for missing source', () async {
    expect(
      () => service.copyTempFileFromPath('missing.png', 'png'),
      throwsA(isA<CacheServiceException>()),
    );
  });

  test('clearExpiredCache removes old files and keeps fresh files', () async {
    final oldPath = await service.writeTempFile([1], 'tmp');
    final freshPath = await service.writeTempFile([2], 'tmp');

    await File(
      oldPath,
    ).setLastModified(DateTime.now().subtract(const Duration(hours: 2)));

    await service.clearExpiredCache();

    expect(await File(oldPath).exists(), isFalse);
    expect(await File(freshPath).exists(), isTrue);
  });

  test('clearAll removes the dedicated cache directory', () async {
    final path = await service.writeTempFile([1], 'tmp');
    final cacheDirectory = File(path).parent;

    await service.clearAll();

    expect(await cacheDirectory.exists(), isFalse);
  });
}
