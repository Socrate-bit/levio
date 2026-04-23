import 'dart:async';

import 'package:camera/camera.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';
import '../../alarms/services/alarm_cascade_controller.dart';

import '../../missions/models/mission.dart';
import '../../missions/widgets/item_picker_screen.dart';
import '../../wakeup/screens/wakeup_complete_screen.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../widgets/levio_brand_header.dart';

/// Returns the default item labels for a hunt mission type.
List<String> _defaultItemsFor(MissionType type) {
  final ItemPickerData data;
  switch (type) {
    case MissionType.objectHunt:
      data = objectHuntPickerData;
    case MissionType.petHunt:
      data = petHuntPickerData;
    case MissionType.natureHunt:
      data = natureHuntPickerData;
    default:
      return [];
  }
  return data.sections.expand((s) => s.items).map((i) => i.label).toList();
}

class PhotoDismissScreen extends StatefulWidget {
  final String alarmId;
  final String nativeAlarmId;
  final MissionType missionType;
  final String alarmLabel;
  final List<String>? selectedItems;
  final VoidCallback? onComplete;
  final VoidCallback? onProgress;
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
    this.onProgress,
    this.manageAlarm = true,
    this.isPreview = false,
  });

  @override
  State<PhotoDismissScreen> createState() => _PhotoDismissScreenState();
}

enum _PhotoError { none, notDetected, other }

class _PhotoDismissScreenState extends State<PhotoDismissScreen> {
  CameraController? _controller;
  bool _isValidating = false;
  _PhotoError _errorType = _PhotoError.none;
  String? _rawError;
  final _startTime = DateTime.now();
  late final String _targetObject;
  late final List<String> _candidates;
  String _displayLabel = '';
  bool _rouletteRunning = false;
  Timer? _rouletteTimer;
  AlarmCascadeController? _cascade;

  // Roulette tick delays (ms) — start fast, decelerate, dramatic last beat.
  static const _rouletteDelays = <int>[
    80, 80, 80, 90, 100, 120, 140, 170, 210, 260, 320, 400, 500, 650, 850,
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Determine target object for hunt missions
    final items = (widget.selectedItems != null && widget.selectedItems!.isNotEmpty)
        ? widget.selectedItems!
        : _defaultItemsFor(widget.missionType);
    _candidates = List<String>.from(items);
    _targetObject = _candidates.isNotEmpty
        ? (List<String>.from(_candidates)..shuffle()).first
        : '';

    // Roulette only runs when there are multiple candidates to reveal.
    if (_candidates.length > 1) {
      // Start on any candidate that is not the target so the reveal isn't
      // spoiled on the very first frame.
      _displayLabel = _candidates.firstWhere(
        (c) => c != _targetObject,
        orElse: () => _candidates.first,
      );
      _rouletteRunning = true;
      _scheduleRouletteTick(0);
    } else {
      _displayLabel = _targetObject;
    }

    _initCamera();
    if (widget.manageAlarm && !widget.isPreview) {
      _cascade = AlarmCascadeController(alarmId: widget.alarmId)..start();
    }
  }

