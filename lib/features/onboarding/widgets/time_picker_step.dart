import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';

import '../../../shared/theme/app_theme.dart';

class TimePickerStep extends StatefulWidget {
  final String title;
  // Use subtitle for a static string, subtitleBuilder for one that tracks the
  // selected time (e.g. "Your alarm will ring at HH:mm").
  final String? subtitle;
  final String Function(TimeOfDay)? subtitleBuilder;
  // Notifier is updated locally on every scroll tick; the parent reads its
  // value once on Continue instead of emitting a Bloc state per tick.
  final ValueNotifier<TimeOfDay> notifier;
  // When set (bedtime picker), shows a live sleep-duration badge comparing the
  // picked time to this wake-up time, colour-coded by how much sleep it leaves.
  final TimeOfDay? compareWakeTime;

  const TimePickerStep({
    super.key,
    required this.title,
    this.subtitle,
    this.subtitleBuilder,
    required this.notifier,
    this.compareWakeTime,
  });

  @override
  State<TimePickerStep> createState() => _TimePickerStepState();
}

class _TimePickerStepState extends State<TimePickerStep> {
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  @override
  void initState() {
    super.initState();
    _hourController =
        FixedExtentScrollController(initialItem: widget.notifier.value.hour);
    _minuteController =
        FixedExtentScrollController(initialItem: widget.notifier.value.minute);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
              height: 1.2,
            ),
          ),
          if (widget.subtitle != null || widget.subtitleBuilder != null) ...[
            SizedBox(height: 8.h),
            if (widget.subtitleBuilder != null)
              ValueListenableBuilder<TimeOfDay>(
                valueListenable: widget.notifier,
                builder: (_, time, _) => Text(
                  widget.subtitleBuilder!(time),
                  style: TextStyle(fontSize: 16.sp, color: c.textSecondary),
                ),
              )
            else
              Text(
                widget.subtitle!,
                style: TextStyle(fontSize: 16.sp, color: c.textSecondary),
              ),
          ],
          const Spacer(),
          Center(
            child: ValueListenableBuilder<TimeOfDay>(
              valueListenable: widget.notifier,
              builder: (_, time, _) => Text(
                _formatTime(time),
                style: TextStyle(
                  fontSize: 64.sp,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                ),
              ),
            ),
          ),
          if (widget.compareWakeTime != null) ...[
            SizedBox(height: 14.h),
            Center(
              child: ValueListenableBuilder<TimeOfDay>(
                valueListenable: widget.notifier,
                builder: (_, bedtime, _) => _SleepDurationBadge(
                  bedtime: bedtime,
                  wakeTime: widget.compareWakeTime!,
                ),
              ),
            ),
          ],
          SizedBox(height: 16.h),
          SizedBox(
            height: 200.h,
            child: Row(
              children: [
                Expanded(
                  child: CupertinoPicker(
                    scrollController: _hourController,
                    itemExtent: 40.h,
                    onSelectedItemChanged: (index) {
                      widget.notifier.value = TimeOfDay(
                        hour: index,
                        minute: widget.notifier.value.minute,
                      );
                    },
                    children: List.generate(
                      24,
                      (i) => Center(
                        child: Text(
                          i.toString().padLeft(2, '0'),
                          style: TextStyle(
                              fontSize: 22.sp, color: c.textPrimary),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    scrollController: _minuteController,
                    itemExtent: 40.h,
                    onSelectedItemChanged: (index) {
                      widget.notifier.value = TimeOfDay(
                        hour: widget.notifier.value.hour,
                        minute: index,
                      );
                    },
                    children: List.generate(
                      60,
                      (i) => Center(
                        child: Text(
                          i.toString().padLeft(2, '0'),
                          style: TextStyle(
                              fontSize: 22.sp, color: c.textPrimary),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

/// Pill showing how much sleep the picked bedtime leaves before [wakeTime],
/// colour-coded: red under 6h, green from 6h to under 8h, blue at 8h or more.
class _SleepDurationBadge extends StatelessWidget {
  final TimeOfDay bedtime;
  final TimeOfDay wakeTime;

  const _SleepDurationBadge({required this.bedtime, required this.wakeTime});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Minutes from bedtime to wake-up, rolling over midnight when needed.
    final bedMin = bedtime.hour * 60 + bedtime.minute;
    final wakeMin = wakeTime.hour * 60 + wakeTime.minute;
    var total = wakeMin - bedMin;
    if (total <= 0) total += 24 * 60;

    final Color color;
    if (total < 6 * 60) {
      color = const Color(0xFFE53935); // red — under 6h, too little
    } else if (total < 7 * 60) {
      color = const Color(0xFFF9A825); // yellow — 6–7h, a bit short
    } else if (total < 8 * 60) {
      color = const Color(0xFF43A047); // green — 7–8h, healthy range
    } else {
      color = const Color(0xFF1E88E5); // blue — 8h or more, plenty
    }

    final h = total ~/ 60;
    final m = total % 60;
    final duration = m == 0 ? '${h}h' : '${h}h${m.toString().padLeft(2, '0')}';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bedtime_outlined, size: 16.sp, color: color),
          SizedBox(width: 6.w),
          Text(
            l10n.onboardingSleepDurationBadge(duration),
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
