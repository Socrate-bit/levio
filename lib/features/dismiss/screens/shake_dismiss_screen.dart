import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import '../../alarms/services/alarm_cascade_controller.dart';
import 'package:shake/shake.dart';

import '../../missions/models/mission.dart';
import '../../wakeup/screens/wakeup_complete_screen.dart';
import '../../../shared/theme/app_theme.dart';
import '../widgets/levio_brand_header.dart';

class ShakeDismissScreen extends StatefulWidget {
  final String alarmId;
  final String nativeAlarmId;
  final String alarmLabel;
  final int target;
  final VoidCallback? onComplete;
  final VoidCallback? onProgress;
  final bool manageAlarm;
  final bool isPreview;

  const ShakeDismissScreen({
    super.key,
    required this.alarmId,
    required this.nativeAlarmId,
    this.alarmLabel = 'Alarm #1',
    this.target = 15,
    this.onComplete,
    this.onProgress,
    this.manageAlarm = true,
    this.isPreview = false,
  });

  @override
  State<ShakeDismissScreen> createState() => _ShakeDismissScreenState();
}

class _ShakeDismissScreenState extends State<ShakeDismissScreen> {
  int _shakeCount = 0;
  late final ShakeDetector _detector;
  final _startTime = DateTime.now();
  AlarmCascadeController? _cascade;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _detector = ShakeDetector.autoStart(
      shakeThresholdGravity: 1.5,
      shakeSlopTimeMS: 500,
      minimumShakeCount: 1,
      onPhoneShake: (_) => _onShake(),
    );
    if (widget.manageAlarm && !widget.isPreview) {
      _cascade = AlarmCascadeController(alarmId: widget.alarmId)..start();
    }
  }

  void _onShake() {
    if (_shakeCount >= widget.target) return;
    HapticFeedback.mediumImpact();
    widget.onProgress?.call();
    _cascade?.reportProgress();
    setState(() => _shakeCount++);
    if (_shakeCount >= widget.target) {
      _dismiss();
    }
  }

  Future<void> _dismiss() async {
    _detector.stopListening();

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
            missionType: MissionType.shakePhone,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _detector.stopListening();
    _cascade?.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final progress = _shakeCount / widget.target;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const LevioBrandHeader(),
                Expanded(
                  child: Center(

                    child: Padding(
                      padding: EdgeInsets.all(8.0.w),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 220.w,
                            height: 220.h,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox.expand(
                                  child: CircularProgressIndicator(
                                    value: progress,
                                    strokeWidth: 12,
                                    backgroundColor: c.separator,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          AppColors.orange,
                                        ),
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          '$_shakeCount',

                                          style: TextStyle(
                                            color: c.textPrimary,
                                            fontSize: 64.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '/ ${widget.target}',
                                          style: TextStyle(
                                            color: c.textSecondary,
                                            fontSize: 22.sp,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 24.h),
                          Text(
                            l10n.dismissShakePrompt,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            style: TextStyle(

                              fontSize: 18.sp,
                              color: c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (widget.isPreview)
              Positioned(
                top: 16.h,
                right: 16.w,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 36.w,
                    height: 36.h,
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 18.sp,
                      color: Colors.white,
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
