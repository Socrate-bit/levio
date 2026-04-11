import 'package:flutter/material.dart';

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

const alarmSounds = [
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

const soundCategories = ['Classic', 'Viral', 'Aggressive', 'Peaceful'];
const soundCategoryIcons = {
  'Classic': '🔔',
  'Viral': '🔥',
  'Aggressive': '⚡',
  'Peaceful': '🌿',
};
