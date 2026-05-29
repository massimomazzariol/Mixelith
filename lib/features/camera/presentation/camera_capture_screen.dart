import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../shared/widgets/mixelith_gradient_button.dart';
import '../../../shared/widgets/mixelith_loading_overlay.dart';
import '../../../shared/widgets/mixelith_screen_scaffold.dart';
import '../../editor/presentation/editor_preview_screen.dart';
import '../domain/camera_capture_state.dart';
import '../providers/camera_capture_controller.dart';

class CameraCaptureScreen extends ConsumerStatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  ConsumerState<CameraCaptureScreen> createState() =>
      _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends ConsumerState<CameraCaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  CameraDescription? _cameraDescription;
  bool _isInitializing = true;
  bool _isCapturing = false;
  _CameraError? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initializeCamera();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final description = _cameraDescription;
      if (description != null) {
        _initializeCamera(description);
      }
      return;
    }

    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _cameraController = null;
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final importState = ref.watch(cameraCaptureControllerProvider);
    final isBusy = _isCapturing || importState.isImporting;

    return MixelithScreenScaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: isBusy ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Take photo'),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: _buildBody(context)),
            if (isBusy)
              MixelithLoadingOverlay(
                message: importState.isImporting
                    ? 'Preparing capture'
                    : 'Capturing photo',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isInitializing) {
      return const _CameraLoadingState();
    }

    final error = _error;
    if (error != null) {
      return _CameraErrorState(
        title: error.title,
        message: error.message,
        actionLabel: error.canRetry ? 'Try again' : null,
        onAction: error.canRetry ? () => _initializeCamera() : null,
      );
    }

    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return _CameraErrorState(
        title: 'Camera unavailable',
        message: 'Unable to start the camera on this device.',
        actionLabel: 'Try again',
        onAction: () => _initializeCamera(),
      );
    }

    return _CameraPreviewBody(
      controller: controller,
      isCaptureEnabled: !_isCapturing,
      onCapture: _handleCapture,
    );
  }

  Future<void> _initializeCamera([CameraDescription? preferredCamera]) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isInitializing = false;
        _error = const _CameraError(
          title: 'Android Camera',
          message: 'Camera capture is available on Android builds.',
          canRetry: false,
        );
      });
      return;
    }

    setState(() {
      _isInitializing = true;
      _error = null;
    });

    try {
      final service = ref.read(cameraServiceProvider);
      final cameras = await service.getAvailableCameras();
      if (cameras.isEmpty) {
        throw const _CameraSetupException(
          'No camera available',
          'This device does not expose a camera usable by Mixelith.',
          false,
        );
      }

      final selectedCamera =
          preferredCamera ?? _selectBackCamera(cameras) ?? cameras.first;
      final nextController = service.createController(selectedCamera);
      await nextController.initialize();

      if (!mounted) {
        await nextController.dispose();
        return;
      }

      final previousController = _cameraController;
      setState(() {
        _cameraDescription = selectedCamera;
        _cameraController = nextController;
        _isInitializing = false;
        _error = null;
      });
      await previousController?.dispose();
    } on CameraException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isInitializing = false;
        _error = _mapCameraException(error);
      });
    } on _CameraSetupException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isInitializing = false;
        _error = _CameraError(
          title: error.title,
          message: error.message,
          canRetry: error.canRetry,
        );
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isInitializing = false;
        _error = const _CameraError(
          title: 'Unable to start camera',
          message:
              'The camera did not start correctly. Try again shortly.',
          canRetry: true,
        );
      });
    }
  }

  CameraDescription? _selectBackCamera(List<CameraDescription> cameras) {
    for (final camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.back) {
        return camera;
      }
    }
    return null;
  }

  Future<void> _handleCapture() async {
    final controller = _cameraController;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture ||
        _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      final captured = await ref
          .read(cameraServiceProvider)
          .captureStill(controller);
      final importResult = await ref
          .read(cameraCaptureControllerProvider.notifier)
          .importCapturedImage(captured);

      if (!mounted) {
        return;
      }

      if (importResult.status == CameraCaptureStatus.imported &&
          importResult.workingImage != null) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) =>
                EditorPreviewScreen(workingImage: importResult.workingImage!),
          ),
        );
        ref.read(cameraCaptureControllerProvider.notifier).reset();
        return;
      }

      setState(() => _isCapturing = false);
      _showSnackBar(
        importResult.message ??
            'Unable to prepare the capture. Try again.',
      );
    } on CameraException catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isCapturing = false);
      _showSnackBar('Capture failed. Try again.');
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isCapturing = false);
      _showSnackBar('Capture failed. Try again.');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  _CameraError _mapCameraException(CameraException error) {
    final code = error.code.toLowerCase();
    if (code.contains('accessdenied') ||
        code.contains('permission') ||
        code.contains('restricted')) {
      return const _CameraError(
        title: 'Camera not authorized',
        message:
            'Allow camera access to take a photo in Mixelith. No audio is recorded.',
        canRetry: true,
      );
    }

    return const _CameraError(
      title: 'Unable to start camera',
      message:
          'The camera did not start correctly. Try again shortly.',
      canRetry: true,
    );
  }
}

class _CameraPreviewBody extends StatelessWidget {
  const _CameraPreviewBody({
    required this.controller,
    required this.isCaptureEnabled,
    required this.onCapture,
  });

  final CameraController controller;
  final bool isCaptureEnabled;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      child: Column(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: MixelithColors.red.withValues(alpha: 0.16),
                    blurRadius: 34,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(27),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: Colors.black,
                      child: Center(child: CameraPreview(controller)),
                    ),
                    const _CameraPrivacyPill(),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Semantics(
            button: true,
            label: 'Take photo now',
            child: GestureDetector(
              onTap: isCaptureEnabled ? onCapture : null,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 160),
                opacity: isCaptureEnabled ? 1 : 0.5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: MixelithColors.accentGradient,
                    boxShadow: [
                      BoxShadow(
                        color: MixelithColors.orange.withValues(alpha: 0.28),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const SizedBox.square(
                    dimension: 76,
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: Color(0xFF080509),
                      size: 34,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraPrivacyPill extends StatelessWidget {
  const _CameraPrivacyPill();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 14,
      right: 14,
      bottom: 14,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.52),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(
            'Photo only. No audio. No automatic saving.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _CameraLoadingState extends StatelessWidget {
  const _CameraLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 220,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox.square(
              dimension: 30,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(height: 16),
            Text('Starting camera', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _CameraErrorState extends StatelessWidget {
  const _CameraErrorState({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: MixelithColors.surface,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.photo_camera_outlined,
                    size: 34,
                    color: MixelithColors.yellow,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: MixelithGradientButton(
                        label: actionLabel!,
                        icon: Icons.refresh_rounded,
                        onPressed: onAction,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraError {
  const _CameraError({
    required this.title,
    required this.message,
    required this.canRetry,
  });

  final String title;
  final String message;
  final bool canRetry;
}

class _CameraSetupException implements Exception {
  const _CameraSetupException(this.title, this.message, this.canRetry);

  final String title;
  final String message;
  final bool canRetry;
}
