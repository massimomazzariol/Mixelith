abstract class CacheService {
  Future<String> writeTempFile(List<int> bytes, String extension);

  Future<String> reserveTempFilePath(String extension);

  Future<String> copyTempFileFromPath(String sourcePath, String extension);

  Future<void> clearExpiredCache();

  Future<void> clearAll();
}
