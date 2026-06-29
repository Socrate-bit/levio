import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../../dismiss/screens/breathing_mission_screen.dart';
import '../cubit/screentime_cubit.dart';
import '../cubit/screentime_state.dart';
import '../models/screentime_schedule.dart';
import '../widgets/unlock_countdown_dialog.dart';
import 'schedule_form_screen.dart';

class ScreenTimeDetailScreen extends StatefulWidget {
  const ScreenTimeDetailScreen({super.key});

  @override
  State<ScreenTimeDetailScreen> createState() => _ScreenTimeDetailScreenState();
}

class _ScreenTimeDetailScreenState extends State<ScreenTimeDetailScreen> {
  ScreenTimeCubit? _cubit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cubit = context.read<ScreenTimeCubit>();
  }

  @override
  void dispose() {
    // Re-lock the controls when leaving so unlocking only lasts for this visit.
    _cubit?.relock();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: BlocBuilder<ScreenTimeCubit, ScreenTimeState>(
          builder: (context, state) {
            final locked = state.controlsLocked;
            return Column(
              children: [
                _TopBar(title: l10n.screenTimeTitle),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8.h),
                        _StatusCard(state: state),
                        SizedBox(height: 16.h),
                        _ActivatedCard(state: state, locked: locked),
                        SizedBox(height: 16.h),
                        _AppsCard(state: state, locked: locked),
                        SizedBox(height: 16.h),
                        _SchedulesSection(state: state, locked: locked),
                        SizedBox(height: 16.h),
                        _UnlockSection(locked: locked),
                        SizedBox(height: 32.h),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: withHaptic(() => Navigator.pop(context)),
            child: Container(
              width: 40.w,
              height: 40.h,
              decoration: BoxDecoration(
                color: c.card,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 8),
                ],
              ),
              child: Icon(Icons.arrow_back, size: 20.sp, color: c.textPrimary),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: TextStyle(fontSize: 19.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SizedBox(width: 40.w),
        ],
      ),
    );
  }
}

/// "Active until HH:MM" / "Active in Xh Ym" / "Inactive".
class _StatusCard extends StatelessWidget {
  final ScreenTimeState state;
  const _StatusCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final active = state.isActiveNow;

    String label;
    if (active && state.activeUntil != null) {
      final t = TimeOfDay.fromDateTime(state.activeUntil!).format(context);
      label = l10n.screenTimeStatusActiveUntil(t);
    } else if (state.activeIn != null) {
      label = l10n.screenTimeStatusActiveIn(_formatDuration(state.activeIn!));
    } else {
      label = l10n.screenTimeStatusInactive;
    }

    final color = active ? AppColors.orange : c.textSecondary;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withAlpha(60), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(active ? Icons.shield : Icons.shield_outlined, color: color, size: 26.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                    color: c.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  l10n.screenTimeSubtitle,
                  style: TextStyle(fontSize: 13.sp, color: c.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

class _ActivatedCard extends StatelessWidget {
  final ScreenTimeState state;
  final bool locked;
  const _ActivatedCard({required this.state, required this.locked});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return _Card(
      child: Row(
        children: [
          Icon(Icons.power_settings_new, size: 22.sp, color: c.textSecondary),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              l10n.screenTimeActivated,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
          ),
          if (locked)
            Icon(Icons.lock, size: 18.sp, color: c.textSecondary),
          SizedBox(width: 8.w),
          Switch(
            value: state.enabled,
            activeThumbColor: c.purpleDeep,
            onChanged: locked
                ? null
                : withHapticValue((v) async {
                    final cubit = context.read<ScreenTimeCubit>();
                    final messenger = ScaffoldMessenger.of(context);
                    await cubit.setEnabled(v);
                    if (v && cubit.state.auth == ScreenTimeAuth.denied) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(l10n.screenTimeAuthDenied)),
                      );
                    }
                  }),
          ),
        ],
      ),
    );
  }
}

class _AppsCard extends StatelessWidget {
  final ScreenTimeState state;
  final bool locked;
  const _AppsCard({required this.state, required this.locked});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return _Card(
      onTap: locked ? null : () => context.read<ScreenTimeCubit>().pickApps(),
      child: Row(
        children: [
          Icon(Icons.apps, size: 22.sp, color: c.textSecondary),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.screenTimePickApps,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: c.textPrimary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  state.hasSelectedApps
                      ? l10n.screenTimeAppsBlocked(state.selectedAppCount)
                      : l10n.screenTimeNoAppsSelected,
                  style: TextStyle(fontSize: 13.sp, color: c.textSecondary),
                ),
              ],
            ),
          ),
          if (locked)
            Icon(Icons.lock, size: 18.sp, color: c.textSecondary)
          else
            Icon(Icons.chevron_right, color: c.textSecondary),
        ],
      ),
    );
  }
}

class _SchedulesSection extends StatelessWidget {
  final ScreenTimeState state;
  final bool locked;
  const _SchedulesSection({required this.state, required this.locked});

  Future<void> _addSchedule(BuildContext context) async {
    final result = await Navigator.push<ScreenTimeSchedule>(
      context,
      MaterialPageRoute(builder: (_) => const ScheduleFormScreen()),
    );
    if (result != null && context.mounted) {
      context.read<ScreenTimeCubit>().addSchedule(result);
    }
  }

