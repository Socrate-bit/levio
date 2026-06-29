import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';

import '../services/custom_items_service.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';

/// Data for the item picker grid.
class ItemPickerData {
  final String title;
  final String subtitle;
  final List<ItemPickerSection> sections;

  const ItemPickerData({
    required this.title,
    required this.subtitle,
    required this.sections,
  });
}

class ItemPickerSection {
  final String name;
  final List<ItemPickerItem> items;

  const ItemPickerSection({required this.name, required this.items});
}

class ItemPickerItem {
  final String label;
  final String emoji;

  const ItemPickerItem(this.label, this.emoji);
}

// ── Object Hunt items ──
final objectHuntPickerData = ItemPickerData(
  title: 'Select Items',
  subtitle: 'A random item will be chosen each morning',
  sections: [
    ItemPickerSection(name: 'Household Items', items: [
      ItemPickerItem('Toothbrush', '\u{1faa5}'),
      ItemPickerItem('Running Faucet', '\u{1f6b0}'),
      ItemPickerItem('Shoes', '\u{1f45f}'),
      ItemPickerItem('Fridge', '\u{1f9ca}'),
      ItemPickerItem('Keys', '\u{1f511}'),
      ItemPickerItem('Coffee Mug', '\u{2615}'),
      ItemPickerItem('Mirror', '\u{1fa9e}'),
      ItemPickerItem('Water Bottle', '\u{1f4a7}'),
      ItemPickerItem('Dustpan', '\u{1f9f9}'),
      ItemPickerItem('Toilet', '\u{1f6bd}'),
      ItemPickerItem('Book', '\u{1f4d5}'),
      ItemPickerItem('Lamp', '\u{1f4a1}'),
      ItemPickerItem('TV Remote', '\u{1f4fa}'),
      ItemPickerItem('Front Door', '\u{1f6aa}'),
      ItemPickerItem('Stove', '\u{1f373}'),
      ItemPickerItem('Lotion Bottle', '\u{1f9f4}'),
      ItemPickerItem('Soap', '\u{1f9fc}'),
      ItemPickerItem('Plant', '\u{1fab4}'),
      ItemPickerItem('Plate', '\u{1f37d}\u{fe0f}'),
      ItemPickerItem('Towel', '\u{1f6c1}'),
      ItemPickerItem('Backpack', '\u{1f392}'),
      ItemPickerItem('Headphones', '\u{1f3a7}'),
      ItemPickerItem('Shower', '\u{1f6bf}'),
    ]),
  ],
);

// ── Pet Hunt items ──
final petHuntPickerData = ItemPickerData(
  title: 'Select Your Pets',
  subtitle: 'Select which pets you have at home',
  sections: [
    ItemPickerSection(name: '', items: [
      ItemPickerItem('Dog', '\u{1f436}'),
      ItemPickerItem('Cat', '\u{1f431}'),
      ItemPickerItem('Bird', '\u{1f426}'),
      ItemPickerItem('Fish', '\u{1f41f}'),
      ItemPickerItem('Hamster', '\u{1f439}'),
      ItemPickerItem('Rabbit', '\u{1f430}'),
      ItemPickerItem('Turtle', '\u{1f422}'),
      ItemPickerItem('Guinea Pig', '\u{1f439}'),
      ItemPickerItem('Lizard', '\u{1f98e}'),
      ItemPickerItem('Snake', '\u{1f40d}'),
    ]),
  ],
);

// ── Nature Hunt items ──
final natureHuntPickerData = ItemPickerData(
  title: 'Select Nature Items',
  subtitle: 'A random nature item will be chosen each morning',
  sections: [
    ItemPickerSection(name: '', items: [
      ItemPickerItem('Tree', '\u{1f333}'),
      ItemPickerItem('Flower', '\u{1f33a}'),
      ItemPickerItem('Rock', '\u{1faa8}'),
      ItemPickerItem('Leaf', '\u{1f343}'),
      ItemPickerItem('Grass', '\u{1f33f}'),
      ItemPickerItem('Bush', '\u{1f338}'),
      ItemPickerItem('Stick', '\u{1fab5}'),
      ItemPickerItem('Pinecone', '\u{1f332}'),
    ]),
  ],
);

/// Returns the localized section name for item picker sections.
String _localizedSectionName(AppLocalizations l10n, String name) {
  switch (name) {
    case 'Household Items':
      return l10n.itemPickerHouseholdItems;
    case 'Custom Items':
      return l10n.itemPickerCustomItems;
    default:
      return name;
  }
}

/// Full-screen multi-select picker with emoji grid.
class ItemPickerScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<ItemPickerSection> sections;
  final List<String>? preselected;
  final bool showAddCustom;

  const ItemPickerScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.sections,
    this.preselected,
    this.showAddCustom = false,
  });

  @override
  State<ItemPickerScreen> createState() => _ItemPickerScreenState();
}

