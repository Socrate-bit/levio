import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';
import '../../../shared/theme/app_theme.dart';
import '../data/sounds.dart';

class SoundPickerScreen extends StatefulWidget {
  const SoundPickerScreen({super.key});

  @override
  State<SoundPickerScreen> createState() => _SoundPickerScreenState();
}

class _SoundPickerScreenState extends State<SoundPickerScreen> {
  String _selectedId = 'default';
  String? _playingId;
  final _player = AudioPlayer();
  List<CustomSoundItem> _customSounds = [];

  @override
  void initState() {
    super.initState();
    _loadCustomSounds();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _loadCustomSounds() async {
    final sounds = await loadCustomSounds();
    if (mounted) setState(() => _customSounds = sounds);
  }

  /// Pick an audio file, copy it to app storage, and refresh the list.
  Future<void> _uploadSound() async {
    final result = await FilePicker.pickFiles(type: FileType.audio);
    if (result == null || result.files.single.path == null) return;

    final file = result.files.single;
    final item = await addCustomSound(file.path!, file.name);
    if (item == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File too large (max 10 MB)')),
        );
      }
      return;
    }
    await _loadCustomSounds();
    if (mounted) setState(() => _selectedId = item.id);
  }

  /// Delete a custom sound after user confirmation.
  Future<void> _confirmDelete(CustomSoundItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Sound'),
        content: Text('Remove "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await deleteCustomSound(item.id);
    if (_selectedId == item.id) _selectedId = 'default';
    if (_playingId == item.id) {
      await _player.stop();
      _playingId = null;
    }
    await _loadCustomSounds();
  }

  /// Preview a sound — toggle play/stop. Handles both preset and custom sources.
  Future<void> _previewSound(String id) async {
    if (_playingId == id) {
      await _player.stop();
      setState(() => _playingId = null);
      return;
    }
    setState(() => _playingId = id);
    try {
      if (isCustomSound(id)) {
        final item = _customSounds.firstWhere((s) => s.id == id);
        final path = await customSoundFilePath(item.fileName);
        await _player.play(DeviceFileSource(path));
      } else {
        await _player.play(AssetSource('sounds/$id.mp3'));
      }
      _player.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _playingId = null);
      });
    } catch (_) {
      if (mounted) setState(() => _playingId = null);
    }
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: c.card,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close,
                          size: 18, color: c.textPrimary),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        l10n.soundPickerTitle,
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
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  const SizedBox(height: 20),
                  // Your Sounds section
                  _SectionHeader(title: l10n.soundPickerYourSounds),
                  GestureDetector(
                    onTap: _uploadSound,
                    child: Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.add,
                              size: 18, color: c.textSecondary),
                          const SizedBox(width: 12),
                          Text(
                            l10n.soundPickerUpload,
                            style: TextStyle(
                              fontSize: 15,
                              color: c.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Custom sound rows
                  if (_customSounds.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: _customSounds.asMap().entries.map((entry) {
                          final i = entry.key;
                          final sound = entry.value;
                          final isFirst = i == 0;
                          final isLast = i == _customSounds.length - 1;
                          final isSelected = _selectedId == sound.id;
                          final isPlaying = _playingId == sound.id;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedId = sound.id),
                            onLongPress: () => _confirmDelete(sound),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  topLeft: isFirst
                                      ? const Radius.circular(14)
                                      : Radius.zero,
                                  topRight: isFirst
                                      ? const Radius.circular(14)
                                      : Radius.zero,
                                  bottomLeft: isLast
                                      ? const Radius.circular(14)
                                      : Radius.zero,
                                  bottomRight: isLast
                                      ? const Radius.circular(14)
                                      : Radius.zero,
                                ),
                                border: isSelected
                                    ? Border.all(
                                        color: AppColors.green,
                                        width: 2,
                                      )
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppColors.green.withValues(alpha: 0.3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.music_note,
                                        size: 18, color: AppColors.green),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      sound.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: c.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => _previewSound(sound.id),
                                    child: Icon(
                                      isPlaying
                                          ? Icons.equalizer
                                          : Icons.play_circle_outline,
                                      color: isPlaying
                                          ? AppColors.orange
                                          : c.textSecondary,
                                      size: 22,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ...soundCategories.map((cat) {
                    final catSounds =
                        alarmSounds.where((s) => s.category == cat).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          title: localizedSoundCategory(l10n, cat),
                          icon: soundCategoryIcons[cat],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: c.card,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children:
                                catSounds.asMap().entries.map((entry) {
                              final i = entry.key;
                              final sound = entry.value;
                              final isFirst = i == 0;
                              final isLast = i == catSounds.length - 1;
                              final isSelected =
                                  _selectedId == sound.id;
                              final isPlaying = _playingId == sound.id;
                              return GestureDetector(
                                onTap: () => setState(
                                    () => _selectedId = sound.id),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                      topLeft: isFirst
                                          ? const Radius.circular(14)
                                          : Radius.zero,
                                      topRight: isFirst
                                          ? const Radius.circular(14)
                                          : Radius.zero,
                                      bottomLeft: isLast
                                          ? const Radius.circular(14)
                                          : Radius.zero,
                                      bottomRight: isLast
                                          ? const Radius.circular(14)
                                          : Radius.zero,
                                    ),
                                    border: isSelected
                                        ? Border.all(
                                            color: AppColors.green,
                                            width: 2,
                                          )
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: sound.color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Text(
                                        localizedSoundName(l10n, sound.id),
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: c.textPrimary,
                                        ),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: () => _previewSound(sound.id),
                                        child: Icon(
                                          isPlaying
                                              ? Icons.equalizer
                                              : Icons.play_circle_outline,
                                          color: isPlaying
                                              ? AppColors.orange
                                              : c.textSecondary,
                                          size: 22,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ElevatedButton(
                onPressed: () {
                  // Handle both preset and custom sounds
                  if (isCustomSound(_selectedId)) {
                    final sound =
                        _customSounds.firstWhere((s) => s.id == _selectedId);
                    Navigator.pop(
                        context, {'id': sound.id, 'name': sound.name});
                  } else {
                    final sound =
                        alarmSounds.firstWhere((s) => s.id == _selectedId);
                    Navigator.pop(
                        context, {'id': sound.id, 'name': sound.name});
                  }
                },
                child: Text(l10n.soundPickerSelect),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? icon;

  const _SectionHeader({required this.title, this.icon});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        if (icon != null) ...[
          Text(icon!, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
        ],
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: c.textPrimary,
          ),
        ),
      ],
    );
  }
}
