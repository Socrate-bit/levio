import 'package:flutter/material.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';

const _iconSize = 40.0;
const _lineWidth = 4.0;
const _nodeSpacing = 48.0;

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
                  color: const Color(0xFF4CAF50),
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

/// Data for a single timeline node
class _NodeData {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String time;
  final String label;

  const _NodeData({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.time,
    required this.label,
  });
}

/// Typical morning — zigzag line with gradient from yellow to red
class _TypicalTimeline extends StatelessWidget {
  final AppColors colors;
  const _TypicalTimeline({required this.colors});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final nodes = [
      _NodeData(
        icon: Icons.notifications_none,
        iconColor: const Color(0xFFFFC107),
        bgColor: const Color(0xFFFFF8E1),
        time: '7:00',
        label: l10n.onboardingTimelineAlarm,
      ),
      _NodeData(
        icon: Icons.snooze,
        iconColor: const Color(0xFFFF9800),
        bgColor: const Color(0xFFFFF3E0),
        time: '7:09',
        label: l10n.onboardingTimelineSnooze,
      ),
      _NodeData(
        icon: Icons.snooze,
        iconColor: const Color(0xFFFF6B6B),
        bgColor: const Color(0xFFFFEBEE),
        time: '7:18',
        label: l10n.onboardingTimelineSnooze,
      ),
      _NodeData(
        icon: Icons.warning_rounded,
        iconColor: const Color(0xFFFF5252),
        bgColor: const Color(0xFFFFEBEE),
        time: '7:27',
        label: l10n.onboardingTimelinePanic,
      ),
    ];

    final totalHeight =
        nodes.length * _iconSize + (nodes.length - 1) * _nodeSpacing;

    return LayoutBuilder(builder: (context, constraints) {
    final lineCenter = constraints.maxWidth / 2;
    final lineOffset = lineCenter - _iconSize / 2 - 20;
    return SizedBox(
      height: totalHeight,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Continuous zigzag line behind icons
          Positioned(
            left: lineOffset + _iconSize / 2 - _lineWidth / 2,
            top: _iconSize / 2,
            bottom: _iconSize / 2,
            width: _lineWidth + 16,
            child: CustomPaint(
              size: Size(_lineWidth + 16, totalHeight - _iconSize),
              painter: _ZigzagLinePainter(
                startColor: const Color(0xFFFFC107),
                endColor: const Color(0xFFFF5252),
              ),
            ),
          ),
          // Nodes on top
          for (var i = 0; i < nodes.length; i++)
            Positioned(
              top: i * (_iconSize + _nodeSpacing),
              left: lineOffset,
              child: _TimelineNodeRow(node: nodes[i]),
            ),
        ],
      ),
    );
    });
  }
}

/// Levio morning — straight line
class _LevioTimeline extends StatelessWidget {
  final AppColors colors;
  const _LevioTimeline({required this.colors});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final nodes = [
      _NodeData(
        icon: Icons.notifications_none,
        iconColor: const Color(0xFF4CAF50),
        bgColor: const Color(0xFFE8F5E9),
        time: '7:00',
        label: l10n.onboardingTimelineAlarm,
      ),
      _NodeData(
        icon: Icons.check_circle,
        iconColor: const Color(0xFF4CAF50),
        bgColor: const Color(0xFFE8F5E9),
        time: '7:01',
        label: l10n.onboardingTimelineMission,
      ),
      _NodeData(
        icon: Icons.wb_sunny,
        iconColor: const Color(0xFF4CAF50),
        bgColor: const Color(0xFFE8F5E9),
        time: '7:02',
        label: l10n.onboardingTimelineStarted,
      ),
    ];

    const levioNodeSpacing = 20.0;
    final nodesHeight =
        nodes.length * _iconSize + (nodes.length - 1) * levioNodeSpacing;
    const badgeGap = 24.0;
    const badgeHeight = 80.0;
    const tailHeight = 30.0;
    final totalHeight = nodesHeight + badgeGap + badgeHeight + 8 + tailHeight;

    return LayoutBuilder(builder: (context, constraints) {
    // Center the drawing: offset so the line sits at horizontal middle
    final lineCenter = constraints.maxWidth / 2;
    final lineOffset = lineCenter - _iconSize / 2 - 20;
    return SizedBox(
      height: totalHeight,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Continuous straight line behind everything
          Positioned(
            left: lineOffset + _iconSize / 2 - _lineWidth / 2,
            top: _iconSize / 2,
            bottom: 0,
            child: Container(width: _lineWidth, color: const Color(0xFF4CAF50)),
          ),
          // Nodes on top — closer together
          for (var i = 0; i < nodes.length; i++)
            Positioned(
              top: i * (_iconSize + levioNodeSpacing),
              left: lineOffset,
              child: _TimelineNodeRow(node: nodes[i]),
            ),
          // "25 MINS GAINED" badge — centered on the vertical line
          Positioned(
            top: nodesHeight + badgeGap,
            left: lineOffset + _iconSize / 2,
            child: FractionalTranslation(
              translation: const Offset(-0.5, 0),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.onboardingTimelineMins,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                    Text(
                      l10n.onboardingTimelineGained,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    });
  }
}

/// A single node row: icon circle + time/label text
class _TimelineNodeRow extends StatelessWidget {
  final _NodeData node;
  const _TimelineNodeRow({required this.node});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: _iconSize,
          height: _iconSize,
          decoration: BoxDecoration(
            color: node.bgColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: Icon(node.icon, size: 20, color: node.iconColor),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              node.time,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              node.label,
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

/// Paints a continuous zigzag line with a color gradient
class _ZigzagLinePainter extends CustomPainter {
  final Color startColor;
  final Color endColor;

  _ZigzagLinePainter({required this.startColor, required this.endColor});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = _lineWidth / 2;
    const amplitude = 8.0;
    const segments = 12;
    final segH = size.height / segments;

    final path = Path();
    path.moveTo(centerX, 0);
    for (var i = 0; i < segments; i++) {
      final y = i * segH;
      final dir = i.isEven ? 1.0 : -1.0;
      path.lineTo(centerX + amplitude * dir, y + segH / 2);
      path.lineTo(centerX, y + segH);
    }

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [startColor, endColor],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = _lineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
