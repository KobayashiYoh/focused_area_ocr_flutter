import 'dart:ui' as ui;
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:focused_area_ocr_flutter/coordinate_util.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// A custom painter for rendering the focused area and recognized text on a canvas.
class FocusedAreaOCRPainter extends CustomPainter {
  FocusedAreaOCRPainter({
    required this.recognizedText,
    required this.imageSize,
    required this.rotation,
    required this.cameraLensDirection,
    required this.focusedAreaWidth,
    required this.focusedAreaHeight,
    required this.focusedAreaCenter,
    required this.focusedAreaRadius,
    this.focusedAreaPaint,
    this.unfocusedAreaPaint,
    this.textBackgroundPaint,
    this.uiTextStyle,
    this.onScanText,
  });

  /// The recognized text data.
  final RecognizedText recognizedText;

  /// The size of the image.
  final Size imageSize;

  /// The rotation of the image.
  final InputImageRotation rotation;

  /// The direction of the camera lens.
  final CameraLensDirection cameraLensDirection;

  /// The width of the focused area.
  final double focusedAreaWidth;

  /// The height of the focused area.
  final double focusedAreaHeight;

  /// The center position of the focused area.
  final Offset focusedAreaCenter;

  /// The radius of the focused area's corners.
  final Radius focusedAreaRadius;

  /// The paint to use for drawing the focused area.
  final Paint? focusedAreaPaint;

  /// The paint to use for drawing the unfocused area.
  final Paint? unfocusedAreaPaint;

  /// The paint to use for drawing the background of recognized text.
  final Paint? textBackgroundPaint;

  /// The text style to use for recognized text, using `dart:ui`'s `TextStyle` instead of `material.dart`'s `TextStyle`.
  final ui.TextStyle? uiTextStyle;

  /// Callback function called when text is scanned.
  final Function? onScanText;

  /// Draws the focused area on the canvas.
  void _drawFocusedArea(Canvas canvas, RRect focusedRRect) {
    final Paint defaultPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.blue;
    canvas.drawRRect(
      focusedRRect,
      focusedAreaPaint == null ? defaultPaint : focusedAreaPaint!,
    );
  }

  /// Draws the unfocused area on the canvas.
  void _drawUnfocusedArea(Canvas canvas, Size size, RRect focusedRRect) {
    final Offset deviceCenter = Offset(size.width / 2, size.height / 2);
    final Rect deviceRect = Rect.fromCenter(
      center: deviceCenter,
      width: size.width,
      height: size.height,
    );
    final Paint defaultPaint = Paint()..color = const Color(0x99000000);
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(deviceRect),
        Path()..addRRect(focusedRRect),
      ),
      unfocusedAreaPaint == null ? defaultPaint : unfocusedAreaPaint!,
    );
  }

  /// Draws the recognized text and its background on the canvas.
  void _drawText(Canvas canvas, TextBlock textBlock, Rect textRect) {
    final ui.TextStyle defaultStyle = ui.TextStyle(
      color: Colors.lightGreenAccent,
      background: Paint()..color = const Color(0x99000000),
    );
    final ParagraphBuilder builder = ParagraphBuilder(
      ParagraphStyle(),
    );
    builder.pushStyle(uiTextStyle == null ? defaultStyle : uiTextStyle!);
    builder.addText(textBlock.text);
    builder.pop();
    canvas.drawParagraph(
      builder.build()
        ..layout(
          ParagraphConstraints(width: (textRect.right - textRect.left).abs()),
        ),
      Offset(textRect.left, textRect.top),
    );
  }

  /// Draws the background for the recognized text on the canvas.
  void _drawTextBackground(Canvas canvas, TextBlock textBlock, Size size) {
    final List<Offset> cornerPoints = <Offset>[];
    for (final point in textBlock.cornerPoints) {
      final double x = CoordinateUtil.translateX(
        x: point.x.toDouble(),
        canvasSize: size,
        imageSize: imageSize,
        rotation: rotation,
        cameraLensDirection: cameraLensDirection,
      );
      final double y = CoordinateUtil.translateY(
        y: point.y.toDouble(),
        canvasSize: size,
        imageSize: imageSize,
        rotation: rotation,
        cameraLensDirection: cameraLensDirection,
      );
      cornerPoints.add(Offset(x, y));
    }
    cornerPoints.add(cornerPoints.first);
    final Paint defaultPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.lightGreenAccent;
    canvas.drawPoints(
      PointMode.polygon,
      cornerPoints,
      textBackgroundPaint == null ? defaultPaint : textBackgroundPaint!,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final RRect focusedRRect = RRect.fromLTRBR(
      ((size.width - focusedAreaWidth) / 2) + focusedAreaCenter.dx,
      ((size.height - focusedAreaHeight) / 2) + focusedAreaCenter.dy,
      ((size.width - focusedAreaWidth) / 2 + focusedAreaWidth) +
          focusedAreaCenter.dx,
      ((size.height - focusedAreaHeight) / 2 + focusedAreaHeight) +
          focusedAreaCenter.dy,
      focusedAreaRadius,
    );

    _drawUnfocusedArea(canvas, size, focusedRRect);
    _drawFocusedArea(canvas, focusedRRect);

    for (final textBlock in recognizedText.blocks) {
      final double textLeft = CoordinateUtil.translateX(
        x: textBlock.boundingBox.left,
        canvasSize: size,
        imageSize: imageSize,
        rotation: rotation,
        cameraLensDirection: cameraLensDirection,
      );
      final double textTop = CoordinateUtil.translateY(
        y: textBlock.boundingBox.top,
        canvasSize: size,
        imageSize: imageSize,
        rotation: rotation,
        cameraLensDirection: cameraLensDirection,
      );
      final double textRight = CoordinateUtil.translateX(
        x: textBlock.boundingBox.right,
        canvasSize: size,
        imageSize: imageSize,
        rotation: rotation,
        cameraLensDirection: cameraLensDirection,
      );
      final double textBottom = CoordinateUtil.translateY(
        y: textBlock.boundingBox.bottom,
        canvasSize: size,
        imageSize: imageSize,
        rotation: rotation,
        cameraLensDirection: cameraLensDirection,
      );
      final Rect textRect =
          Rect.fromLTRB(textLeft, textTop, textRight, textBottom);

      final bool hasPointInRange =
          CoordinateUtil.hasPointInRange(focusedRRect, textRect);
      if (hasPointInRange) {
        _drawTextBackground(canvas, textBlock, size);
        _drawText(canvas, textBlock, textRect);
        if (onScanText != null) {
          onScanText!(textBlock.text);
        }
      }
    }
  }

  @override
  bool shouldRepaint(FocusedAreaOCRPainter oldDelegate) {
    return oldDelegate.recognizedText != recognizedText;
  }
}
