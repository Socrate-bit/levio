import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../../missions/services/custom_items_service.dart';
import '../../missions/widgets/item_picker_screen.dart';

/// Admin/UGC picker: choose a single hunt item that the photo_dismiss roulette
/// will always land on. Pops with the picked label, or an empty string to clear.
/// Pops with `null` when dismissed without selection.
///
/// In addition to the built-in catalog, this surfaces the user's custom objects
/// (from `meta/custom`) and lets an admin create new ones inline.
class ForcedHuntTargetPickerScreen extends StatefulWidget {
  final String? currentLabel;

  const ForcedHuntTargetPickerScreen({super.key, this.currentLabel});

  @override
  State<ForcedHuntTargetPickerScreen> createState() =>
      _ForcedHuntTargetPickerScreenState();
}

class _ForcedHuntTargetPickerScreenState
    extends State<ForcedHuntTargetPickerScreen> {
  static const _noneSentinel = '';

  List<String> _customObjects = [];
  // Parallel map of custom-object name -> chosen emoji (display only).
  Map<String, String> _customEmojis = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCustom();
  }

  Future<void> _loadCustom() async {
    final custom = await CustomItemsService.getCustomObjects();
    final emojis = await CustomItemsService.getCustomObjectEmojis();
    if (!mounted) return;
    setState(() {
      _customObjects = custom;
      _customEmojis = emojis;
      _loading = false;
    });
  }

  /// All built-in labels across the three hunt catalogs — used to dedupe a new
  /// custom object against the catalog.
  Set<String> get _builtInLabels => [
        objectHuntPickerData,
        petHuntPickerData,
        natureHuntPickerData,
      ].expand((d) => d.sections).expand((s) => s.items).map((i) => i.label).toSet();

  /// Opens the creation modal, persists, and appends to the grid. Does not pop —
  /// the admin taps the new tile to set it as the forced target.
  Future<void> _openAddCustomModal() async {
    final result = await showModalBottomSheet<({String name, String emoji})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddCustomObjectSheet(),
    );
    if (result == null || !mounted) return;

    final name = result.name.trim();
    if (name.isEmpty) return;
    if (_customObjects.contains(name) || _builtInLabels.contains(name)) return;

    setState(() {
      _customObjects.add(name);
      _customEmojis[name] = result.emoji;
    });
    CustomItemsService.addCustomObject(name, emoji: result.emoji);
  }

  void _deleteCustom(String label) {
    setState(() {
      _customObjects.remove(label);
      _customEmojis.remove(label);
    });
    CustomItemsService.removeCustomObject(label);
  }

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
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.orange,
                        strokeWidth: 2.5,
                      ),
                    )
                  : ListView(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      children: [
                        // "None (random)" clear option.
                        _PickerTile(
                          emoji: '\u{1f3b2}',
                          label: l10n.forcedHuntTargetPickerNone,
                          selected: widget.currentLabel == null,
                          onTap: () => Navigator.pop(context, _noneSentinel),
                        ),
                        SizedBox(height: 12.h),
                        for (final (name, items) in sections) ...[
                          _SectionHeader(name: name),
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
                                selected: widget.currentLabel == item.label,
                                onTap: () =>
                                    Navigator.pop(context, item.label),
                              );
                            },
                          ),
                        ],
                        // Custom objects section.
                        if (_customObjects.isNotEmpty) ...[
                          _SectionHeader(name: l10n.itemPickerCustomItems),
                          _buildCustomGrid(c, l10n),
                        ],
                        SizedBox(height: 16.h),
                        // Add your own — opens the create modal.
                        GestureDetector(
                          onTap: withHaptic(_openAddCustomModal),
                          child: Container(
                            height: 48.h,
                            decoration: BoxDecoration(
                              color: c.card,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: c.textPrimary.withAlpha(120),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add,
                                    color: c.textPrimary, size: 20.sp),
                                SizedBox(width: 8.w),
                                Text(
                                  l10n.itemPickerAddCustom,
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    color: c.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 80.h),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Grid of custom objects — each selectable tile has a delete (X) badge.
  Widget _buildCustomGrid(AppColors c, AppLocalizations l10n) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.9,
      ),
      itemCount: _customObjects.length,
      itemBuilder: (_, i) {
        final label = _customObjects[i];
        return Stack(
          // Expand so the tile fills the grid cell instead of shrinking to its
          // content (default StackFit.loose would let the Column size to min).
          fit: StackFit.expand,
          children: [
            _PickerTile(
              emoji: _customEmojis[label] ?? '\u{2b50}',
              label: label,
              selected: widget.currentLabel == label,
              onTap: () => Navigator.pop(context, label),
            ),
            // Delete button
            Positioned(
              top: 4.h,
              right: 4.w,
              child: GestureDetector(
                onTap: withHaptic(() => _deleteCustom(label)),
                child: Container(
                  width: 22.w,
                  height: 22.h,
                  decoration: BoxDecoration(
                    color: c.separator,
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(Icons.close, size: 14.sp, color: c.textSecondary),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String name;
  const _SectionHeader({required this.name});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: EdgeInsets.only(top: 8.h, bottom: 8.h),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: c.textPrimary,
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
