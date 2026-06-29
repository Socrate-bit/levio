import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';

import '../services/custom_items_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';

/// Which preset catalog the routine picker offers.
enum RoutineMode { wake, night }

/// Union of every built-in routine label across catalogs — used to tell preset
/// steps apart from user-added custom ones.
final Set<String> _allPresetSteps = {
  ...routinePresetSteps,
  ...routineWakePresetSteps,
  ...routineNightPresetSteps,
};

/// Full-screen chip picker to build a wind-down / wake-up routine. Returns the
/// selected step labels (built-in + custom) as a `List<String>`, or null when
/// cancelled.
///
/// [mode] selects the preset catalog (wake vs night); when null the legacy
/// catalog is used. Set [showModeToggle] (in-app only) to let the user switch
/// between wake and night catalogs from a segmented control.
class RoutinePickerScreen extends StatefulWidget {
  final List<String>? preselected;
  final RoutineMode? mode;
  final bool showModeToggle;

  const RoutinePickerScreen({
    super.key,
    this.preselected,
    this.mode,
    this.showModeToggle = false,
  });

  @override
  State<RoutinePickerScreen> createState() => _RoutinePickerScreenState();
}

class _RoutinePickerScreenState extends State<RoutinePickerScreen> {
  // Ordered list of chosen steps (shown as cards). A step in here is removed
  // from the chip pool; deleting its card returns the chip.
  late List<String> _selected;
  late RoutineMode? _mode;
  List<String> _customSteps = [];
  bool _loading = true;

  /// Preset catalog for the active mode (legacy list when no mode is set).
  List<String> get _presetSteps {
    switch (_mode) {
      case RoutineMode.wake:
        return routineWakePresetSteps;
      case RoutineMode.night:
        return routineNightPresetSteps;
      case null:
        return routinePresetSteps;
    }
  }

  /// All selectable labels (presets + persisted custom steps).
  List<String> get _allLabels => [..._presetSteps, ..._customSteps];

  @override
  void initState() {
    super.initState();
    _mode = widget.mode;
    // Start from the existing config when editing; otherwise nothing is
    // pre-selected — every chip is available to add.
    _selected = widget.preselected?.toList() ?? <String>[];
    _loadCustom();
  }

  Future<void> _loadCustom() async {
    final custom = await CustomItemsService.getCustomRoutineSteps();
    if (!mounted) return;
    // Surface any preselected steps not in any preset catalog or the persisted
    // store (e.g. custom steps from a saved routine).
    final extra = _selected.where(
      (s) => !_allPresetSteps.contains(s) && !custom.contains(s),
    );
    setState(() {
      _customSteps = [...custom, ...extra];
      _loading = false;
    });
  }

  /// Opens a modal with a text field + button to name a new custom step,
  /// instead of editing inline on a chip.
  Future<void> _showAddCustomDialog() async {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final ctrl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          l10n.routineAddStep,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(fontSize: 15.sp, color: c.textPrimary),
          decoration: InputDecoration(
            hintText: l10n.routineAddStep,
            hintStyle: TextStyle(color: c.textSecondary),
            filled: true,
            fillColor: c.background,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.r),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.generalCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              l10n.screenTimeAddSchedule,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (text == null || text.isEmpty) return;

    final isNew =
        !_customSteps.contains(text) && !_allPresetSteps.contains(text);
    setState(() {
      if (isNew) _customSteps.add(text);
      // A new custom step goes straight into the routine as a card.
      if (!_selected.contains(text)) _selected.add(text);
    });
    if (isNew) CustomItemsService.addCustomRoutineStep(text);
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
            // Wake/night catalog switch (in-app editing only).
            if (widget.showModeToggle) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _ModeToggle(
                  mode: _mode ?? RoutineMode.wake,
                  wakeLabel: l10n.routineModeWake,
                  nightLabel: l10n.routineModeNight,
                  onChanged: (m) => setState(() => _mode = m),
                ),
              ),
              SizedBox(height: 16.h),
            ],

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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Chosen steps, in order, as removable cards.
                          // Hold-and-drag to reorder.
                          if (_selected.isNotEmpty)
                            ReorderableListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              buildDefaultDragHandles: false,
                              itemCount: _selected.length,
                              onReorder: (oldIndex, newIndex) {
                                setState(() {
                                  if (newIndex > oldIndex) newIndex -= 1;
                                  final item = _selected.removeAt(oldIndex);
                                  _selected.insert(newIndex, item);
                                });
                              },
                              itemBuilder: (context, i) {
                                final step = _selected[i];
                                return Padding(
                                  key: ValueKey(step),
                                  padding: EdgeInsets.only(bottom: 10.h),
                                  child: ReorderableDelayedDragStartListener(
                                    index: i,
                                    child: _StepCard(
                                      index: i + 1,
                                      label: localizedItemName(l10n, step),
                                      onDelete: () => setState(
                                          () => _selected.remove(step)),
                                    ),
                                  ),
                                );
                              },
                            ),
                          if (_selected.isNotEmpty) SizedBox(height: 6.h),
                          // Remaining chips (selected steps are pulled out) +
                          // the add-custom chip / inline field.
                          Wrap(
                            spacing: 10.w,
                            runSpacing: 10.h,
                            children: [
                              for (final label in _allLabels)
                                if (!_selected.contains(label))
                                  _Chip(
                                    label: localizedItemName(l10n, label),
                                    selected: false,
                                    onTap: () =>
                                        setState(() => _selected.add(label)),
                                  ),
                              _Chip(
                                label: l10n.routineAddStep,
                                selected: false,
                                isAdd: true,
                                onTap: _showAddCustomDialog,
                              ),
                            ],
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

}

/// A selected routine step shown as a card with its order number and a
/// delete action that returns the step to the chip pool.
class _StepCard extends StatelessWidget {
  final int index;
  final String label;
  final VoidCallback onDelete;

  const _StepCard({
    required this.index,
    required this.label,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: c.separator, width: 1.5),
      ),
      child: Row(
        children: [
          // Order badge.
          Container(
            width: 26.w,
            height: 26.w,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.orange,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: c.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: withHaptic(onDelete),
            child: Icon(Icons.close, size: 20.sp, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Segmented wake/night switch shown above the chip pool when editing in-app.
class _ModeToggle extends StatelessWidget {
  final RoutineMode mode;
  final String wakeLabel;
  final String nightLabel;
  final ValueChanged<RoutineMode> onChanged;

  const _ModeToggle({
    required this.mode,
    required this.wakeLabel,
    required this.nightLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    Widget segment(RoutineMode m, String label) {
      final selected = mode == m;
      return Expanded(
        child: GestureDetector(
          onTap: withHaptic(() => onChanged(m)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.symmetric(vertical: 10.h),
            decoration: BoxDecoration(
              color: selected ? c.card : Colors.transparent,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: selected ? c.textPrimary : c.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: c.separator,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          segment(RoutineMode.wake, wakeLabel),
          segment(RoutineMode.night, nightLabel),
        ],
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
