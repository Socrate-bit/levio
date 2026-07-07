import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../../missions/models/mission.dart';
import '../../missions/models/mission_config.dart';
import '../../missions/widgets/mission_icon.dart';
import '../cubit/alarm_cubit.dart';
import '../cubit/alarm_state.dart';
import '../widgets/alarm_kind_icon.dart';
import 'alarm_form_screen.dart';

/// Dedicated tab listing all of the user's alarms (create / edit / toggle /
/// delete). New alarms are created via the global add button in the bottom nav.
class AlarmsScreen extends StatefulWidget {
  const AlarmsScreen({super.key});

  @override
  State<AlarmsScreen> createState() => _AlarmsScreenState();
}

class _AlarmsScreenState extends State<AlarmsScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 12.h),
              Text(
                l10n.alarmsTitle,
                style: TextStyle(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.bold,
                  color: c.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 16.h),
              BlocBuilder<AlarmCubit, AlarmState>(
                builder: (context, state) {
                  if (state.alarms.isEmpty) {
                    return const _EmptyAlarmsCard();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final alarm in state.alarms)
                        Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: _AlarmCard(alarm: alarm),
                        ),
                    ],
                  );
                },
              ),
              SizedBox(height: 120.h),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlarmCard extends StatelessWidget {
  final AppAlarmEntry alarm;
  const _AlarmCard({required this.alarm});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final t = alarm.dateTime;
    final h = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
    final m = t.minute.toString().padLeft(2, '0');
    final isPM = t.hour >= 12;
    final dayStr =
        alarm.isOneTime ? l10n.alarmsOneTime : _daysLabel(l10n, alarm.repeatDays);

    return GestureDetector(
      onTap: withHaptic(() => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<AlarmCubit>(),
                child: AlarmFormScreen(alarm: alarm),
              ),
            ),
          )),
      child: Container(
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(6), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AlarmKindIcon(isSleep: alarm.isSleep),
                SizedBox(width: 8.w),
                Text(
                  dayStr,
                  style: TextStyle(fontSize: 13.sp, color: c.textSecondary),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$h:$m',
                  style: TextStyle(
                    fontSize: 44.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                    color: c.textPrimary,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 8.h, left: 4.w),
                  child: Text(
                    isPM ? 'PM' : 'AM',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: c.textSecondary,
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.only(bottom: 10.h),
                  child: Switch(
                    value: alarm.isEnabled,
                    activeThumbColor: c.purpleDeep,
                    onChanged: withHapticValue((val) =>
                        context.read<AlarmCubit>().toggleAlarm(alarm.id, val)),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  alarm.name.isNotEmpty ? alarm.name : l10n.alarmsDefaultName(1),
                  style: TextStyle(fontSize: 13.sp, color: c.textSecondary),
                ),
                if (alarm.missions.isNotEmpty) ...[
                  Text(' · ',
                      style:
                          TextStyle(fontSize: 13.sp, color: c.textSecondary)),
                  _StackedMissionIcons(missions: alarm.missions),
                  SizedBox(width: 6.w),
                  Text(
                    alarm.missions.length == 1
                        ? localizedMissionName(l10n, alarm.missions.first.type)
                        : l10n.alarmsMissionsCount(alarm.missions.length),
                    style: TextStyle(fontSize: 13.sp, color: c.textSecondary),
                  ),
                ],
                const Spacer(),
                GestureDetector(
                  onTap: withHaptic(
                      () => context.read<AlarmCubit>().removeAlarm(alarm.id)),
                  child: Icon(Icons.delete_outline,
                      size: 32.sp, color: c.textSecondary.withAlpha(140)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _daysLabel(AppLocalizations l10n, List<bool> days) {
    if (days.every((d) => d)) return l10n.alarmsEveryDay;
    if (days.every((d) => !d)) return l10n.alarmsOneTime;

    final selected = <String>[];
    for (int i = 0; i < days.length; i++) {
      if (days[i]) selected.add(localizedDayShort(l10n, i));
    }
    if (days[1] &&
        days[2] &&
        days[3] &&
        days[4] &&
        days[5] &&
        !days[0] &&
        !days[6]) {
      return l10n.alarmsWeekdays;
    }
    return selected.join(', ');
  }
}

/// Stacked/overlapping mission icons.
class _StackedMissionIcons extends StatelessWidget {
  final List<MissionConfig> missions;
  const _StackedMissionIcons({required this.missions});

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

class _EmptyAlarmsCard extends StatelessWidget {
  const _EmptyAlarmsCard();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Center(
        child: Column(
          children: [
            Image.asset('assets/siren.png', width: 48.w, height: 48.h),
            SizedBox(height: 12.h),
            Text(
              l10n.alarmsEmpty,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              l10n.alarmsEmptyHint,
              style: TextStyle(fontSize: 14.sp, color: c.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
