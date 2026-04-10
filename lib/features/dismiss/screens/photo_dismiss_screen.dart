import 'package:camera/camera.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../alarms/services/alarm_channel.dart';

import '../../missions/models/mission.dart';
import '../../wakeup/screens/wakeup_complete_screen.dart';
import '../../../shared/theme/app_theme.dart';

const _houseObjects = [
  'coffee mug', 'book', 'lamp', 'pillow', 'remote control',
  'water bottle', 'shoes', 'plant', 'clock', 'chair',
  'towel', 'mirror', 'candle', 'bag', 'headphones',
  'pen', 'cup', 'key', 'hat', 'glasses',
];

class PhotoDismissScreen extends StatefulWidget {
  final String alarmId;
  final MissionType missionType;
  final String alarmLabel;
  final String? customObject;

  const PhotoDismissScreen({
    super.key,
    required this.alarmId,
    this.missionType = MissionType.skyPhoto,
    this.alarmLabel = 'Alarm #1',
    this.customObject,
  });

  @override
  State<PhotoDismissScreen> createState() => _PhotoDismissScreenState();
}

class _PhotoDismissScreenState extends State<PhotoDismissScreen> {
  CameraController? _controller;
  bool _isValidating = false;
  String? _errorMessage;
  final _startTime = DateTime.now();
  late final String _targetObject;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    if (widget.missionType == MissionType.objectHunt) {
      _targetObject = widget.customObject?.isNotEmpty == true
          ? widget.customObject!
          : (_houseObjects..shuffle()).first;
    } else {
      _targetObject = '';
    }
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
      final prompt = widget.missionType == MissionType.objectHunt
          ? 'Does this image clearly show a $_targetObject? Reply with only YES or NO.'
          : geminiPromptFor(widget.missionType);
      final response = await model.generateContent([
        Content.multi([
          TextPart(prompt),
          InlineDataPart('image/jpeg', imageBytes),
        ]),
      ]);

      final answer = response.text?.trim().toUpperCase() ?? '';
      if (answer.contains('YES')) {
        await _dismiss();
      } else {
        final info = missionInfoFor(widget.missionType);
        setState(() =>
            _errorMessage = 'No ${info.name.toLowerCase()} detected — try again');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  Future<void> _dismiss() async {
    await AlarmChannel.dismissAlarm(widget.alarmId);
    final elapsed = DateTime.now().difference(_startTime).inSeconds;
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => WakeupCompleteScreen(
            alarmId: widget.alarmId,
            timeTakenSeconds: elapsed,
            missionType: widget.missionType,
          ),
        ),
      );
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
    final info = missionInfoFor(widget.missionType);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Camera preview
            if (controller != null && controller.value.isInitialized)
              CameraPreview(controller)
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // Mission target overlay card
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(160),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'TAKE A PHOTO OF',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: info.iconBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(info.icon,
                            color: info.iconColor, size: 28),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.missionType == MissionType.objectHunt
                            ? _targetObject
                            : info.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Loading overlay
            if (_isValidating)
              Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                          color: AppColors.orange),
                      const SizedBox(height: 16),
                      Text(
                        'Checking for ${info.name.toLowerCase()}…',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16),
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
                  padding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900.withAlpha(220),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 15),
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
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(40),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.black,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),

          ],
        ),
      ),
    );
  }
}
