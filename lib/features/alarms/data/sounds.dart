import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

// ── Custom (user-uploaded) sounds ──────────────────────────────────────

const _customSoundsKey = 'custom_sounds';
const _customSoundsDir = 'custom_sounds';
const maxCustomSoundBytes = 10 * 1024 * 1024; // 10 MB

class CustomSoundItem {
  final String id;
  final String name;
  final String fileName;

  const CustomSoundItem({
    required this.id,
    required this.name,
    required this.fileName,
  });

  factory CustomSoundItem.fromJson(Map<String, dynamic> json) =>
      CustomSoundItem(
        id: json['id'] as String,
        name: json['name'] as String,
        fileName: json['fileName'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'fileName': fileName,
      };
}

/// Returns true when [id] refers to a user-uploaded sound.
bool isCustomSound(String id) => id.startsWith('custom_');

/// Absolute path to [fileName] inside the custom sounds directory.
Future<String> customSoundFilePath(String fileName) async {
  final dir = await getApplicationDocumentsDirectory();
  return '${dir.path}/$_customSoundsDir/$fileName';
}

/// Load persisted custom sounds from SharedPreferences.
Future<List<CustomSoundItem>> loadCustomSounds() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getStringList(_customSoundsKey);
  if (raw == null) return [];
  return raw.map((e) => CustomSoundItem.fromJson(jsonDecode(e) as Map<String, dynamic>)).toList();
}

/// Persist [sounds] to SharedPreferences.
Future<void> saveCustomSounds(List<CustomSoundItem> sounds) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(
    _customSoundsKey,
    sounds.map((s) => jsonEncode(s.toJson())).toList(),
  );
}

/// Pick a source file, copy it into the app documents dir, and persist metadata.
/// Returns the new item, or null if the file exceeds the size limit.
Future<CustomSoundItem?> addCustomSound(String sourceFilePath, String originalFileName) async {
  final sourceFile = File(sourceFilePath);

  // Size guard
  if (await sourceFile.length() > maxCustomSoundBytes) return null;

  final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
  final ext = originalFileName.contains('.') ? originalFileName.substring(originalFileName.lastIndexOf('.')) : '.mp3';
  final storedName = '$id$ext';

  // Copy to app documents
  final destPath = await customSoundFilePath(storedName);
  final destDir = Directory(destPath).parent;
  if (!destDir.existsSync()) destDir.createSync(recursive: true);
  await sourceFile.copy(destPath);

  // Derive display name from original file name
  final displayName = _displayNameFrom(originalFileName);

  final item = CustomSoundItem(id: id, name: displayName, fileName: storedName);
  final list = await loadCustomSounds();
  list.add(item);
  await saveCustomSounds(list);
  return item;
}

/// Remove a custom sound file and its metadata entry.
Future<void> deleteCustomSound(String id) async {
  final list = await loadCustomSounds();
  final item = list.where((s) => s.id == id).firstOrNull;
  if (item != null) {
    try {
      final path = await customSoundFilePath(item.fileName);
      final file = File(path);
      if (file.existsSync()) await file.delete();
    } catch (e) {
      debugPrint('[sounds] failed to delete file: $e');
    }
  }
  list.removeWhere((s) => s.id == id);
  await saveCustomSounds(list);
}

/// Convert a file name like "my_alarm-sound.mp3" → "My Alarm Sound".
String _displayNameFrom(String fileName) {
  var name = fileName;
  final dotIdx = name.lastIndexOf('.');
  if (dotIdx > 0) name = name.substring(0, dotIdx);
  return name
      .replaceAll(RegExp(r'[_\-]'), ' ')
      .trim()
      .split(RegExp(r'\s+'))
      .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
