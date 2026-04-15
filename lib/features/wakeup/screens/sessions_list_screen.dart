import 'package:flutter/material.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';

import '../../../features/missions/models/mission.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../models/wakeup_session.dart';
import '../services/history_service.dart';
import 'today_wakeup_screen.dart';

class SessionsListScreen extends StatefulWidget {
  const SessionsListScreen({super.key});

  @override
  State<SessionsListScreen> createState() => _SessionsListScreenState();
}

class _SessionsListScreenState extends State<SessionsListScreen> {
  List<WakeupSession>? _sessions;
  int _totalWakeups = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      HistoryService.getSessions(limit: 50, includeIncomplete: true),
      HistoryService.getTotalWakeups(),
    ]);
    if (!mounted) return;
    setState(() {
      _sessions = results[0] as List<WakeupSession>;
      _totalWakeups = results[1] as int;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: GestureDetector(
                onTap: withHaptic(() => Navigator.pop(context)),
                child: Row(
                  children: [
                    Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                      color: c.textPrimary,
                    ),

                    Expanded(
                      child: Text(
                        l10n.sessionsTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _sessions == null
                  ? const Center(child: CircularProgressIndicator())
                  : _sessions!.isEmpty
                  ? Center(
                      child: Text(
                        l10n.sessionsNoWakeups,
                        style: TextStyle(fontSize: 15, color: c.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: _sessions!.length,
                      separatorBuilder: (context, i) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final session = _sessions![i];
                        final wakeupNumber = _totalWakeups - i;
                        return _SessionTile(
                          session: session,
                          wakeupNumber: wakeupNumber,
                          onTap: () => {},
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final WakeupSession session;
  final int wakeupNumber;
  final VoidCallback onTap;

  const _SessionTile({
    required this.session,
    required this.wakeupNumber,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final ts = session.timestamp;
    final h = ts.hour > 12 ? ts.hour - 12 : (ts.hour == 0 ? 12 : ts.hour);
    final isPM = ts.hour >= 12;
    final timeStr =
        '$h:${ts.minute.toString().padLeft(2, '0')} ${isPM ? 'pm' : 'am'}';
    final dateStr = '${localizedMonth(l10n, ts.month)} ${ts.day}';
    final missionLabel = session.missionType != null
        ? localizedMissionName(l10n, session.missionType!)
        : l10n.wakeupWakeUp;
    final missionIcon = session.missionType != null
        ? missionInfoFor(session.missionType!).icon
        : Icons.wb_sunny;
    final missionColor = session.missionType != null
        ? missionInfoFor(session.missionType!).iconColor
        : AppColors.orange;

    final mins = session.timeTakenSeconds ~/ 60;
    final secs = session.timeTakenSeconds % 60;
    final durationStr = mins > 0 ? '${mins}m ${secs}s' : '${secs}s';

    final missed = !session.completed;
    final iconColor = missed ? c.textSecondary : missionColor;
    final iconBg = missed
        ? c.textSecondary.withAlpha(20)
        : missionColor.withAlpha(25);

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: missed ? 0.6 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  missed ? Icons.alarm_off_outlined : missionIcon,
                  color: iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      missed ? l10n.sessionsMissed : missionLabel,
                      style: TextStyle(fontSize: 13, color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    dateStr,
                    style: TextStyle(fontSize: 13, color: c.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  if (!missed)
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 12, color: c.textSecondary),
                        const SizedBox(width: 3),
                        Text(
                          durationStr,
                          style: TextStyle(fontSize: 12, color: c.textSecondary),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}
