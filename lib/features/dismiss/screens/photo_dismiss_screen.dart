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
  AlarmCascadeController? _cascade;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Determine target object for hunt missions
    final items = (widget.selectedItems != null && widget.selectedItems!.isNotEmpty)
        ? widget.selectedItems!
        : _defaultItemsFor(widget.missionType);
    _targetObject = items.isNotEmpty
        ? (List<String>.from(items)..shuffle()).first
        : '';

    _initCamera();
    if (widget.manageAlarm && !widget.isPreview) {
      _cascade = AlarmCascadeController(alarmId: widget.alarmId)..start();
    }
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
    _controller?.dispose();
    _cascade?.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  String? _resolveError(AppLocalizations l10n) {
    switch (_errorType) {
      case _PhotoError.none:
        return null;
      case _PhotoError.notDetected:
        return l10n.dismissPhotoNotDetected(
          localizedPhotoTarget(l10n, widget.missionType).toLowerCase(),
        );
      case _PhotoError.other:
        return _rawError != null ? l10n.dismissPhotoError(_rawError!) : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final l10n = AppLocalizations.of(context);
    final info = missionInfoFor(widget.missionType);
    final targetLabel = _targetObject.isNotEmpty ? localizedItemName(l10n, _targetObject) : localizedPhotoTarget(l10n, widget.missionType);
    final errorMessage = _resolveError(l10n);

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
                  padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 0),
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

                SizedBox(height: 16.h),

                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28.r),
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
                                        color: const Color(0xFFE53935).withAlpha(200),
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
                                            l10n.dismissPhotoChecking(localizedPhotoTarget(l10n, widget.missionType).toLowerCase()),
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
                            )
                          : ColoredBox(
                              color: const Color(0xFF1A1A1A),
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
                    ),
                  ),
                ),

                SizedBox(height: 20.h),

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
                        child: Icon(info.icon, color: info.iconColor, size: 24.sp),
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

                SizedBox(height: 20.h),

                GestureDetector(
                  onTap: _isValidating ? null : withHaptic(_captureAndValidate),
                  child: Container(
                    width: 72.w,
                    height: 72.h,
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
                    child: Icon(Icons.camera_alt, color: Colors.black, size: 32.sp),
                  ),
                ),

                SizedBox(height: 32.h),
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
