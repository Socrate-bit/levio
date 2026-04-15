import 'package:flutter/material.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';

class TimelineComparison extends StatelessWidget {
  const TimelineComparison({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Typical morning column
        Expanded(
          child: Column(
            children: [
              Text(
                l10n.onboardingTimelineTypical,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: c.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              _TypicalTimeline(colors: c),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Levio morning column
        Expanded(
          child: Column(
            children: [
              Text(
                l10n.onboardingTimelineLevio,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(height: 20),
              _LevioTimeline(colors: c),
            ],
          ),
        ),
      ],
    );
  }
}

class _TypicalTimeline extends StatelessWidget {
  final AppColors colors;
  const _TypicalTimeline({required this.colors});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        _TimelineNode(
          icon: Icons.notifications_none,
          iconColor: const Color(0xFFFFC107),
          bgColor: const Color(0xFFFFF8E1),
          time: '7:00',
          label: l10n.onboardingTimelineAlarm,
          lineColor: const Color(0xFFFFC107),
        ),
        _ZigzagLine(color: const Color(0xFFFFC107)),
        _TimelineNode(
          icon: Icons.snooze,
          iconColor: const Color(0xFFFF9800),
          bgColor: const Color(0xFFFFF3E0),
          time: '7:09',
          label: l10n.onboardingTimelineSnooze,
          lineColor: const Color(0xFFFF6B6B),
        ),
        _ZigzagLine(color: const Color(0xFFFF6B6B)),
        _TimelineNode(
          icon: Icons.snooze,
          iconColor: const Color(0xFFFF6B6B),
          bgColor: const Color(0xFFFFEBEE),
          time: '7:18',
          label: l10n.onboardingTimelineSnooze,
          lineColor: const Color(0xFFFF6B6B),
        ),
        _ZigzagLine(color: const Color(0xFFFF6B6B)),
        _TimelineNode(
          icon: Icons.warning_rounded,
          iconColor: const Color(0xFFFF5252),
          bgColor: const Color(0xFFFFEBEE),
          time: '7:27',
          label: l10n.onboardingTimelinePanic,
        ),
      ],
    );
  }
}

class _LevioTimeline extends StatelessWidget {
  final AppColors colors;
  const _LevioTimeline({required this.colors});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        _TimelineNode(
          icon: Icons.notifications_none,
          iconColor: AppColors.green,
          bgColor: const Color(0xFFE8F5E9),
          time: '7:00',
          label: l10n.onboardingTimelineAlarm,
          lineColor: AppColors.green,
        ),
        _StraightLine(color: AppColors.green),
        _TimelineNode(
          icon: Icons.check_circle,
          iconColor: AppColors.green,
          bgColor: const Color(0xFFE8F5E9),
          time: '7:01',
          label: l10n.onboardingTimelineMission,
          lineColor: AppColors.green,
        ),
        _StraightLine(color: AppColors.green),
        _TimelineNode(
          icon: Icons.wb_sunny,
          iconColor: AppColors.green,
          bgColor: const Color(0xFFE8F5E9),
          time: '7:02',
          label: l10n.onboardingTimelineStarted,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                l10n.onboardingTimelineMins,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.green,
                ),
              ),
              Text(
                l10n.onboardingTimelineGained,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                  color: AppColors.green,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 2,
          height: 30,
          color: AppColors.green,
        ),
      ],
    );
  }
}

class _TimelineNode extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String time;
  final String label;
  final Color? lineColor;

  const _TimelineNode({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.time,
    required this.label,
    this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              time,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ZigzagLine extends StatelessWidget {
  final Color color;
  const _ZigzagLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 17),
      child: SizedBox(
        width: 2,
        height: 32,
        child: CustomPaint(
          painter: _ZigzagPainter(color: color),
        ),
      ),
    );
  }
}

class _ZigzagPainter extends CustomPainter {
  final Color color;
  _ZigzagPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    const segments = 4;
    final segH = size.height / segments;
    const amplitude = 4.0;

    path.moveTo(size.width / 2, 0);
    for (var i = 0; i < segments; i++) {
      final y = i * segH;
      final dir = i.isEven ? 1.0 : -1.0;
      path.lineTo(size.width / 2 + amplitude * dir, y + segH / 2);
      path.lineTo(size.width / 2, y + segH);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StraightLine extends StatelessWidget {
  final Color color;
  const _StraightLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 17),
      child: Container(
        width: 2,
        height: 32,
        color: color,
      ),
    );
  }
}
