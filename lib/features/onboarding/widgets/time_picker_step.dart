import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
              height: 1.2,
            ),
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.subtitle!,
              style: TextStyle(fontSize: 16, color: c.textSecondary),
            ),
          ],
          const Spacer(),
          Center(
            child: Text(
              _formatTime(widget.time),
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: c.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  child: CupertinoPicker(
                    scrollController: _hourController,
                    itemExtent: 40,
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
                              fontSize: 22, color: c.textPrimary),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    scrollController: _minuteController,
                    itemExtent: 40,
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
                              fontSize: 22, color: c.textPrimary),
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
