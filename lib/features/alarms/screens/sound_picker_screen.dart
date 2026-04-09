import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

class AlarmSoundItem {
  final String id;
  final String name;
  final Color color;
  final String category;

  const AlarmSoundItem({
    required this.id,
    required this.name,
    required this.color,
    required this.category,
  });
}

const _sounds = [
  // Classic
  AlarmSoundItem(
      id: 'default',
      name: 'Default',
      color: Color(0xFF8E8E93),
      category: 'Classic'),
  AlarmSoundItem(
      id: 'alarm_clock',
      name: 'Alarm Clock',
      color: Color(0xFF4A5568),
      category: 'Classic'),
  AlarmSoundItem(
      id: 'reveille',
      name: 'Reveille',
      color: Color(0xFF2D6A4F),
      category: 'Classic'),
  AlarmSoundItem(
      id: 'sparkles',
      name: 'Sparkles',
      color: Color(0xFFCC79B8),
      category: 'Classic'),
  // Viral
  AlarmSoundItem(
      id: 'mindful_earth',
      name: 'Mindful Earth',
      color: Color(0xFF1FAB89),
      category: 'Viral'),
  AlarmSoundItem(
      id: 'epic_brass',
      name: 'Epic Brass',
      color: Color(0xFFE8B400),
      category: 'Viral'),
  AlarmSoundItem(
      id: 'neon',
      name: 'Neon',
      color: Color(0xFF5DADE2),
      category: 'Viral'),
  AlarmSoundItem(
      id: 'rise_and_shine',
      name: 'Rise And Shine',
      color: Color(0xFFFF8C42),
      category: 'Viral'),
  // Aggressive
  AlarmSoundItem(
      id: 'air_raid',
      name: 'Air Raid',
      color: Color(0xFFE53E3E),
      category: 'Aggressive'),
  AlarmSoundItem(
      id: 'meltdown',
      name: 'Meltdown',
      color: Color(0xFFC53030),
      category: 'Aggressive'),
  AlarmSoundItem(
      id: 'rave',
      name: 'Rave',
      color: Color(0xFFB83280),
      category: 'Aggressive'),
  AlarmSoundItem(
      id: 'pop_star',
      name: 'Pop Star',
      color: Color(0xFF00B5D8),
      category: 'Aggressive'),
  AlarmSoundItem(
      id: 'party_time',
      name: 'Party Time',
      color: Color(0xFFED64A6),
      category: 'Aggressive'),
  // Peaceful
  AlarmSoundItem(
      id: 'sunray',
      name: 'Sunray',
      color: Color(0xFFE8B400),
      category: 'Peaceful'),
  AlarmSoundItem(
      id: 'jolly_day',
      name: 'Jolly Day',
      color: Color(0xFFED8936),
      category: 'Peaceful'),
  AlarmSoundItem(
      id: 'london_town',
      name: 'London Town',
      color: Color(0xFF667EEA),
      category: 'Peaceful'),
  AlarmSoundItem(
      id: 'first_snow',
      name: 'First Snow',
      color: Color(0xFF76E4F7),
      category: 'Peaceful'),
];

const _categories = ['Classic', 'Viral', 'Aggressive', 'Peaceful'];
const _categoryIcons = {
  'Classic': '🔔',
  'Viral': '🔥',
  'Aggressive': '⚡',
  'Peaceful': '🌿',
};

class SoundPickerScreen extends StatefulWidget {
  const SoundPickerScreen({super.key});

  @override
  State<SoundPickerScreen> createState() => _SoundPickerScreenState();
}

class _SoundPickerScreenState extends State<SoundPickerScreen> {
  String _selectedId = 'default';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                      decoration: const BoxDecoration(
                        color: AppColors.card,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 18, color: AppColors.textPrimary),
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
                  // AI promo banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE85D04), Color(0xFF9B2226)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _NewBadge(),
                                ],
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Create Your Alarm Sound',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'AI-generated jingles, made for you',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              SizedBox(height: 8),
                              _CreditBadge(),
                            ],
                          ),
                        ),
                        Icon(Icons.auto_awesome,
                            color: Colors.white70, size: 32),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Your Sounds section
                  const _SectionHeader(title: 'Your Sounds'),
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.add,
                            size: 18, color: AppColors.textSecondary),
                        SizedBox(width: 12),
                        Text(
                          'Upload Sound',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._categories.map((cat) {
                    final catSounds =
                        _sounds.where((s) => s.category == cat).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          title: cat,
                          icon: _categoryIcons[cat],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.card,
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

                              return GestureDetector(
                                onTap: () => setState(
                                    () => _selectedId = sound.id),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.transparent
                                        : Colors.transparent,
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
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const Spacer(),
                                      if (!isSelected)
                                        const Icon(
                                          Icons.play_circle_outline,
                                          color: AppColors.textSecondary,
                                          size: 22,
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
                      _sounds.firstWhere((s) => s.id == _selectedId);
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
    return Row(
      children: [
        if (icon != null) ...[
          Text(icon!, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
        ],
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
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
