import 'package:camera/camera.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_alarmkit/flutter_alarmkit.dart';

class PhotoDismissScreen extends StatefulWidget {
  final String alarmId;

  const PhotoDismissScreen({super.key, required this.alarmId});

  @override
  State<PhotoDismissScreen> createState() => _PhotoDismissScreenState();
}

class _PhotoDismissScreenState extends State<PhotoDismissScreen> {
  CameraController? _controller;
  bool _isValidating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      setState(() => _errorMessage = 'No camera available');
      return;
    }
    final controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await controller.initialize();
    if (!mounted) return;
    setState(() => _controller = controller);
  }

  Future<void> _captureAndValidate() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (_isValidating) return;

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    try {
      final image = await controller.takePicture();
      final imageBytes = await image.readAsBytes();

      final model = FirebaseAI.googleAI()
          .generativeModel(model: 'gemini-2.0-flash-lite');
      final response = await model.generateContent([
        Content.multi([
          TextPart(
            'Does this image clearly show a door? '
            'Reply with only YES or NO.',
          ),
          InlineDataPart('image/jpeg', imageBytes),
        ]),
      ]);

      final answer = response.text?.trim().toUpperCase() ?? '';
      if (answer.contains('YES')) {
        await FlutterAlarmkit().stopAlarm(alarmId: widget.alarmId);
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        setState(() => _errorMessage = 'No door detected — try again');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          if (controller != null && controller.value.isInitialized)
            CameraPreview(controller)
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Red alarm banner
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.redAccent.withAlpha(220),
              padding: const EdgeInsets.fromLTRB(16, 52, 16, 12),
              child: const Text(
                'ALARM — Point at a door and take a photo to dismiss',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          // Loading overlay
          if (_isValidating)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Checking for door…',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

          // Error message
          if (_errorMessage != null)
            Positioned(
              bottom: 140,
              left: 24,
              right: 24,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade900.withAlpha(220),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            ),

          // Capture button
          if (!_isValidating)
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _captureAndValidate,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      color: Colors.white24,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 32,
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
