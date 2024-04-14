import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

/// Utility class for handling camera-related operations.
class CameraUtil {
  /// Utility class for handling camera-related operations.
  static final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  /// Generates an input image from a camera image.
  ///
  /// [image] is the image data from the camera.
  /// [controller] is the camera controller.
  /// [cameras] is the list of available cameras.
  /// [cameraIndex] is the index of the camera to use.
  /// Returns an [InputImage] object if successful, otherwise returns null.
  static InputImage? inputImageFromCameraImage({
    required CameraImage image,
    required CameraController? controller,
    required List<CameraDescription> cameras,
    required int cameraIndex,
  }) {
    if (controller == null) {
      return null;
    }
    final camera = cameras[cameraIndex];
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      int? rotationCompensation =
          _orientations[controller.value.deviceOrientation];
      if (rotationCompensation == null) {
        return null;
      }
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }
    if (rotation == null) {
      return null;
    }
    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    final bool isValidFormat = format == null ||
        (Platform.isAndroid && format != InputImageFormat.nv21) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888);
    if (isValidFormat) {
      return null;
    }
    if (image.planes.length != 1) {
      return null;
    }
    final plane = image.planes.first;
    final size = Size(image.width.toDouble(), image.height.toDouble());
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: size,
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }
}
