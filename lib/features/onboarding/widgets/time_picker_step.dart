import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../shared/theme/app_theme.dart';

class TimePickerStep extends StatefulWidget {
  final String title;
  final String? subtitle;
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onTimeChanged;

  const TimePickerStep({
    super.key,
    required this.title,
    this.subtitle,
    required this.time,
    required this.onTimeChanged,
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
    _hourController = FixedExtentScrollController(initialItem: widget.time.hour);
    _minuteController =
        FixedExtentScrollController(initialItem: widget.time.minute);
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
          if (widget.subtitle != null) ...[
            SizedBox(height: 8.h),
            Text(
              widget.subtitle!,
              style: TextStyle(fontSize: 16.sp, color: c.textSecondary),
            ),
          ],
          const Spacer(),
          Center(
            child: Text(
              _formatTime(widget.time),
              style: TextStyle(
                fontSize: 64.sp,
                fontWeight: FontWeight.bold,
                color: c.textPrimary,
              ),
            ),
          ),
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
                      widget.onTimeChanged(
                        TimeOfDay(hour: index, minute: widget.time.minute),
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
                      widget.onTimeChanged(
                        TimeOfDay(hour: widget.time.hour, minute: index),
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
