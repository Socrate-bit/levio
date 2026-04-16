import 'package:flutter/material.dart';
import 'package:levio/l10n/generated/app_localizations.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../../dismiss/data/affirmations.dart';

/// Full-screen picker for selecting affirmations.
class AffirmationPickerScreen extends StatefulWidget {
  final List<String>? preselected;

  const AffirmationPickerScreen({super.key, this.preselected});

  @override
  State<AffirmationPickerScreen> createState() =>
      _AffirmationPickerScreenState();
}

class _AffirmationPickerScreenState extends State<AffirmationPickerScreen> {
  late Set<String> _selected;
  final _customCtrl = TextEditingController();

  /// All items: built-in affirmations + any custom ones from preselected.
  late List<String> _allItems;

  @override
  void initState() {
    super.initState();
    _selected = widget.preselected?.toSet() ?? {};
    // Include custom affirmations that aren't in the built-in list
    final custom = _selected.where((s) => !affirmations.contains(s)).toList();
    _allItems = [...affirmations, ...custom];
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  void _addCustom() {
    final text = _customCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      if (!_allItems.contains(text)) _allItems.add(text);
      _selected.add(text);
    });
    _customCtrl.clear();
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
                        if (_selected.length < _allItems.length) {
                          _selected = _allItems.toSet();
                        } else {
                          _selected.clear();
                        }
                      });
                    }),
                    child: Text(
                      _selected.length < _allItems.length
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

            // List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _allItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (_, i) {
                  final item = _allItems[i];
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected
                              ? c.purpleDeep
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item,
                              style: TextStyle(
                                fontSize: 14,
                                color: c.textPrimary,
                              ),
                            ),
                          ),
                          Icon(
                            selected
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: selected
                                ? c.purpleDeep
                                : c.textSecondary,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
}
