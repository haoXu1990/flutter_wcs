import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class FlareKameraController with WidgetsBindingObserver {
  CameraController? controller;

  List<CameraDescription> cameras = [];
  CameraDescription? activeCamera;

  XFile? _currentXFile;

  int _pointers = 0;
  double _currentScale = 1.0;
  double _baseScale = 1.0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;

  FlareKameraController();

  // Mark: - Private Method

  CameraDescription? inactiveCamera() {
    final description = controller?.description;
    if (description == null || cameras.isEmpty) return null;

    if (description.lensDirection == CameraLensDirection.front) {
      return getAvailableCameras(CameraLensDirection.back);
    } else {
      return getAvailableCameras(CameraLensDirection.front);
    }
  }

  CameraDescription? getAvailableCameras(CameraLensDirection direction) {
    for (var camera in cameras) {
      if (camera.lensDirection == direction) {
        return camera;
      }
    }
  }

  // Mark: - KameraPreview

  Widget _cameraPreviewWidget() {
    final CameraController? cameraController = controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return const Text(
        'Tap a camera',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return Listener(
        onPointerDown: (_) => _pointers++,
        onPointerUp: (_) => _pointers--,
        child: CameraPreview(
          controller!,
          child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: _handleScaleStart,
              onScaleUpdate: _handleScaleUpdate,
              onTapDown: (details) => onViewFinderTap(details, constraints),
            );
          }),
        ),
      );
    }
  }

  /// ScaleStart
  ///
  /// starting scale with [details]
  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
  }

  /// ScaleUpdate
  ///
  /// update scale with [details]
  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    if (controller == null || _pointers != 2) {
      return;
    }
    _currentScale = (_baseScale * details.scale).clamp(_minAvailableZoom, _maxAvailableZoom);

    await controller!.setZoomLevel(_currentScale);
  }

  // Mark: - Kamera

  /// Picture
  ///
  /// take a picture with
  Future<XFile?> takePicture() async {
    final CameraController? cameraController = controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return null;
    }

    if (cameraController.value.isTakingPicture) {
      return null;
    }

    try {
      XFile file = await cameraController.takePicture();
      return file;
    } on CameraException catch (e) {
      logError(e.code, e.description);
      return null;
    }
  }

  /// Set interset point and exposure
  ///
  /// set interset point from [details] and [constraints]
  void onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    if (controller == null) {
      return;
    }

    final CameraController cameraController = controller!;

    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    cameraController.setExposurePoint(offset);
    cameraController.setFocusPoint(offset);
  }

  /// Reset Kamera
  ///
  /// reset kamera with [description]
  void onNewCameraSelected(CameraDescription description) async {
    if (controller != null) {
      await controller!.dispose();
    }

    final CameraController cameraController = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    controller = cameraController;

    // cameraController.addListener(() {
    //   if (mounted) setState(() {});

    //   if (cameraController.value.hasError) {
    //     logError("00", cameraController.value.errorDescription);
    //   }
    // });

    try {
      await cameraController.initialize();
      await cameraController.getMaxZoomLevel().then((value) => _maxAvailableZoom = value);
      await cameraController.getMinZoomLevel().then((value) => _minAvailableZoom = value);
    } on CameraException catch (e) {
      cameraController.dispose();
      // logError(e.code, e.description);
    }
  }

  /// print log
  ///
  void logError(String code, String? message) {
    if (message != null) {
      print('Error: $code\nError Message: $message');
    } else {
      print('Error: $code');
    }
  }
}
