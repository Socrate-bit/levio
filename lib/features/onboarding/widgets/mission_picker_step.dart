import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../../missions/models/mission.dart';
import '../../missions/models/mission_config.dart';
import '../../missions/widgets/mission_config_modal.dart';
import '../../missions/widgets/mission_icon.dart';

class MissionPickerStep extends StatelessWidget {
  final MissionType? selectedMission;
  // Config for the currently selected mission, used to pre-fill the config
  // modal when re-tapping it.
  final MissionConfig? selectedConfig;
  final ValueChanged<MissionConfig> onSelected;

  const MissionPickerStep({
    super.key,
    required this.selectedMission,
    this.selectedConfig,
    required this.onSelected,
  });

  // Open the mission config ("customize") modal; report back only if the user
  // confirms a config (cancelling leaves the current selection unchanged).
  Future<void> _pickMission(BuildContext context, MissionInfo mission) async {
    final config = await showMissionConfigModal(
      context,
      mission,
      selectedConfig?.type == mission.type ? selectedConfig : null,
    );
    if (config != null) onSelected(config);
  }

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
          padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                l10n.onboardingMissionPickerTitle,
                textAlign: TextAlign.center,
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
                textAlign: TextAlign.center,
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
                onTap: withHaptic(() => _pickMission(context, mission)),
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
                        child: Center(
                          child: MissionIcon(info: mission, size: 28.sp),
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizedMissionName(l10n, mission.type),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: c.textPrimary,
                              ),
                            ),
                            Text(
                              localizedMissionDesc(l10n, mission.type),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
