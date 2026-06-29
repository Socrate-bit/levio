import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../models/mission.dart';
import 'mission_icon.dart';

/// Full-screen picker for selecting which missions to include in the random pool.
class RandomPoolPickerScreen extends StatefulWidget {
  final List<MissionType>? preselected;

  const RandomPoolPickerScreen({super.key, this.preselected});

  @override
  State<RandomPoolPickerScreen> createState() =>
      _RandomPoolPickerScreenState();
}

class _RandomPoolPickerScreenState extends State<RandomPoolPickerScreen> {
  late Set<MissionType> _selected;

  /// All selectable mission types (excludes none and random).
  static final _available = allMissions
      .where((m) => m.type != MissionType.random)
      .toList();

  @override
  void initState() {
    super.initState();
    _selected = widget.preselected?.toSet() ?? {};
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
            // Top bar
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
                      child: Icon(Icons.close, size: 18.sp, color: c.textPrimary),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        l10n.randomPoolTitle,
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
                l10n.randomPoolSubtitle,
                style: TextStyle(fontSize: 13.sp, color: c.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 4.h),

            // Count + select/deselect
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  Text(
                    l10n.randomPoolSelected(_selected.length),
                    style: TextStyle(fontSize: 14.sp, color: c.textSecondary),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: withHaptic(() {
                      setState(() {
                        if (_selected.length < _available.length) {
                          _selected =
                              _available.map((m) => m.type).toSet();
                        } else {
                          _selected.clear();
                        }
                      });
                    }),
                    child: Text(
                      _selected.length < _available.length
                          ? l10n.randomPoolSelectAll
                          : l10n.randomPoolDeselectAll,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: c.purpleDeep,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // Grid
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.6,
                ),
                itemCount: _available.length,
                itemBuilder: (_, i) {
                  final info = _available[i];
                  final selected = _selected.contains(info.type);
                  return GestureDetector(
                    onTap: withHaptic(() {
                      setState(() {
                        if (selected) {
                          _selected.remove(info.type);
                        } else {
                          _selected.add(info.type);
                        }
                      });
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: selected
                            ? c.card
                            : c.card.withAlpha(80),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: selected
                              ? c.purpleDeep
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Opacity(
                            opacity: selected ? 1.0 : 0.4,
                            child: MissionIcon(info: info, size: 26.sp),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            localizedMissionName(l10n, info.type),
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? c.textPrimary
                                  : c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Done button
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
              child: ElevatedButton(
                onPressed: withHaptic(() =>
                    Navigator.pop(context, _selected.toList())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.textPrimary,
                  foregroundColor: c.background,
                  minimumSize: Size(double.infinity, 54.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  l10n.randomPoolDone,
                  style: TextStyle(
                      fontSize: 16.sp, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
