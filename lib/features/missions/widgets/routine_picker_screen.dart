import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';

import '../services/custom_items_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';

/// Full-screen chip picker to build a wind-down / wake-up routine. Returns the
/// selected step labels (built-in + custom) as a `List<String>`, or null when
/// cancelled.
class RoutinePickerScreen extends StatefulWidget {
  final List<String>? preselected;

  const RoutinePickerScreen({super.key, this.preselected});

  @override
  State<RoutinePickerScreen> createState() => _RoutinePickerScreenState();
}

class _RoutinePickerScreenState extends State<RoutinePickerScreen> {
  late Set<String> _selected;
  final _customCtrl = TextEditingController();
  List<String> _customSteps = [];
  bool _adding = false;
  bool _loading = true;

  /// All selectable labels (presets + persisted custom steps).
  List<String> get _allLabels => [...routinePresetSteps, ..._customSteps];

  @override
  void initState() {
    super.initState();
    // Preselect from the existing config; default to all presets on first use.
    _selected = widget.preselected?.toSet() ?? routinePresetSteps.toSet();
    _loadCustom();
  }

  Future<void> _loadCustom() async {
    final custom = await CustomItemsService.getCustomRoutineSteps();
    if (!mounted) return;
    // Surface any preselected custom steps not yet in the persisted store.
    final extra = _selected.where(
      (s) => !routinePresetSteps.contains(s) && !custom.contains(s),
    );
    setState(() {
      _customSteps = [...custom, ...extra];
      _loading = false;
    });
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  void _addCustom() {
    final text = _customCtrl.text.trim();
    if (text.isEmpty) {
      setState(() => _adding = false);
      return;
    }
    if (!_customSteps.contains(text) && !routinePresetSteps.contains(text)) {
      setState(() {
        _customSteps.add(text);
        _selected.add(text);
      });
      CustomItemsService.addCustomRoutineStep(text);
    } else {
      setState(() => _selected.add(text));
    }
    _customCtrl.clear();
    setState(() => _adding = false);
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
                      child:
                          Icon(Icons.close, size: 18.sp, color: c.textPrimary),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        l10n.routinePickerTitle,
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
                l10n.routinePickerSubtitle,
                style: TextStyle(fontSize: 13.sp, color: c.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 16.h),

            // Chips
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.orange,
                        strokeWidth: 2.5,
                      ),
                    )
                  : SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Wrap(
                        spacing: 10.w,
                        runSpacing: 10.h,
                        children: [
                          for (final label in _allLabels)
                            _Chip(
                              label: localizedItemName(l10n, label),
                              selected: _selected.contains(label),
                              onTap: () => setState(() {
                                if (!_selected.remove(label)) {
                                  _selected.add(label);
                                }
                              }),
                            ),
                          // Add-custom chip / inline field
                          _adding
                              ? _addField(c, l10n)
                              : _Chip(
                                  label: l10n.routineAddStep,
                                  selected: false,
                                  isAdd: true,
                                  onTap: () => setState(() => _adding = true),
                                ),
                        ],
                      ),
                    ),
            ),

            // Done button
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
              child: ElevatedButton(
                onPressed: _selected.isEmpty
                    ? null
                    : withHaptic(
                        () => Navigator.pop(context, _selected.toList()),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: c.separator,
                  minimumSize: Size(double.infinity, 54.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  l10n.itemPickerDone,
                  style:
                      TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Inline text field shown in place of the "＋ Add" chip while typing.
  Widget _addField(AppColors c, AppLocalizations l10n) {
    return SizedBox(
      width: 200.w,
      child: TextField(
        controller: _customCtrl,
        autofocus: true,
        style: TextStyle(fontSize: 14.sp, color: c.textPrimary),
        decoration: InputDecoration(
          isDense: true,
          hintText: l10n.routineAddStep,
          hintStyle: TextStyle(color: c.textSecondary),
          filled: true,
          fillColor: c.card,
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.r),
            borderSide: BorderSide.none,
          ),
          suffixIcon: GestureDetector(
            onTap: withHaptic(_addCustom),
            child: Icon(Icons.check, color: AppColors.orange, size: 20.sp),
          ),
        ),
        onSubmitted: (_) => _addCustom(),
        onTapOutside: (_) => _addCustom(),
      ),
    );
  }
}

/// A rounded pill chip used in the routine picker.
class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isAdd;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.isAdd = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: withHaptic(onTap),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: selected ? AppColors.orange : c.card,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: selected ? AppColors.orange : c.separator,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAdd) ...[
              Icon(Icons.add, size: 16.sp, color: c.textSecondary),
              SizedBox(width: 4.w),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: selected
                    ? Colors.white
                    : (isAdd ? c.textSecondary : c.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
