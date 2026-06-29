import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';

/// "Where do you go first?" step. Picking a room maps to a concrete wake-up
/// mission (kitchen → find the fridge, bathroom → find the shower, outside →
/// sky photo). "Other" hands off to the full mission picker via [onPickOther].
class FirstRoomStep extends StatelessWidget {
  final String title;
  final String? subtitle;

  /// One of 'kitchen' | 'bathroom' | 'outside' | 'other' (or null).
  final String? selectedRoom;

  /// Localized name of the mission chosen for the "Other" path, shown as the
  /// card's subtitle when [selectedRoom] is 'other'.
  final String? otherMissionLabel;

  final ValueChanged<String> onRoomSelected;
  final VoidCallback onPickOther;

  final String kitchenLabel;
  final String bathroomLabel;
  final String outsideLabel;
  final String otherLabel;

  const FirstRoomStep({
    super.key,
    required this.title,
    this.subtitle,
    required this.selectedRoom,
    this.otherMissionLabel,
    required this.onRoomSelected,
    required this.onPickOther,
    required this.kitchenLabel,
    required this.bathroomLabel,
    required this.outsideLabel,
    required this.otherLabel,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
              height: 1.2,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle ?? '',
            style: TextStyle(fontSize: 16.sp, color: c.textSecondary),
          ),
          SizedBox(height: 24.h),
          _RoomCard(
            emoji: '🍳',
            label: kitchenLabel,
            selected: selectedRoom == 'kitchen',
            onTap: () => onRoomSelected('kitchen'),
          ),
          _RoomCard(
            emoji: '🚿',
            label: bathroomLabel,
            selected: selectedRoom == 'bathroom',
            onTap: () => onRoomSelected('bathroom'),
          ),
          _RoomCard(
            emoji: '🌤️',
            label: outsideLabel,
            selected: selectedRoom == 'outside',
            onTap: () => onRoomSelected('outside'),
          ),
          _RoomCard(
            emoji: '✨',
            label: otherLabel,
            subtitle: selectedRoom == 'other' ? otherMissionLabel : null,
            selected: selectedRoom == 'other',
            onTap: onPickOther,
          ),
        ],
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _RoomCard({
    required this.emoji,
    required this.label,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: GestureDetector(
        onTap: withHaptic(onTap),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 18.h),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: selected ? c.textPrimary : c.separator,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Text(emoji, style: TextStyle(fontSize: 26.sp)),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: c.textPrimary,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                width: 24.w,
                height: 24.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? c.textPrimary : Colors.transparent,
                  border: Border.all(
                    color: selected ? c.textPrimary : c.textSecondary,
                    width: 2,
                  ),
                ),
                child: selected
                    ? Icon(Icons.check, size: 16.sp, color: c.card)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
