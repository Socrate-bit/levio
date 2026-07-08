import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../../../shared/widgets/day_selector_row.dart';
import '../../../shared/widgets/time_picker_sheet.dart';
import '../models/screentime_schedule.dart';

/// Add / edit a single blocking window. Returns the resulting
/// [ScreenTimeSchedule] via Navigator.pop, or null if cancelled.
class ScheduleFormScreen extends StatefulWidget {
  final ScreenTimeSchedule? schedule;

  const ScheduleFormScreen({super.key, this.schedule});

  @override
  State<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends State<ScheduleFormScreen> {
  late List<bool> _repeatDays;
  late TimeOfDay _start;
  late TimeOfDay _end;

  bool get _isEditing => widget.schedule != null;

  @override
  void initState() {
    super.initState();
    final s = widget.schedule;
    if (s != null) {
      _repeatDays = List.from(s.repeatDays);
      _start = TimeOfDay(hour: s.startHour, minute: s.startMinute);
      _end = TimeOfDay(hour: s.endHour, minute: s.endMinute);
    } else {
      _repeatDays = List.filled(7, true);
      _start = const TimeOfDay(hour: 22, minute: 0);
      _end = const TimeOfDay(hour: 7, minute: 0);
    }
  }

  bool get _canSave => _repeatDays.any((d) => d);

  void _save() {
    final base = widget.schedule ?? ScreenTimeSchedule.create();
    final result = base.copyWith(
      repeatDays: _repeatDays,
      startHour: _start.hour,
      startMinute: _start.minute,
      endHour: _end.hour,
      endMinute: _end.minute,
    );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: withHaptic(() => Navigator.pop(context)),
                    child: Container(
                      width: 40.w,
                      height: 40.h,
                      decoration: BoxDecoration(
                        color: c.card,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(12),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(Icons.close, size: 20.sp, color: c.textPrimary),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        _isEditing
                            ? l10n.screenTimeScheduleEdit
                            : l10n.screenTimeScheduleNew,
                        style: TextStyle(
                          fontSize: 19.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 40.w),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  children: [
                    SizedBox(height: 16.h),
                    _Card(
                      onTap: () async {
                        final picked = await showTimePickerSheet(
                          context,
                          initial: _start,
                          title: l10n.screenTimeStartTime,
                        );
                        if (picked != null) setState(() => _start = picked);
                      },
                      child: _timeRow(c, l10n.screenTimeStartTime, _start),
                    ),
                    SizedBox(height: 12.h),
                    _Card(
                      onTap: () async {
                        final picked = await showTimePickerSheet(
                          context,
                          initial: _end,
                          title: l10n.screenTimeEndTime,
                        );
                        if (picked != null) setState(() => _end = picked);
                      },
                      child: _timeRow(c, l10n.screenTimeEndTime, _end),
                    ),
                    SizedBox(height: 12.h),
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.alarmFormRepeatOn,
                            style: TextStyle(
                              fontSize: 15.sp,
                              color: c.textSecondary,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          DaySelectorRow(
                            days: _repeatDays,
                            onChanged: (next) =>
                                setState(() => _repeatDays = next),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              child: ElevatedButton(
                onPressed: _canSave ? withHaptic(_save) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _canSave ? c.textPrimary : c.separator,
                  foregroundColor: _canSave ? c.background : c.textSecondary,
                  minimumSize: Size(double.infinity, 56.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  l10n.screenTimeSaveSchedule,
                  style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeRow(AppColors c, String label, TimeOfDay time) {
    return Row(
      children: [
        Text(label, style: TextStyle(fontSize: 17.sp, color: c.textPrimary)),
        const Spacer(),
        Text(
          time.format(context),
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w600,
            color: c.textPrimary,
          ),
        ),
        SizedBox(width: 4.w),
        Icon(Icons.chevron_right, size: 22.sp, color: c.textSecondary),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _Card({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: withHaptic(onTap),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: child,
      ),
    );
  }
}
