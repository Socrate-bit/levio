import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';
import '../utils/haptic_utils.dart';

/// A row of 7 tappable day circles (Sun..Sat), used for repeat-day selection.
///
/// Extracted from the alarm form so the alarm and screen-time features share a
/// single repeat-day selector. [days] is length 7, index 0 = Sunday.
class DaySelectorRow extends StatelessWidget {
  final List<bool> days;
  final ValueChanged<List<bool>> onChanged;

  const DaySelectorRow({
    super.key,
    required this.days,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final dayLabels = [
      l10n.daySingleSun,
      l10n.daySingleMon,
      l10n.daySingleTue,
      l10n.daySingleWed,
      l10n.daySingleThu,
      l10n.daySingleFri,
      l10n.daySingleSat,
    ];

    return Row(
      children: List.generate(7, (i) {
        final selected = days[i];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: i == 0 ? 0 : 4.w,
              right: i == 6 ? 0 : 4.w,
            ),
            child: GestureDetector(
              onTap: withHaptic(() {
                final next = List<bool>.from(days)..[i] = !selected;
                onChanged(next);
              }),
              child: AspectRatio(
                aspectRatio: 1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? AppColors.orange : c.background,
                  ),
                  child: Center(
                    child: Text(
                      dayLabels[i],
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : c.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
