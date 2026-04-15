import 'package:flutter/material.dart';

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
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.onboardingMissionPickerTitle,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.onboardingMissionPickerSubtitle,
                style: TextStyle(fontSize: 16, color: c.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: _missions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final mission = _missions[index];
              final isSelected = selectedMission == mission.type;
              return GestureDetector(
                onTap: withHaptic(() => onSelected(mission.type)),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? c.textPrimary : c.separator,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: mission.iconBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(mission.icon,
                            color: mission.iconColor, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              localizedMissionName(l10n, mission.type),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: c.textPrimary,
                              ),
                            ),
                            Text(
                              localizedMissionDesc(l10n, mission.type),
                              style: TextStyle(
                                  fontSize: 13, color: c.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
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
                            ? Icon(Icons.check, size: 16, color: c.card)
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