  Future<void> _editSchedule(
    BuildContext context,
    ScreenTimeSchedule schedule,
  ) async {
    final result = await Navigator.push<ScreenTimeSchedule>(
      context,
      MaterialPageRoute(builder: (_) => ScheduleFormScreen(schedule: schedule)),
    );
    if (result != null && context.mounted) {
      context.read<ScreenTimeCubit>().updateSchedule(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.screenTimeSchedulesTitle,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: c.textPrimary,
              ),
            ),
            const Spacer(),
            if (!locked)
              GestureDetector(
                onTap: withHaptic(() => _addSchedule(context)),
                child: Row(
                  children: [
                    Icon(Icons.add, size: 18.sp, color: AppColors.orange),
                    SizedBox(width: 2.w),
                    Text(
                      l10n.screenTimeAddSchedule,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.orange,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        SizedBox(height: 10.h),
        if (state.schedules.isEmpty)
          _Card(
            child: Text(
              l10n.screenTimeNoSchedules,
              style: TextStyle(fontSize: 14.sp, color: c.textSecondary),
            ),
          )
        else
          ...state.schedules.map(
            (s) => Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: _ScheduleRow(
                schedule: s,
                locked: locked,
                onTap: () => _editSchedule(context, s),
              ),
            ),
          ),
      ],
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  final ScreenTimeSchedule schedule;
  final bool locked;
  final VoidCallback onTap;
  const _ScheduleRow({
    required this.schedule,
    required this.locked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final start = TimeOfDay(hour: schedule.startHour, minute: schedule.startMinute)
        .format(context);
    final end = TimeOfDay(hour: schedule.endHour, minute: schedule.endMinute)
        .format(context);

    return GestureDetector(
      onTap: locked ? null : withHaptic(onTap),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$start – $end',
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.bold,
                      color: c.textPrimary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    _daysLabel(l10n, schedule.repeatDays),
                    style: TextStyle(fontSize: 13.sp, color: c.textSecondary),
                  ),
                ],
              ),
            ),
            Switch(
              value: schedule.enabled,
              activeThumbColor: c.purpleDeep,
              onChanged: locked
                  ? null
                  : withHapticValue((v) => context
                      .read<ScreenTimeCubit>()
                      .toggleSchedule(schedule.id, v)),
            ),
            if (!locked)
              GestureDetector(
                onTap: withHaptic(() =>
                    context.read<ScreenTimeCubit>().removeSchedule(schedule.id)),
                child: Icon(
                  Icons.delete_outline,
                  size: 22.sp,
                  color: c.textSecondary.withAlpha(140),
                ),
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
    for (var i = 0; i < days.length; i++) {
      if (days[i]) selected.add(localizedDayShort(l10n, i));
    }
    if (days[1] && days[2] && days[3] && days[4] && days[5] &&
        !days[0] && !days[6]) {
      return l10n.alarmsWeekdays;
    }
    return selected.join(', ');
  }
}

/// Outcome of the unlock confirmation dialog.
enum _UnlockChoice { keepLocked, breathe, unlock }

/// The "Unlock" button is always present so its context stays mounted across
/// the confirm dialog; it is only actionable (and red) while controls are
/// locked, and rendered gray/disabled otherwise. Tapping it runs the
/// discouraging confirmation + focus-locked countdown.
class _UnlockSection extends StatelessWidget {
  final bool locked;
  const _UnlockSection({required this.locked});

  /// First a centered confirmation ("do you really want to unlock?"), then the
  /// focus-locked countdown dialog if the user proceeds. The middle "breathe"
  /// option launches a short calming exercise instead of unlocking.
  Future<void> _onUnlock(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ScreenTimeCubit>();
    final choice = await showDialog<_UnlockChoice>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n.screenTimeUnlockConfirmTitle,
          textAlign: TextAlign.center,
        ),
        content: Text(
          l10n.screenTimeUnlockConfirmBody,
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Main, recommended action: keep the controls locked.
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, _UnlockChoice.keepLocked),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    minimumSize: Size(double.infinity, 48.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    l10n.screenTimeUnlockConfirmCancel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              // Calming alternative: breathe instead of giving in.
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, _UnlockChoice.breathe),
                  style: OutlinedButton.styleFrom(
                    minimumSize: Size(double.infinity, 48.h),
                    side: BorderSide(color: AppColors.blue.withAlpha(140)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    l10n.screenTimeUnlockConfirmBreathe,
                    style: const TextStyle(
                      color: AppColors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 4.h),
              // Discouraged action: unlock anyway.
              TextButton(
                onPressed: () => Navigator.pop(ctx, _UnlockChoice.unlock),
                child: Text(
                  l10n.screenTimeUnlockConfirmProceed,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    if (!context.mounted) return;

    // Breathe: launch a short standalone breathing exercise (no alarm side
    // effects) instead of unlocking.
    if (choice == _UnlockChoice.breathe) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const BreathingMissionScreen(
            alarmId: '',
            nativeAlarmId: '',
            rounds: 5,
            isPreview: true,
            manageAlarm: false,
          ),
        ),
      );
      return;
    }

    if (choice != _UnlockChoice.unlock) return;

    cubit.startUnlockCountdown();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const UnlockCountdownDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        if (locked) ...[
          Row(
            children: [
              Icon(Icons.lock, size: 16.sp, color: c.textSecondary),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  l10n.screenTimeLockedHint,
                  style: TextStyle(fontSize: 13.sp, color: c.textSecondary),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
        ],
        OutlinedButton(
          onPressed: locked ? withHaptic(() => _onUnlock(context)) : null,
          style: OutlinedButton.styleFrom(
            minimumSize: Size(double.infinity, 52.h),
            side: BorderSide(
              color: locked ? AppColors.error.withAlpha(120) : c.separator,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
          ),
          child: Text(
            l10n.screenTimeUnlock,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: locked ? AppColors.error : c.textSecondary.withAlpha(120),
            ),
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _Card({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: withHaptic(onTap),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: child,
      ),
    );
  }
}
