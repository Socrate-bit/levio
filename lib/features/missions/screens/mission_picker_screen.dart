import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../../../app.dart' show buildDismissScreen;
import '../models/mission.dart';
import '../models/mission_config.dart';
import '../widgets/mission_config_modal.dart';

class MissionPickerScreen extends StatefulWidget {
  const MissionPickerScreen({super.key});

  @override
  State<MissionPickerScreen> createState() => _MissionPickerScreenState();
}

class _MissionPickerScreenState extends State<MissionPickerScreen> {
  MissionCategory _filter = MissionCategory.all;

  List<MissionInfo> get _filtered {
    if (_filter == MissionCategory.all) return allMissions;
    return allMissions.where((m) => m.category == _filter).toList();
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
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: withHaptic(() => Navigator.pop(context)),
                    child: Container(
                      width: 36.w,
                      height: 36.h,
                      decoration: BoxDecoration(
                        color: c.card,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close,
                          size: 18.sp, color: c.textPrimary),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        l10n.missionPickerTitle,
                        style: TextStyle(
                            fontSize: 17.sp, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  SizedBox(width: 36.w),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            // Filter tabs
            SizedBox(
              height: 38.h,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                children: MissionCategory.values.map((cat) {
                  final label = switch (cat) {
                    MissionCategory.all => l10n.missionPickerAll,
                    MissionCategory.trending => l10n.missionPickerTrending,
                    MissionCategory.hunts => l10n.missionPickerHunts,
                    MissionCategory.physical => l10n.missionPickerPhysical,
                  };
                  final icon = switch (cat) {
                    MissionCategory.all => '\u26a1',
                    MissionCategory.trending => '\ud83d\udd25',
                    MissionCategory.hunts => '\ud83d\udd0d',
                    MissionCategory.physical => '\ud83d\udcaa',
                  };
                  final selected = _filter == cat;
                  return Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: GestureDetector(
                      onTap: withHaptic(() => setState(() => _filter = cat)),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: EdgeInsets.symmetric(
                            horizontal: 14.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.orange : c.card,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          '$icon $label',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : c.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: _filtered.length,
                itemBuilder: (ctx, i) =>
                    _MissionCard(info: _filtered[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final MissionInfo info;
  const _MissionCard({required this.info});

  Future<void> _onTap(BuildContext context) async {
    final config = await showMissionConfigModal(context, info);
    if (config != null && context.mounted) {
      Navigator.pop(context, config);
    }
  }

  void _preview(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final config = MissionConfig(type: info.type);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => buildDismissScreen(
          config: config,
          alarmId: '',
          nativeAlarmId: '',
          alarmLabel: l10n.missionPickerPreview,
          isPreview: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: withHaptic(() => _onTap(context)),
      child: Container(
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52.w,
              height: 52.h,
              decoration: BoxDecoration(
                color: info.iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(info.icon, color: info.iconColor, size: 26.sp),
            ),
            SizedBox(height: 10.h),
            Text(
              localizedMissionName(l10n, info.type),
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
                color: c.textPrimary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              localizedMissionDesc(l10n, info.type),
              style: TextStyle(
                fontSize: 12.sp,
                color: c.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            GestureDetector(
              onTap: withHaptic(() => _preview(context)),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 6.h),
                decoration: BoxDecoration(
                  color: c.background,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow,
                        size: 14.sp, color: c.textSecondary),
                    SizedBox(width: 2.w),
                    Text(
                      l10n.missionPickerPreview,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
