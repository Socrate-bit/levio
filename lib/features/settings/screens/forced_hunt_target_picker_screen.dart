import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../../missions/widgets/item_picker_screen.dart';

/// Admin/UGC picker: choose a single hunt item that the photo_dismiss roulette
/// will always land on. Pops with the picked label, or an empty string to clear.
/// Pops with `null` when dismissed without selection.
class ForcedHuntTargetPickerScreen extends StatelessWidget {
  final String? currentLabel;

  const ForcedHuntTargetPickerScreen({super.key, this.currentLabel});

  static const _noneSentinel = '';

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);

    final sections = <(String, List<ItemPickerItem>)>[
      (l10n.forcedHuntTargetPickerObjects,
          objectHuntPickerData.sections.expand((s) => s.items).toList()),
      (l10n.forcedHuntTargetPickerPets,
          petHuntPickerData.sections.expand((s) => s.items).toList()),
      (l10n.forcedHuntTargetPickerNature,
          natureHuntPickerData.sections.expand((s) => s.items).toList()),
    ];

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
                      child:
                          Icon(Icons.close, size: 18.sp, color: c.textPrimary),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        l10n.forcedHuntTargetPickerTitle,
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 36.w),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                l10n.forcedHuntTargetPickerSubtitle,
                style: TextStyle(fontSize: 13.sp, color: c.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                children: [
                  // "None (random)" clear option.
                  _PickerTile(
                    emoji: '\u{1f3b2}',
                    label: l10n.forcedHuntTargetPickerNone,
                    selected: currentLabel == null,
                    onTap: () => Navigator.pop(context, _noneSentinel),
                  ),
                  SizedBox(height: 12.h),
                  for (final (name, items) in sections) ...[
                    Padding(
                      padding: EdgeInsets.only(top: 8.h, bottom: 8.h),
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final item = items[i];
                        return _PickerTile(
                          emoji: item.emoji,
                          label: localizedItemName(l10n, item.label),
                          selected: currentLabel == item.label,
                          onTap: () => Navigator.pop(context, item.label),
                        );
                      },
                    ),
                  ],
                  SizedBox(height: 80.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PickerTile({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: withHaptic(onTap),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: selected ? c.purpleDeep : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: TextStyle(fontSize: 36.sp)),
            SizedBox(height: 6.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.w),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: c.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
