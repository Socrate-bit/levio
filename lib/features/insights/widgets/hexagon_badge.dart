import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';

class HexagonBadge extends StatelessWidget {
  final String label;
  final bool earned;
  final double size;
  final Color? earnedColor;
  final VoidCallback? onTap;

  /// Optional PNG art (streak badges). When set, the image replaces the drawn
  /// hexagon and [label]/[earnedColor] are ignored.
  final String? imageAsset;

  const HexagonBadge({
    super.key,
    required this.label,
    this.earned = false,
    this.size = 72,
    this.earnedColor,
    this.onTap,
    this.imageAsset,
  });

  @override
  Widget build(BuildContext context) {
    if (imageAsset != null) {
      return GestureDetector(
        onTap: withHaptic(onTap),
        child: StreakBadgeImage(
          asset: imageAsset!,
          size: size,
          earned: earned,
        ),
      );
    }
    return GestureDetector(
      onTap: withHaptic(onTap),
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _HexPainter(
            earned: earned,
            fillColor: earned
                ? (earnedColor ?? AppColors.orange)
                : const Color(0xFFD1D1D6),
            borderColor: earned
                ? (earnedColor?.withAlpha(180) ?? AppColors.orange.withAlpha(180))
                : Colors.transparent,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: earned ? Colors.white : const Color(0xFFAEAEB2),
                fontSize: size * 0.26,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders a streak-badge PNG, zoom-cropped by 15% (7.5% off each edge) to
/// remove the transparent padding baked into the source art. Unearned badges
/// are desaturated and dimmed to read as "locked".
class StreakBadgeImage extends StatelessWidget {
  final String asset;
  final double size;
  final bool earned;

  /// Fraction of the frame kept after the zoom-crop (0.85 = 15% cropped).
  static const double _keep = 0.85;

  const StreakBadgeImage({
    super.key,
    required this.asset,
    required this.size,
    this.earned = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget image = ClipRect(
      child: Transform.scale(
        scale: 1 / _keep,
        child: Image.asset(asset, fit: BoxFit.contain),
      ),
    );

    if (!earned) {
      // Greyscale (locked) treatment.
      const greyscale = <double>[
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0, 0, 0, 1, 0,
      ];
      image = Opacity(
        opacity: 0.4,
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix(greyscale),
          child: image,
        ),
      );
    }

    return SizedBox(width: size, height: size, child: image);
  }
}

class _HexPainter extends CustomPainter {
  final bool earned;
  final Color fillColor;
  final Color borderColor;

  _HexPainter({
    required this.earned,
    required this.fillColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(cx, cy) - 2;

    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = math.pi / 6 + i * math.pi / 3;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    if (earned) {
      // Outer glow ring
      final outerPath = Path();
      final rOuter = r + 3;
      for (int i = 0; i < 6; i++) {
        final angle = math.pi / 6 + i * math.pi / 3;
        final x = cx + rOuter * math.cos(angle);
        final y = cy + rOuter * math.sin(angle);
        if (i == 0) { outerPath.moveTo(x, y); } else { outerPath.lineTo(x, y); }
      }
      outerPath.close();

      canvas.drawPath(
        outerPath,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_HexPainter old) =>
      old.earned != earned || old.fillColor != fillColor;
}

/// Large version used on badge unlock screen
class LargeHexagonBadge extends StatelessWidget {
  final String label;
  final Color color;
  final double size;

  const LargeHexagonBadge({
    super.key,
    required this.label,
    required this.color,
    this.size = 140,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LargeHexPainter(color: color),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size * 0.28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4.h),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  3,
                  (_) => Padding(
                    padding: EdgeInsets.symmetric(horizontal: 1.w),
                    child: Icon(Icons.star, color: Colors.yellow, size: 14.sp),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LargeHexPainter extends CustomPainter {
  final Color color;
  _LargeHexPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Outer gold ring
    final rOuter = math.min(cx, cy);
    _drawHex(canvas, cx, cy, rOuter, const Color(0xFFFFD700));

    // Inner colored hex
    _drawHex(canvas, cx, cy, rOuter - 6, color);
  }

  void _drawHex(Canvas canvas, double cx, double cy, double r, Color c) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = math.pi / 6 + i * math.pi / 3;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      if (i == 0) { path.moveTo(x, y); } else { path.lineTo(x, y); }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = c..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_LargeHexPainter old) => old.color != color;
}
