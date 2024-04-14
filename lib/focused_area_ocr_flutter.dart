import 'dart:io';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:focused_area_ocr_flutter/focused_area_ocr_painter.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'camera_util.dart';

/// A widget for capturing live camera feed and performing OCR on a focused area of the camera view.
class FocusedAreaOCRView extends StatefulWidget {
  const FocusedAreaOCRView({
    Key? key,
    this.focusedAreaWidth = 200.0,
    this.focusedAreaHeight = 40.0,
    this.focusedAreaCenter = Offset.zero,
    this.focusedAreaRadius = const Radius.circular(8.0),
    this.focusedAreaPaint,
    this.unfocusedAreaPaint,
    this.textBackgroundPaint,
    this.paintTextStyle,
    required this.onScanText,
    this.script = TextRecognitionScript.latin,
    this.showDropdown = true,
    this.onCameraFeedReady,
    this.onDetectorViewModeChanged,
    this.onCameraLensDirectionChanged,
  }) : super(key: key);

  /// The width of the focused area.
  final double? focusedAreaWidth;

  /// The height of the focused area.
  final double? focusedAreaHeight;

  /// The center position of the focused area.
  final Offset? focusedAreaCenter;

  /// The radius of the focused area's corners.
  final Radius? focusedAreaRadius;

  /// The paint to use for drawing the focused area.
  final Paint? focusedAreaPaint;

  /// The paint to use for drawing the unfocused area.
  final Paint? unfocusedAreaPaint;

  /// The paint to use for drawing the background of recognized text.
  final Paint? textBackgroundPaint;

  /// The text style to use for recognized text, using `dart:ui`'s `TextStyle` instead of `material.dart`'s `TextStyle`.
  final ui.TextStyle? paintTextStyle;

  /// Callback function called when text is scanned.
  final Function? onScanText;

  /// The script used for text recognition.
  final TextRecognitionScript script;

  /// Whether to show the script dropdown (for selecting recognition script).
  final bool showDropdown;

  /// Callback function called when the camera feed is ready.
  final VoidCallback? onCameraFeedReady;

  /// Callback function called when the detector view mode changes.
  final VoidCallback? onDetectorViewModeChanged;

  /// Callback function called when the camera lens direction changes.
  final Function(CameraLensDirection direction)? onCameraLensDirectionChanged;

  @override
  State<FocusedAreaOCRView> createState() => _FocusedAreaOCRViewState();
}

class _FocusedAreaOCRViewState extends State<FocusedAreaOCRView> {
  late TextRecognizer _textRecognizer;
  TextRecognitionScript _script = TextRecognitionScript.latin;
  bool _canProcess = true;
  bool _isLoading = false;
  CustomPaint? _customPaint;
  final CameraLensDirection _cameraLensDirection = CameraLensDirection.back;
  static List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _cameraIndex = -1;

  /// Processes the input image for text recognition.
  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess || _isLoading) {
      return;
    }
    _isLoading = true;
    final recognizedText = await _textRecognizer.processImage(inputImage);
    final bool isEmptyImageMetadata = inputImage.metadata?.size == null ||
        inputImage.metadata?.rotation == null;
    if (isEmptyImageMetadata) {
      _customPaint = null;
    } else {
      final painter = FocusedAreaOCRPainter(
        recognizedText: recognizedText,
        imageSize: inputImage.metadata!.size,
        rotation: inputImage.metadata!.rotation,
        cameraLensDirection: _cameraLensDirection,
        focusedAreaWidth: widget.focusedAreaWidth!,
        focusedAreaHeight: widget.focusedAreaHeight!,
        focusedAreaCenter: widget.focusedAreaCenter!,
        focusedAreaRadius: widget.focusedAreaRadius!,
        focusedAreaPaint: widget.focusedAreaPaint,
        unfocusedAreaPaint: widget.unfocusedAreaPaint,
        textBackgroundPaint: widget.textBackgroundPaint,
        uiTextStyle: widget.paintTextStyle,
        onScanText: widget.onScanText,
      );
      _customPaint = CustomPaint(painter: painter);
    }
    _isLoading = false;
    if (mounted) {
      setState(() {});
    }
  }

  /// Starts the live camera feed.
  Future<void> _startLiveFeed() async {
    final camera = _cameras[_cameraIndex];
    final imageFormatGroup =
        Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888;
    _controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: imageFormatGroup,
    );
    _controller?.initialize().then((_) {
      if (!mounted) {
        return;
      }
      _controller?.startImageStream(_processCameraImage).then((value) {
        if (widget.onCameraFeedReady != null) {
          widget.onCameraFeedReady!();
        }
        if (widget.onCameraLensDirectionChanged != null) {
          widget.onCameraLensDirectionChanged!(camera.lensDirection);
        }
      });
      setState(() {});
    });
  }

  /// Stops the live camera feed.
  Future<void> _stopLiveFeed() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }

  /// Processes the camera image received from the live feed.
  ///
  /// [image] The camera image to process.
  void _processCameraImage(CameraImage image) {
    final inputImage = CameraUtil.inputImageFromCameraImage(
      image: image,
      controller: _controller,
      cameras: _cameras,
      cameraIndex: _cameraIndex,
    );
    if (inputImage == null) {
      return;
    }
    _processImage(inputImage);
  }

  /// Initializes the camera by setting up available cameras and starting the live feed.
  Future<void> _initialize() async {
    if (_cameras.isEmpty) {
      _cameras = await availableCameras();
    }
    for (var i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection == _cameraLensDirection) {
        _cameraIndex = i;
        break;
      }
    }
    if (_cameraIndex != -1) {
      _startLiveFeed();
    }
  }

  @override
  void initState() {
    _script = widget.script;
    _textRecognizer = TextRecognizer(script: _script);
    _initialize();
    super.initState();
  }

  @override
  void dispose() async {
    _canProcess = false;
    _textRecognizer.close();
    _stopLiveFeed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isNotInitialized = _cameras.isEmpty ||
        _controller == null ||
        _controller?.value.isInitialized == false;
    if (isNotInitialized) {
      return const SizedBox.shrink();
    }
    return CameraPreview(
      _controller!,
      child: _customPaint,
    );
  }
}
