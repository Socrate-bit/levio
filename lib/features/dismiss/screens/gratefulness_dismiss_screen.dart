import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';

import '../../../shared/theme/app_theme.dart';
import '../../alarms/services/alarm_cascade_controller.dart';
import '../../missions/models/mission.dart';
import '../../wakeup/screens/wakeup_complete_screen.dart';
import '../widgets/levio_brand_header.dart';

/// Gratefulness mission. Asks 3 positive-focus questions one at a time; the
/// user types an answer for each. Answers are not persisted — they only gate
/// completion (must be non-empty). Designed to start the day on a positive note.
class GratefulnessDismissScreen extends StatefulWidget {
  final String alarmId;
  final String nativeAlarmId;
  final String alarmLabel;
  final VoidCallback? onComplete;
  final VoidCallback? onProgress;
  final bool manageAlarm;
  final bool isPreview;

  const GratefulnessDismissScreen({
    super.key,
    required this.alarmId,
    required this.nativeAlarmId,
    this.alarmLabel = 'Alarm #1',
    this.onComplete,
    this.onProgress,
    this.manageAlarm = true,
    this.isPreview = false,
  });

  @override
  State<GratefulnessDismissScreen> createState() =>
      _GratefulnessDismissScreenState();
}

class _GratefulnessDismissScreenState extends State<GratefulnessDismissScreen> {
  static const _questionCount = 3;
  // Minimum trimmed answer length to count as a meaningful response.
  static const _minLength = 2;

  final _ctrl = TextEditingController();
  int _index = 0;
  final _startTime = DateTime.now();
  AlarmCascadeController? _cascade;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    if (widget.manageAlarm && !widget.isPreview) {
      _cascade = AlarmCascadeController(alarmId: widget.alarmId)..start();
    }
  }

  bool get _canAdvance => _ctrl.text.trim().length >= _minLength;

  String _question(AppLocalizations l10n) {
    switch (_index) {
      case 0:
        return l10n.gratefulnessQuestion1;
      case 1:
        return l10n.gratefulnessQuestion2;
      default:
        return l10n.gratefulnessQuestion3;
    }
  }

  void _next() {
    if (!_canAdvance) return;
    widget.onProgress?.call();
    _cascade?.reportProgress();
    HapticFeedback.lightImpact();
    if (_index + 1 >= _questionCount) {
      _dismiss();
    } else {
      setState(() {
        _index++;
        _ctrl.clear();
      });
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
            missionType: MissionType.gratefulness,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _cascade?.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final isLast = _index + 1 >= _questionCount;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const LevioBrandHeader(),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.gratefulnessProgress(_index + 1, _questionCount),
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: c.textSecondary,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4.r),
                          child: LinearProgressIndicator(
                            value: _index / _questionCount,
                            minHeight: 6.h,
                            backgroundColor: c.separator,
                            valueColor: const AlwaysStoppedAnimation(
                              AppColors.orange,
                            ),
                          ),
                        ),
                        SizedBox(height: 40.h),
                        Text(
                          _question(l10n),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: c.textPrimary,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 28.h),
                        TextField(
                          controller: _ctrl,
                          autofocus: true,
                          minLines: 2,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.done,
                          style: TextStyle(
                            fontSize: 18.sp,
                            color: c.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: l10n.gratefulnessHint,
                            hintStyle: TextStyle(
                              fontSize: 16.sp,
                              color: c.textSecondary,
                            ),
                            filled: true,
                            fillColor: c.card,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14.r),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.all(16.w),
                          ),
                          onChanged: (_) {
                            widget.onProgress?.call();
                            _cascade?.reportProgress();
                            setState(() {});
                          },
                          onSubmitted: (_) => _next(),
                        ),
                        SizedBox(height: 24.h),
                        ElevatedButton(
                          onPressed: _canAdvance ? _next : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: c.textPrimary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: c.separator,
                            minimumSize: Size(double.infinity, 54.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            isLast
                                ? l10n.gratefulnessFinish
                                : l10n.gratefulnessNext,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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
                    decoration: BoxDecoration(
                      color: c.card,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, size: 18.sp, color: c.textPrimary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
