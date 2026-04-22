import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../../missions/models/mission.dart';

class MissionPickerStep extends StatelessWidget {
  final MissionType? selectedMission;
  final ValueChanged<MissionType> onSelected;

  const MissionPickerStep({
    super.key,
    required this.selectedMission,
    required this.onSelected,
  });

  static final _missions = allMissions
      .where((m) => m.type != MissionType.none && m.type != MissionType.random)
      .toList();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.onboardingMissionPickerTitle,
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                l10n.onboardingMissionPickerSubtitle,
                style: TextStyle(fontSize: 16.sp, color: c.textSecondary),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            itemCount: _missions.length,
            separatorBuilder: (_, _) => SizedBox(height: 10.h),
            itemBuilder: (context, index) {
              final mission = _missions[index];
              final isSelected = selectedMission == mission.type;
              return GestureDetector(
                onTap: withHaptic(() => onSelected(mission.type)),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: isSelected ? c.textPrimary : c.separator,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44.w,
                        height: 44.h,
                        decoration: BoxDecoration(
                          color: mission.iconBg,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Icon(mission.icon,
                            color: mission.iconColor, size: 22.sp),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizedMissionName(l10n, mission.type),
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: c.textPrimary,
                              ),
                            ),
                            Text(
                              localizedMissionDesc(l10n, mission.type),
                              style: TextStyle(
                                  fontSize: 13.sp, color: c.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 24.w,
                        height: 24.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              isSelected ? c.textPrimary : Colors.transparent,
                          border: Border.all(
                            color:
                                isSelected ? c.textPrimary : c.textSecondary,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Icon(Icons.check, size: 16.sp, color: c.card)
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