  /// Recursively schedules each roulette tick using a growing delay table.
  /// The final tick lands on [_targetObject] and unlocks the take-photo button.
  void _scheduleRouletteTick(int step) {
    _rouletteTimer = Timer(Duration(milliseconds: _rouletteDelays[step]), () {
      if (!mounted) return;
      final isLast = step == _rouletteDelays.length - 1;
      setState(() {
        if (isLast) {
          _displayLabel = _targetObject;
          _rouletteRunning = false;
        } else {
          // Advance to next candidate, skipping the target until the final tick
          // so the reveal is not spoiled mid-spin.
          final currentIndex = _candidates.indexOf(_displayLabel);
          var nextIndex = (currentIndex + 1) % _candidates.length;
          if (_candidates[nextIndex] == _targetObject &&
              _candidates.length > 2) {
            nextIndex = (nextIndex + 1) % _candidates.length;
          }
          _displayLabel = _candidates[nextIndex];
        }
      });
      HapticFeedback.selectionClick();
      if (isLast) HapticFeedback.mediumImpact();
      if (!isLast) _scheduleRouletteTick(step + 1);
    });
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      setState(() {
        _errorType = _PhotoError.other;
        _rawError = 'No camera available';
      });
      return;
    }
    final controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await controller.initialize();
    // Lock the camera preview so it doesn't rotate when the device tilts.
    await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
    if (!mounted) return;
    setState(() => _controller = controller);
  }

  Future<void> _captureAndValidate() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (_isValidating) return;

    widget.onProgress?.call();
    _cascade?.reportProgress();

    setState(() {
      _isValidating = true;
      _errorType = _PhotoError.none;
      _rawError = null;
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
        setState(() => _errorType = _PhotoError.notDetected);
      }
    } catch (e) {
      setState(() {
        _errorType = _PhotoError.other;
        _rawError = e.toString();
      });
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

    await _cascade?.finish();

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
    _rouletteTimer?.cancel();
    _controller?.dispose();
    _cascade?.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  // Localized label for the currently displayed target — follows the roulette
  // mid-spin then settles on the actual picked target.
  String _targetLabel(AppLocalizations l10n) => _displayLabel.isNotEmpty
      ? localizedItemName(l10n, _displayLabel)
      : localizedPhotoTarget(l10n, widget.missionType);

  String? _resolveError(AppLocalizations l10n) {
    switch (_errorType) {
      case _PhotoError.none:
        return null;
      case _PhotoError.notDetected:
        return l10n.dismissPhotoNotDetected(_targetLabel(l10n).toLowerCase());
      case _PhotoError.other:
        return _rawError != null ? l10n.dismissPhotoError(_rawError!) : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final l10n = AppLocalizations.of(context);
    final info = missionInfoFor(widget.missionType);
    final targetLabel = _targetLabel(l10n);
    final errorMessage = _resolveError(l10n);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const LevioBrandHeader(textColor: Colors.white),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Text(
                    l10n.dismissPhotoPrompt(targetLabel),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
                ),

                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: controller != null &&
                            controller.value.isInitialized &&
                            controller.value.previewSize != null
                        ? AspectRatio(
                            aspectRatio: controller.value.previewSize!.height /
                                controller.value.previewSize!.width,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(28.r),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  CameraPreview(controller),

                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: RadialGradient(
                                        center: Alignment.center,
                                        radius: 1.0,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withAlpha(80),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Viewfinder corner brackets — frame the target.
                                  const _ViewfinderFrame(),

                                  // Centered target icon (emoji for hunts, mission
                                  // material icon for sky/bed/grass).
                                  Center(
                                    child: _TargetBadge(
                                      label: _displayLabel,
                                      info: info,
                                      isHunt: _targetObject.isNotEmpty,
                                      spinning: _rouletteRunning,
                                    ),
                                  ),

                                  if (errorMessage != null)
                                    Positioned(
                                      top: 14.h,
                                      left: 16.w,
                                      right: 16.w,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 7.h,
                                          horizontal: 14.w,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.error.withAlpha(200),
                                          borderRadius: BorderRadius.circular(12.r),
                                        ),
                                        child: Text(
                                          errorMessage,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13.sp,
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
                                            SizedBox(height: 16.h),
                                            Text(
                                              l10n.dismissPhotoChecking(
                                                  targetLabel.toLowerCase()),
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14.sp,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(
                                color: AppColors.orange,
                                strokeWidth: 2.5,
                              ),
                              SizedBox(height: 16.h),
                              Text(
                                l10n.dismissPhotoStarting,
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 14.sp,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(12),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48.w,
                        height: 48.h,
                        decoration: BoxDecoration(
                          color: info.iconBg,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Center(
                          child: _targetObject.isNotEmpty
                              ? Text(
                                  emojiForItemLabel(_displayLabel) ?? '\u{2b50}',
                                  style: TextStyle(fontSize: 22.sp),
                                )
                              : Icon(info.icon,
                                  color: info.iconColor, size: 24.sp),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.dismissPhotoTakePhoto,
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 10.sp,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            targetLabel,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: (_isValidating || _rouletteRunning)
                          ? null
                          : withHaptic(_captureAndValidate),
                      child: Container(
                        width: 72.w,
                        height: 72.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (_isValidating || _rouletteRunning)
                              ? Colors.white.withAlpha(80)
                              : Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(40),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Icon(Icons.camera_alt,
                            color: Colors.black, size: 32.sp),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    SizedBox(
                      height: 16.h,
                      child: _rouletteRunning
                          ? Text(
                              l10n.dismissPhotoPickingTarget,
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12.sp,
                                letterSpacing: 0.3,
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ],
            ),
            if (widget.isPreview)
              Positioned(
                top: 16.h,
                right: 16.w,
                child: GestureDetector(
                  onTap: withHaptic(() => Navigator.of(context).pop()),
                  child: Container(
                    width: 36.w,
                    height: 36.h,
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, size: 18.sp, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Four white corner brackets framing the camera preview.
class _ViewfinderFrame extends StatelessWidget {
  const _ViewfinderFrame();

  @override
  Widget build(BuildContext context) {
    final inset = 16.w;
    return Stack(
      children: [
        Positioned(top: inset, left: inset, child: const _Corner(top: true, left: true)),
        Positioned(top: inset, right: inset, child: const _Corner(top: true, left: false)),
        Positioned(bottom: inset, left: inset, child: const _Corner(top: false, left: true)),
        Positioned(bottom: inset, right: inset, child: const _Corner(top: false, left: false)),
      ],
    );
  }
}

class _Corner extends StatelessWidget {
  final bool top;
  final bool left;
  const _Corner({required this.top, required this.left});

  @override
  Widget build(BuildContext context) {
    const side = BorderSide(color: Colors.white70, width: 3);
    return Container(
      width: 28.w,
      height: 28.w,
      decoration: BoxDecoration(
        border: Border(
          top: top ? side : BorderSide.none,
          bottom: top ? BorderSide.none : side,
          left: left ? side : BorderSide.none,
          right: left ? BorderSide.none : side,
        ),
      ),
    );
  }
}

/// Centered round badge showing the target — emoji for hunt items, the
/// mission's material icon otherwise. Pulses softly while spinning.
class _TargetBadge extends StatelessWidget {
  final String label;
  final MissionInfo info;
  final bool isHunt;
  final bool spinning;

  const _TargetBadge({
    required this.label,
    required this.info,
    required this.isHunt,
    required this.spinning,
  });

  @override
  Widget build(BuildContext context) {
    final emoji = isHunt ? (emojiForItemLabel(label) ?? '\u{2b50}') : null;
    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: spinning ? 0.94 : 1.0,
      child: Container(
        width: 96.w,
        height: 96.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: info.iconBg.withAlpha(230),
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(60),
              blurRadius: 16,
            ),
          ],
        ),
        child: Center(
          child: emoji != null
              ? Text(emoji, style: TextStyle(fontSize: 48.sp))
              : Icon(info.icon, color: info.iconColor, size: 48.sp),
        ),
      ),
    );
  }
}
