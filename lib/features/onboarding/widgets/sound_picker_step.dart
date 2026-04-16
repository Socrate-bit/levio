import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../../alarms/data/sounds.dart';

class SoundPickerStep extends StatefulWidget {
  final String selectedId;
  final void Function(String id, String name) onSelected;

  const SoundPickerStep({
    super.key,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  State<SoundPickerStep> createState() => _SoundPickerStepState();
}

class _SoundPickerStepState extends State<SoundPickerStep> {
  String? _playingId;
  final _player = AudioPlayer();

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _previewSound(String id) async {
    if (_playingId == id) {
      await _player.stop();
      setState(() => _playingId = null);
      return;
    }
    setState(() => _playingId = id);
    try {
      final path = soundAssetPath(id);
      if (path == null) return;
      await _player.play(AssetSource(path));
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Text(
            l10n.onboardingSoundPickerTitle,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: soundCategories.map((cat) {
              final catSounds =
                  alarmSounds.where((s) => s.category == cat).toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(soundCategoryIcons[cat] ?? '',
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Text(
                        localizedSoundCategory(l10n, cat).toUpperCase(),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: c.textSecondary,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...catSounds.map((sound) {
                    final isSelected = widget.selectedId == sound.id;
                    final isPlaying = _playingId == sound.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: withHaptic(() =>
                            widget.onSelected(sound.id, sound.name)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: c.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? c.textPrimary
                                  : c.separator,
                              width: isSelected ? 2 : 1,
                            ),
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
                              Expanded(
                                child: Text(
                                  localizedSoundName(l10n, sound.id),
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: c.textPrimary,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: withHaptic(() => _previewSound(sound.id)),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: isPlaying
                                        ? AppColors.orange
                                        : c.textSecondary,
                                    size: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? c.textPrimary
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? c.textPrimary
                                        : c.textSecondary,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? Icon(Icons.check,
                                        size: 16, color: c.card)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
