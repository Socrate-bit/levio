import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';

import '../services/custom_items_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../../dismiss/data/affirmations.dart';

/// Result returned by [AffirmationPickerScreen].
class AffirmationPickerResult {
  final List<String> affirmations;
  final int count;

  const AffirmationPickerResult({
    required this.affirmations,
    required this.count,
  });
}

/// Full-screen picker for selecting affirmations and count.
class AffirmationPickerScreen extends StatefulWidget {
  final List<String>? preselected;
  final int initialCount;

  const AffirmationPickerScreen({
    super.key,
    this.preselected,
    this.initialCount = 1,
  });

  @override
  State<AffirmationPickerScreen> createState() =>
      _AffirmationPickerScreenState();
}

class _AffirmationPickerScreenState extends State<AffirmationPickerScreen> {
  late Set<String> _selected;
  late int _count;
  final _customCtrl = TextEditingController();
  List<String> _customAffirmations = [];
  bool _loading = true;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _selected = widget.preselected?.toSet() ?? {};
    _count = widget.initialCount;
    _loadCustom();
  }

  Future<void> _loadCustom() async {
    final custom = await CustomItemsService.getCustomAffirmations();
    if (!mounted) return;
    setState(() {
      _customAffirmations = custom;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _addCustom() {
    final text = _customCtrl.text.trim();
    if (text.isEmpty) return;
    if (_customAffirmations.contains(text) ||
        allBuiltInAffirmations.contains(text)) {
      _customCtrl.clear();
      return;
    }
    setState(() {
      _customAffirmations.add(text);
      _selected.add(text);
    });
    _customCtrl.clear();
    CustomItemsService.addCustomAffirmation(text);

    // Scroll to bottom to reveal the new item
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _deleteCustom(String text) {
    setState(() {
      _customAffirmations.remove(text);
      _selected.remove(text);
    });
    CustomItemsService.removeCustomAffirmation(text);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final allBuiltIn = affirmationsFor(context);
    final allItems = [...allBuiltIn, ..._customAffirmations];

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
                        l10n.affirmationPickerTitle,
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

            // Count + select/deselect
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  Text(
                    l10n.affirmationPickerSelected(_selected.length),
                    style: TextStyle(fontSize: 14.sp, color: c.textSecondary),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: withHaptic(() {
                      setState(() {
                        if (_selected.length < allItems.length) {
                          _selected = allItems.toSet();
                        } else {
                          _selected.clear();
                        }
                      });
                    }),
                    child: Text(
                      _selected.length < allItems.length
                          ? l10n.affirmationPickerSelectAll
                          : l10n.affirmationPickerDeselectAll,
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

            // Affirmation count stepper
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.missionConfigNumberOfAffirmations,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: c.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _count > 1
                          ? withHaptic(() => setState(() => _count--))
                          : null,
                      child: Container(
                        width: 32.w,
                        height: 32.h,
                        decoration: BoxDecoration(
                          color: _count > 1
                              ? c.textPrimary
                              : c.separator,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.remove,
                          size: 18.sp,
                          color: _count > 1
                              ? Colors.white
                              : c.textSecondary,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 40.w,
                      child: Center(
                        child: Text(
                          '$_count',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: c.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _count < 10
                          ? withHaptic(() => setState(() => _count++))
                          : null,
                      child: Container(
                        width: 32.w,
                        height: 32.h,
                        decoration: BoxDecoration(
                          color: _count < 10
                              ? c.textPrimary
                              : c.separator,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add,
                          size: 18.sp,
                          color: _count < 10
                              ? Colors.white
                              : c.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // List
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.orange,
                        strokeWidth: 2.5,
                      ),
                    )
                  : ListView(
                      controller: _scrollCtrl,
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      children: [
                        // Built-in affirmations
                        for (final item in allBuiltIn)
                          Padding(
                            padding: EdgeInsets.only(bottom: 4.h),
                            child: _buildTile(item, c),
                          ),

                        // Custom section (at the bottom, animated)
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          alignment: Alignment.topCenter,
                          child: _customAffirmations.isNotEmpty
                              ? Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 12.h),
                                    Text(
                                      l10n.affirmationPickerCustom,
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w600,
                                        color: c.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    for (final item
                                        in _customAffirmations)
                                      Padding(
                                        padding:
                                            EdgeInsets.only(bottom: 4.h),
                                        child: _buildTile(item, c,
                                            isCustom: true),
                                      ),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),
                        SizedBox(height: 80.h),
                      ],
                    ),
            ),

            // Add your own
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customCtrl,
                      style: TextStyle(fontSize: 15.sp, color: c.textPrimary),
                      decoration: InputDecoration(
                        hintText: l10n.affirmationPickerAddOwn,
                        hintStyle: TextStyle(color: c.textSecondary),
                        filled: true,
                        fillColor: c.card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 12.h),
                      ),
                      onSubmitted: (_) => _addCustom(),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: withHaptic(_addCustom),
                    child: Container(
                      width: 44.w,
                      height: 44.h,
                      decoration: BoxDecoration(
                        color: c.textPrimary,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(Icons.add,
                          color: c.background, size: 22.sp),
                    ),
                  ),
                ],
              ),
            ),

            // Done button
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
              child: ElevatedButton(
                onPressed: withHaptic(() => Navigator.pop(
                    context,
                    AffirmationPickerResult(
                      affirmations: _selected.toList(),
                      count: _count,
                    ))),
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
                  l10n.affirmationPickerDone,
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

  Widget _buildTile(String item, AppColors c,
      {bool isCustom = false}) {
    final selected = _selected.contains(item);
    return GestureDetector(
      onTap: withHaptic(() {
        setState(() {
          if (selected) {
            _selected.remove(item);
          } else {
            _selected.add(item);
          }
        });
      }),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: selected ? c.purpleDeep : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item,
                style: TextStyle(fontSize: 14.sp, color: c.textPrimary),
              ),
            ),
            if (isCustom)
              GestureDetector(
                onTap: withHaptic(() => _deleteCustom(item)),
                child: Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: Icon(Icons.delete_outline,
                      size: 20.sp, color: c.textSecondary),
                ),
              ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? c.purpleDeep : c.textSecondary,
              size: 22.sp,
            ),
          ],
        ),
      ),
    );
  }
}
