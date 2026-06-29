import 'package:flutter/material.dart';

import '../models/mission.dart';

/// Renders a mission's icon — the full-color illustration asset when one is
/// defined, otherwise the Material [IconData] fallback (e.g. the `none`
/// mission). [size] is the rendered width/height (already scaled by callers).
class MissionIcon extends StatelessWidget {
  final MissionInfo info;
  final double size;

  const MissionIcon({super.key, required this.info, required this.size});

  @override
  Widget build(BuildContext context) {
    final asset = info.iconAsset;
    if (asset == null) {
      return Icon(info.icon, color: info.iconColor, size: size);
    }
    return Image.asset(asset, width: size, height: size, fit: BoxFit.contain);
  }
}
