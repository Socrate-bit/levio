import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../shared/theme/app_theme.dart';
import '../models/mission.dart';
import '../models/mission_config.dart';
import 'mission_icon.dart';

/// Overlapping row of mission icons (avatar-group style). Shared by the alarm
/// list and the home "next alarm" card. The white ring assumes a [AppColors.card]
/// background behind the stack.
class StackedMissionIcons extends StatelessWidget {
  final List<MissionConfig> missions;
  const StackedMissionIcons({super.key, required this.missions});

  @override
  Widget build(BuildContext context) {
    final size = 20.w;
    final overlap = 8.w;
    final width = size + (missions.length - 1) * (size - overlap);
    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        children: [
          for (int i = 0; i < missions.length; i++)
            Positioned(
              left: i * (size - overlap),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: missionInfoFor(missions[i].type).iconBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.of(context).card,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: MissionIcon(
                    info: missionInfoFor(missions[i].type),
                    size: 14.sp,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
