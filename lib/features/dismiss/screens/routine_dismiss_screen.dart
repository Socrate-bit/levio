import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';

import '../../alarms/services/alarm_cascade_controller.dart';
import '../../missions/models/mission.dart';
import '../../wakeup/screens/wakeup_complete_screen.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../widgets/levio_brand_header.dart';

/// Habit-tracker style dismiss screen: tap each step card to check it off. The
/// Validate button unlocks only once every step is checked. Unlike other
/// missions, the routine is self-paced and never times out (the cascade
/// controller is started with the inactivity watchdog disabled).
class RoutineDismissScreen extends StatefulWidget {
  final String alarmId;
  final String nativeAlarmId;
  final String alarmLabel;
  final List<String>? items;
  final VoidCallback? onComplete;
  final VoidCallback? onProgress;
  final bool manageAlarm;
  final bool isPreview;

  const RoutineDismissScreen({
    super.key,
    required this.alarmId,
    required this.nativeAlarmId,
    this.alarmLabel = 'Alarm #1',
    this.items,
    this.onComplete,
    this.onProgress,
    this.manageAlarm = true,
    this.isPreview = false,
  });

  @override
  State<RoutineDismissScreen> createState() => _RoutineDismissScreenState();
}

class _RoutineDismissScreenState extends State<RoutineDismissScreen> {
  late final List<String> _steps;
  final Set<String> _done = {};
  final _startTime = DateTime.now();
  AlarmCascadeController? _cascade;

  bool get _allDone => _done.length >= _steps.length;

  @override
  void initState() {
    super.initState();
    final items = widget.items;
    _steps = (items != null && items.isNotEmpty) ? items : routinePresetSteps;
    if (widget.manageAlarm && !widget.isPreview) {
      // No watchdog — the routine is completed at the user's own pace.
      _cascade = AlarmCascadeController(alarmId: widget.alarmId)
        ..start(enableInactivityWatchdog: false);
    }
  }

  void _toggle(String step) {
    // Haptic is fired by the _StepCard's withHaptic wrapper.
    widget.onProgress?.call();
    _cascade?.reportProgress();
    setState(() {
      if (!_done.remove(step)) _done.add(step);
    });
  }

  Future<void> _validate() async {
    if (!_allDone) return;

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
            missionType: MissionType.routine,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _cascade?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const LevioBrandHeader(),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Text(
                    l10n.routineTapToComplete,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15.sp, color: c.textSecondary),
                  ),
                ),
                SizedBox(height: 16.h),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                    itemCount: _steps.length,
                    separatorBuilder: (_, _) => SizedBox(height: 12.h),
                    itemBuilder: (_, i) {
                      final step = _steps[i];
                      final done = _done.contains(step);
                      return _StepCard(
                        label: localizedItemName(l10n, step),
                        done: done,
                        onTap: () => _toggle(step),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
                  child: ElevatedButton(
                    onPressed: _allDone ? withHaptic(_validate) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: c.separator,
                      disabledForegroundColor: c.textSecondary,
                      minimumSize: Size(double.infinity, 56.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _allDone
                          ? l10n.routineValidate
                          : '${_done.length} / ${_steps.length}',
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w600,
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

/// A single tappable routine-step card with a check indicator.
class _StepCard extends StatelessWidget {
  final String label;
  final bool done;
  final VoidCallback onTap;

  const _StepCard({
    required this.label,
    required this.done,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: withHaptic(onTap),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
        decoration: BoxDecoration(
          color: done ? AppColors.orange.withAlpha(20) : c.card,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: done ? AppColors.orange : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 26.w,
              height: 26.h,
              decoration: BoxDecoration(
                color: done ? AppColors.orange : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: done ? AppColors.orange : c.separator,
                  width: 2,
                ),
              ),
              child: done
                  ? Icon(Icons.check, size: 16.sp, color: Colors.white)
                  : null,
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: c.textPrimary,
                  decoration: done ? TextDecoration.lineThrough : null,
                  decorationColor: c.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
