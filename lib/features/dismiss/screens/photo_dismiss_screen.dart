import 'package:camera/camera.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../alarms/services/alarm_channel.dart';

import '../../missions/models/mission.dart';
import '../../wakeup/screens/wakeup_complete_screen.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/levio_brand_header.dart';

var _houseObjects = [
  'coffee mug', 'book', 'lamp', 'pillow', 'remote control',
  'water bottle', 'shoes', 'plant', 'clock', 'chair',
  'towel', 'mirror', 'candle', 'bag', 'headphones',
  'pen', 'cup', 'key', 'hat', 'glasses',
];

class PhotoDismissScreen extends StatefulWidget {
  final String alarmId;
  final String nativeAlarmId;
  final MissionType missionType;
  final String alarmLabel;
  final List<String>? selectedItems;
  final VoidCallback? onComplete;
  final bool manageAlarm;
  final bool isPreview;

  const PhotoDismissScreen({
    super.key,
    required this.alarmId,
    required this.nativeAlarmId,
    this.missionType = MissionType.skyPhoto,
    this.alarmLabel = 'Alarm #1',
    this.selectedItems,
    this.onComplete,
    this.manageAlarm = true,
    this.isPreview = false,
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
  String? _missionSnoozeId;
  bool _keepRinging = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Determine target object for hunt missions
    if (widget.missionType == MissionType.objectHunt ||
        widget.missionType == MissionType.petHunt ||
        widget.missionType == MissionType.natureHunt) {
      if (widget.selectedItems != null && widget.selectedItems!.isNotEmpty) {
        _targetObject = (List<String>.from(widget.selectedItems!)..shuffle()).first;
      } else if (widget.missionType == MissionType.objectHunt) {
        _targetObject = (_houseObjects..shuffle()).first;
      } else {
        _targetObject = '';
      }
    } else {
      _targetObject = '';
    }

    _initCamera();
    if (widget.manageAlarm && !widget.isPreview) _initAlarm();
  }

  Future<void> _initAlarm() async {
    final prefs = await SharedPreferences.getInstance();
    _keepRinging = prefs.getBool('keep_alarm_during_mission') ?? false;
    if (!_keepRinging) {
      await AlarmChannel.dismissAlarm(widget.nativeAlarmId);
      _missionSnoozeId = await AlarmChannel.scheduleMissionSnooze(
        nativeAlarmId: widget.nativeAlarmId,
        originalAlarmId: widget.alarmId,
      );
    }
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
          .generativeModel(model: 'gemini-2.5-flash-lite');

      final String prompt;
      if (_targetObject.isNotEmpty) {
        prompt = 'Does this image clearly show a $_targetObject? Reply with only YES or NO.';
      } else {
        prompt = geminiPromptFor(widget.missionType);
      }

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
            _errorMessage = 'No ${info.name.toLowerCase()} detected \u2014 try again');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  Future<void> _dismiss() async {
    if (widget.isPreview) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    if (widget.onComplete != null) {
      widget.onComplete!();
      return;
    }

    if (widget.manageAlarm) {
      await AlarmChannel.cancelMissionSnooze(_missionSnoozeId);
      await AlarmChannel.cancelSnoozesForAlarm(widget.alarmId);
      await AlarmChannel.stopRinging();
    }

    final elapsed = DateTime.now().difference(_startTime).inSeconds;
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => WakeupCompleteScreen(
            alarmId: widget.alarmId,
            nativeAlarmId: widget.nativeAlarmId,
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
    final targetLabel = _targetObject.isNotEmpty ? _targetObject : info.name;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const LevioBrandHeader(textColor: Colors.white),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Text(
                    'Take a photo of $targetLabel to stop the alarm',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: controller != null && controller.value.isInitialized
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                CameraPreview(controller),

                                const DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      center: Alignment.center,
                                      radius: 1.0,
                                      colors: [
                                        Colors.transparent,
                                        Color(0x50000000),
                                      ],
                                    ),
                                  ),
                                ),

                                if (_errorMessage != null)
                                  Positioned(
                                    top: 14,
                                    left: 16,
                                    right: 16,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 7,
                                        horizontal: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE53935).withAlpha(200),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _errorMessage!,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),

                                if (_isValidating)
                                  Container(
                                    color: Colors.black54,
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const CircularProgressIndicator(
                                            color: AppColors.orange,
                                            strokeWidth: 2.5,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            'Checking for ${info.name.toLowerCase()}\u2026',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          : const ColoredBox(
                              color: Color(0xFF1A1A1A),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      color: AppColors.orange,
                                      strokeWidth: 2.5,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'Starting camera\u2026',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 14,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: info.iconBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(info.icon, color: info.iconColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'TAKE A PHOTO OF',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 10,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            targetLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                GestureDetector(
                  onTap: _isValidating ? null : _captureAndValidate,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isValidating
                          ? Colors.white.withAlpha(80)
                          : Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(40),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.black, size: 32),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
            if (widget.isPreview)
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 18, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
