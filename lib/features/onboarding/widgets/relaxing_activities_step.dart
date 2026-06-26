import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../../missions/widgets/routine_picker_screen.dart';

/// Lets the user build their bedtime wind-down routine during onboarding by
/// reusing the app's real [RoutinePickerScreen] (full-screen card route with
/// add-your-own-step support). The chosen labels become the bedtime alarm's
/// `routine` mission.
class RelaxingActivitiesStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const RelaxingActivitiesStep({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onChanged,
  });

  Future<void> _openPicker(BuildContext context) async {
    final result = await Navigator.push<List<String>>(
      context,
      MaterialPageRoute(
        builder: (_) => RoutinePickerScreen(preselected: selected),
      ),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
              height: 1.2,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            style: TextStyle(fontSize: 16.sp, color: c.textSecondary),
          ),
          SizedBox(height: 24.h),
          // Tappable card opening the shared routine picker.
          GestureDetector(
            onTap: withHaptic(() => _openPicker(context)),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: c.separator),
              ),
              child: Row(
                children: [
                  Icon(Icons.bedtime_outlined,
                      size: 22.sp, color: c.textSecondary),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      selected.isEmpty
                          ? l10n.onboardingRelaxActivitiesChoose
                          : l10n.onboardingRelaxActivitiesCount(selected.length),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 22.sp, color: c.textSecondary),
                ],
              ),
            ),
          ),
          if (selected.isNotEmpty) ...[
            SizedBox(height: 16.h),
            Wrap(
              spacing: 10.w,
              runSpacing: 10.h,
              children: [
                for (final label in selected)
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      localizedItemName(l10n, label),
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
