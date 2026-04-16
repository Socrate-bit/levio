import 'package:flutter/material.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';

import '../../../services/custom_items_service.dart';
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
      ItemPickerItem('Tape', '\u{1f4ce}'),
    ]),
    ItemPickerSection(name: 'Fun Items', items: [
      ItemPickerItem('Kim Kardashian', '\u{1f469}'),
      ItemPickerItem('Snoop Dogg', '\u{1f468}'),
      ItemPickerItem('Rubber Duck', '\u{1f986}'),
      ItemPickerItem('Banana', '\u{1f34c}'),
      ItemPickerItem('Pickle', '\u{1f952}'),
      ItemPickerItem('Croc', '\u{1f40a}'),
      ItemPickerItem('Lava Lamp', '\u{1f52e}'),
      ItemPickerItem('Ping Pong Paddle', '\u{1f3d3}'),
      ItemPickerItem('Egg', '\u{1f95a}'),
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
    case 'Fun Items':
      return l10n.itemPickerFunItems;
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
  final _customCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<String> _customObjects = [];
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
    if (!mounted) return;
    setState(() {
      _customObjects = custom;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _customCtrl.dispose();
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

  void _addCustom() {
    final text = _customCtrl.text.trim();
    if (text.isEmpty) return;
    if (_customObjects.contains(text) || _builtInLabels.contains(text)) {
      _customCtrl.clear();
      return;
    }
    setState(() {
      _customObjects.add(text);
      _selected.add(text);
    });
    _customCtrl.clear();
    CustomItemsService.addCustomObject(text);

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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: withHaptic(() => Navigator.pop(context)),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c.card,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, size: 18, color: c.textPrimary),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Selected count + Select/Deselect All
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    l10n.itemPickerSelected(_selected.length),
                    style: TextStyle(fontSize: 14, color: c.textSecondary),
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
                        fontSize: 14,
                        color: c.purpleDeep,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.subtitle,
                style: TextStyle(fontSize: 13, color: c.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),

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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // Built-in sections
                        for (final section in widget.sections) ...[
                          if (section.name.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              _localizedSectionName(l10n, section.name),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: c.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          _buildGrid(section.items, c, l10n),
                          const SizedBox(height: 8),
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
                                      const SizedBox(height: 8),
                                      Text(
                                        _localizedSectionName(
                                            l10n, 'Custom Items'),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: c.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildCustomGrid(c, l10n),
                                      const SizedBox(height: 8),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          ),

                          // Add your own
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _customCtrl,
                                  style: TextStyle(
                                      fontSize: 15, color: c.textPrimary),
                                  decoration: InputDecoration(
                                    hintText: l10n.itemPickerAddOwn,
                                    hintStyle:
                                        TextStyle(color: c.textSecondary),
                                    filled: true,
                                    fillColor: c.card,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                  ),
                                  onSubmitted: (_) => _addCustom(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: withHaptic(_addCustom),
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: AppColors.orange,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.add,
                                      color: Colors.white, size: 22),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 80),
                      ],
                    ),
            ),

            // Done button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: ElevatedButton(
                onPressed: withHaptic(() =>
                    Navigator.pop(context, _selected.toList())),
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.textPrimary,
                  foregroundColor: c.background,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  l10n.itemPickerDone,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
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
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? c.purpleDeep : Colors.transparent,
                width: 2,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('\u{2b50}',
                            style: TextStyle(fontSize: 36)),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
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
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: withHaptic(() => _deleteCustom(label)),
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: c.separator,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close,
                          size: 14, color: c.textSecondary),
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
              borderRadius: BorderRadius.circular(14),
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
                  style: const TextStyle(fontSize: 36),
                ),
                const SizedBox(height: 6),
                Text(
                  localizedItemName(l10n, item.label),
                  style: TextStyle(
                    fontSize: 12,
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