class _ItemPickerScreenState extends State<ItemPickerScreen> {
  late Set<String> _selected;
  final _scrollCtrl = ScrollController();
  List<String> _customObjects = [];
  // Parallel map of custom-object name -> chosen emoji (display only).
  Map<String, String> _customEmojis = {};
  bool _loading = true;

  /// All built-in items across sections.
  Set<String> get _builtInLabels =>
      widget.sections.expand((s) => s.items).map((i) => i.label).toSet();

  /// All selectable labels (built-in + custom).
  List<String> get _allLabels => [
        ..._builtInLabels,
        ..._customObjects,
      ];

  @override
  void initState() {
    super.initState();
    _selected = widget.preselected?.toSet() ?? {};
    if (widget.showAddCustom) {
      _loadCustom();
    } else {
      _loading = false;
    }
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

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _toggleAll(bool selectAll) {
    setState(() {
      if (selectAll) {
        _selected = _allLabels.toSet();
      } else {
        _selected.clear();
      }
    });
  }

  /// Opens the modal to create a custom object (name + emoji), then persists
  /// and selects it. Duplicates (custom or built-in) are silently ignored.
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
      _selected.add(name);
    });
    CustomItemsService.addCustomObject(name, emoji: result.emoji);

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

  void _deleteCustom(String label) {
    setState(() {
      _customObjects.remove(label);
      _customEmojis.remove(label);
      _selected.remove(label);
    });
    CustomItemsService.removeCustomObject(label);
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
                        widget.title,
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

            // Selected count + Select/Deselect All
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                children: [
                  Text(
                    l10n.itemPickerSelected(_selected.length),
                    style: TextStyle(fontSize: 14.sp, color: c.textSecondary),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: withHaptic(() => _toggleAll(
                        _selected.length < _allLabels.length)),
                    child: Text(
                      _selected.length < _allLabels.length
                          ? l10n.itemPickerSelectAll
                          : l10n.itemPickerDeselectAll,
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
            SizedBox(height: 4.h),

            // Subtitle
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Text(
                widget.subtitle,
                style: TextStyle(fontSize: 13.sp, color: c.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 12.h),

            // Grid
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
                        // Built-in sections
                        for (final section in widget.sections) ...[
                          if (section.name.isNotEmpty) ...[
                            SizedBox(height: 8.h),
                            Text(
                              _localizedSectionName(l10n, section.name),
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: c.textPrimary,
                              ),
                            ),
                            SizedBox(height: 8.h),
                          ],
                          _buildGrid(section.items, c, l10n),
                          SizedBox(height: 8.h),
                        ],

                        // Custom objects section (at the bottom)
                        if (widget.showAddCustom) ...[
                          // Section header + grid (animated)
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            alignment: Alignment.topCenter,
                            child: _customObjects.isNotEmpty
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(height: 8.h),
                                      Text(
                                        _localizedSectionName(
                                            l10n, 'Custom Items'),
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                          color: c.textPrimary,
                                        ),
                                      ),
                                      SizedBox(height: 8.h),
                                      _buildCustomGrid(c, l10n),
                                      SizedBox(height: 8.h),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          ),

                          // Add your own — opens a modal (name + emoji)
                          SizedBox(height: 8.h),
                          GestureDetector(
                            onTap: withHaptic(_openAddCustomModal),
                            child: Container(
                              height: 48.h,
                              decoration: BoxDecoration(
                                color: c.card,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: AppColors.orange.withAlpha(120),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add,
                                      color: AppColors.orange, size: 20.sp),
                                  SizedBox(width: 8.w),
                                  Text(
                                    l10n.itemPickerAddCustom,
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      color: AppColors.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        SizedBox(height: 80.h),
                      ],
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
                  l10n.itemPickerDone,
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

  /// Grid for custom objects — each card has a delete icon.
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
        final selected = _selected.contains(label);
        return GestureDetector(
          onTap: withHaptic(() {
            setState(() {
              if (selected) {
                _selected.remove(label);
              } else {
                _selected.add(label);
              }
            });
          }),
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
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_customEmojis[label] ?? '\u{2b50}',
                            style: TextStyle(fontSize: 36.sp)),
                        SizedBox(height: 6.h),
                        Text(
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
                      ],
                    ),
                  ),
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
                      child: Icon(Icons.close,
                          size: 14.sp, color: c.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Grid for built-in items.
  Widget _buildGrid(
      List<ItemPickerItem> items, AppColors c, AppLocalizations l10n) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.9,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final selected = _selected.contains(item.label);
        return GestureDetector(
          onTap: withHaptic(() {
            setState(() {
              if (selected) {
                _selected.remove(item.label);
              } else {
                _selected.add(item.label);
              }
            });
          }),
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
                Text(
                  item.emoji,
                  style: TextStyle(fontSize: 36.sp),
                ),
                SizedBox(height: 6.h),
                Text(
                  localizedItemName(l10n, item.label),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: c.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Bottom-sheet for creating a custom object — a name field plus an emoji
/// picker. Pops `(name, emoji)` once both are provided; the emoji picker
/// guarantees the emoji is a real emoji glyph.
class AddCustomObjectSheet extends StatefulWidget {
  const AddCustomObjectSheet({super.key});

  @override
  State<AddCustomObjectSheet> createState() => _AddCustomObjectSheetState();
}

class _AddCustomObjectSheetState extends State<AddCustomObjectSheet> {
  final _nameCtrl = TextEditingController();
  String? _emoji;
  bool _showEmoji = false;

  @override
  void initState() {
    super.initState();
    // Re-evaluate the Add button enabled state as the name is typed.
    _nameCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _canAdd => _nameCtrl.text.trim().isNotEmpty && _emoji != null;

  void _toggleEmoji() {
    FocusScope.of(context).unfocus();
    setState(() => _showEmoji = !_showEmoji);
  }

  void _submit() {
    if (!_canAdd) return;
    Navigator.pop(context, (name: _nameCtrl.text.trim(), emoji: _emoji!));
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grab handle
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: c.separator,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              l10n.itemPickerNewItemTitle,
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w600,
                color: c.textPrimary,
              ),
            ),
            SizedBox(height: 16.h),

            // Emoji tile + name field
            Row(
              children: [
                GestureDetector(
                  onTap: withHaptic(_toggleEmoji),
                  child: Container(
                    width: 56.w,
                    height: 56.h,
                    decoration: BoxDecoration(
                      color: c.background,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: _showEmoji ? AppColors.orange : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: _emoji != null
                        ? Text(_emoji!, style: TextStyle(fontSize: 30.sp))
                        : Icon(Icons.emoji_emotions_outlined,
                            color: c.textSecondary, size: 26.sp),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    onTap: () {
                      if (_showEmoji) setState(() => _showEmoji = false);
                    },
                    style: TextStyle(fontSize: 15.sp, color: c.textPrimary),
                    decoration: InputDecoration(
                      hintText: l10n.itemPickerNameHint,
                      hintStyle: TextStyle(color: c.textSecondary),
                      filled: true,
                      fillColor: c.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
              ],
            ),

            // "Choose an emoji" hint when none chosen yet
            if (_emoji == null) ...[
              SizedBox(height: 8.h),
              GestureDetector(
                onTap: withHaptic(_toggleEmoji),
                child: Text(
                  l10n.itemPickerChooseEmoji,
                  style: TextStyle(fontSize: 13.sp, color: AppColors.orange),
                ),
              ),
            ],

            // Emoji picker (toggled)
            if (_showEmoji) ...[
              SizedBox(height: 12.h),
              SizedBox(
                height: 256.h,
                child: EmojiPicker(
                  onEmojiSelected: (category, emoji) {
                    setState(() {
                      _emoji = emoji.emoji;
                      _showEmoji = false;
                    });
                  },
                  config: Config(
                    height: 256.h,
                    emojiViewConfig: EmojiViewConfig(
                      backgroundColor: c.card,
                      emojiSizeMax: 28 *
                          (foundation.defaultTargetPlatform ==
                                  TargetPlatform.iOS
                              ? 1.2
                              : 1.0),
                    ),
                    categoryViewConfig: CategoryViewConfig(
                      backgroundColor: c.card,
                      iconColor: c.textSecondary,
                      iconColorSelected: AppColors.orange,
                      indicatorColor: AppColors.orange,
                      backspaceColor: AppColors.orange,
                    ),
                    bottomActionBarConfig:
                        const BottomActionBarConfig(enabled: false),
                    searchViewConfig: SearchViewConfig(
                      backgroundColor: c.card,
                      buttonIconColor: c.textSecondary,
                    ),
                  ),
                ),
              ),
            ],

            SizedBox(height: 16.h),

            // Add button
            ElevatedButton(
              onPressed: _canAdd ? withHaptic(_submit) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.orange.withAlpha(80),
                disabledForegroundColor: Colors.white70,
                minimumSize: Size(double.infinity, 54.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                elevation: 0,
              ),
              child: Text(
                l10n.itemPickerAdd,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Returns the emoji associated with [label] across hunt picker data,
/// or null when the label is custom / unknown.
String? emojiForItemLabel(String label) {
  for (final data in [
    objectHuntPickerData,
    petHuntPickerData,
    natureHuntPickerData,
  ]) {
    for (final section in data.sections) {
      for (final item in section.items) {
        if (item.label == label) return item.emoji;
      }
    }
  }
  return null;
}
