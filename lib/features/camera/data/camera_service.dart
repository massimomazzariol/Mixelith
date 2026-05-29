import 'package:camera/camera.dart';

import '../domain/captured_image.dart';

class CameraService {
  const CameraService();

  Future<List<CameraDescription>> getAvailableCameras() => availableCameras();

  CameraController createController(CameraDescription description) {
    return CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
    );
  }

  Future<CapturedImage> captureStill(CameraController controller) async {
    final file = await controller.takePicture();
    return CapturedImage(
      path: file.path,
      extension: _extensionFromPath(file.path),
      capturedAt: DateTime.now(),
    );
  }

  String _extensionFromPath(String path) {
    final filename = path.split(RegExp(r'[\\/]')).last;
    final dotIndex = filename.lastIndexOf('.');
    if (dotIndex >= 0 && dotIndex < filename.length - 1) {
      final extension = filename.substring(dotIndex + 1).toLowerCase();
      if (extension.isNotEmpty) {
        return extension;
      }
    }
    return 'jpg';
  }
}
