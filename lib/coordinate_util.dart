import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

/// Utility class for handling coordinate translations and checks.
class CoordinateUtil {
  /// Translates the X coordinate based on canvas and image size, rotation, and camera lens direction.
  ///
  /// [x] The X coordinate to be translated.
  /// [canvasSize] The size of the canvas where the image is displayed.
  /// [imageSize] The size of the original image.
  /// [rotation] The rotation of the input image.
  /// [cameraLensDirection] The direction of the camera lens (front or back).
  /// Returns the translated X coordinate.
  static double translateX({
    required double x,
    required Size canvasSize,
    required Size imageSize,
    required InputImageRotation rotation,
    required CameraLensDirection cameraLensDirection,
  }) {
    double imageWidth = Platform.isIOS ? imageSize.width : imageSize.height;
    switch (rotation) {
      case InputImageRotation.rotation90deg:
        return x * canvasSize.width / imageWidth;
      case InputImageRotation.rotation270deg:
        return canvasSize.width - x * canvasSize.width / imageWidth;
      case InputImageRotation.rotation0deg:
      case InputImageRotation.rotation180deg:
        double translatedX = x * canvasSize.width / imageSize.width;
        return cameraLensDirection == CameraLensDirection.front
            ? canvasSize.width - translatedX
            : translatedX;
    }
  }

  /// Translates the Y coordinate based on canvas and image size, rotation, and camera lens direction.
  ///
  /// [y] The Y coordinate to be translated.
  /// [canvasSize] The size of the canvas where the image is displayed.
  /// [imageSize] The size of the original image.
  /// [rotation] The rotation of the input image.
  /// [cameraLensDirection] The direction of the camera lens (front or back).
  /// Returns the translated Y coordinate.
  static double translateY({
    required double y,
    required Size canvasSize,
    required Size imageSize,
    required InputImageRotation rotation,
    required CameraLensDirection cameraLensDirection,
  }) {
    double imageHeight = Platform.isIOS ? imageSize.height : imageSize.width;
    switch (rotation) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        return y * canvasSize.height / imageHeight;
      case InputImageRotation.rotation0deg:
      case InputImageRotation.rotation180deg:
        return y * canvasSize.height / imageSize.height;
    }
  }

  /// Checks if a point represented by a rectangle is within the range of another rounded rectangle.
  ///
  /// [focusedRRect] The rounded rectangle representing the focus area.
  /// [textRect] The rectangle representing the text area..
  /// Returns true if the point represented by [textRect] is within [focusedRRect], otherwise false.
  static bool hasPointInRange(RRect focusedRRect, Rect textRect) {
    final double minX = focusedRRect.left;
    final double maxX = focusedRRect.right;
    if (textRect.left < minX || textRect.right > maxX) {
      return false;
    }
    final double minY = focusedRRect.top;
    final double maxY = focusedRRect.bottom;
    if (textRect.top < minY || textRect.bottom > maxY) {
      return false;
    }
    return true;
  }
}
