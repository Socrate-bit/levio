import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

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
      await _player.play(AssetSource('sounds/$id.mp3'));
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
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Alarm Sound',
                        style: TextStyle(
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
                  _SectionHeader(title: 'Your Sounds'),
                  Container(
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
                          'Upload Sound',
                          style: TextStyle(
                            fontSize: 15,
                            color: c.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...soundCategories.map((cat) {
                    final catSounds =
                        alarmSounds.where((s) => s.category == cat).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          title: cat,
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
                                        sound.name,
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
                  final sound =
                      alarmSounds.firstWhere((s) => s.id == _selectedId);
                  Navigator.pop(context, {'id': sound.id, 'name': sound.name});
                },
                child: const Text('Select Sound'),
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

class _NewBadge extends StatelessWidget {
  const _NewBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'NEW',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _CreditBadge extends StatelessWidget {
  const _CreditBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('✨', style: TextStyle(fontSize: 12)),
          SizedBox(width: 4),
          Text(
            '1 credit',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
