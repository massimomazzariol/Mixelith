class ExportSaveResult {
  const ExportSaveResult({required this.success, this.savedPath, this.message});

  const ExportSaveResult.success({String? savedPath, String? message})
    : this(success: true, savedPath: savedPath, message: message);

  const ExportSaveResult.failure({String? message})
    : this(success: false, message: message);

  final bool success;
  final String? savedPath;
  final String? message;
}
