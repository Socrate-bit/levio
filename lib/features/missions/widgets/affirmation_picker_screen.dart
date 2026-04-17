import 'package:flutter/material.dart';
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
    if (_customAffirmations.contains(text) || affirmations.contains(text)) {
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
    final allBuiltIn = affirmations;
    final allItems = [...allBuiltIn, ..._customAffirmations];

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
                        l10n.affirmationPickerTitle,
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

            // Count + select/deselect
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    l10n.affirmationPickerSelected(_selected.length),
                    style: TextStyle(fontSize: 14, color: c.textSecondary),
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
                        fontSize: 14,
                        color: c.purpleDeep,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Affirmation count stepper
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.missionConfigNumberOfAffirmations,
                        style: TextStyle(
                          fontSize: 14,
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
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _count > 1
                              ? AppColors.orange
                              : c.separator,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.remove,
                          size: 18,
                          color: _count > 1
                              ? Colors.white
                              : c.textSecondary,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: Center(
                        child: Text(
                          '$_count',
                          style: TextStyle(
                            fontSize: 18,
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
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _count < 10
                              ? AppColors.orange
                              : c.separator,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add,
                          size: 18,
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
            const SizedBox(height: 12),

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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // Built-in affirmations
                        for (final item in allBuiltIn)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
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
                                    const SizedBox(height: 12),
                                    Text(
                                      l10n.affirmationPickerCustom,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: c.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    for (final item
                                        in _customAffirmations)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 4),
                                        child: _buildTile(item, c,
                                            isCustom: true),
                                      ),
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
            ),

            // Add your own
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customCtrl,
                      style: TextStyle(fontSize: 15, color: c.textPrimary),
                      decoration: InputDecoration(
                        hintText: l10n.affirmationPickerAddOwn,
                        hintStyle: TextStyle(color: c.textSecondary),
                        filled: true,
                        fillColor: c.card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
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
            ),

            // Done button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  l10n.affirmationPickerDone,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(12),
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
                style: TextStyle(fontSize: 14, color: c.textPrimary),
              ),
            ),
            if (isCustom)
              GestureDetector(
                onTap: withHaptic(() => _deleteCustom(item)),
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(Icons.delete_outline,
                      size: 20, color: c.textSecondary),
                ),
              ),
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              color: selected ? c.purpleDeep : c.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
