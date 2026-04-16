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
  /// Relative path under assets/ (e.g. 'alarm_set/Clock/Clock 1.mp3')
  final String assetPath;

  const AlarmSoundItem({
    required this.id,
    required this.name,
    required this.color,
    required this.category,
    required this.assetPath,
  });
}

const alarmSounds = [
  // Clock
  AlarmSoundItem(
      id: 'default',
      name: 'Default',
      color: Color(0xFF8E8E93),
      category: 'Clock',
      assetPath: 'alarm_set/Clock/Clock 1.mp3'),
  AlarmSoundItem(
      id: 'clock_2',
      name: 'Clock 2',
      color: Color(0xFF4A5568),
      category: 'Clock',
      assetPath: 'alarm_set/Clock/Clock 2.mp3'),
  AlarmSoundItem(
      id: 'clock_3',
      name: 'Clock 3',
      color: Color(0xFF5B6B7F),
      category: 'Clock',
      assetPath: 'alarm_set/Clock/Clock 3.mp3'),
  AlarmSoundItem(
      id: 'clock_4',
      name: 'Clock 4',
      color: Color(0xFF6C7A89),
      category: 'Clock',
      assetPath: 'alarm_set/Clock/Clock 4.mp3'),
  AlarmSoundItem(
      id: 'funny',
      name: 'Funny',
      color: Color(0xFFFF6B6B),
      category: 'Clock',
      assetPath: 'alarm_set/Clock/Funny.mp3'),
  // Gentle
  AlarmSoundItem(
      id: 'celestial',
      name: 'Celestial',
      color: Color(0xFF667EEA),
      category: 'Gentle',
      assetPath: 'alarm_set/Gentle/Celestial.mp3'),
  AlarmSoundItem(
      id: 'chiptune',
      name: 'Chiptune',
      color: Color(0xFF48BB78),
      category: 'Gentle',
      assetPath: 'alarm_set/Gentle/Chiptune.mp3'),
  AlarmSoundItem(
      id: 'dreamscape',
      name: 'Dreamscape',
      color: Color(0xFFB794F4),
      category: 'Gentle',
      assetPath: 'alarm_set/Gentle/Dreamscape.mp3'),
  AlarmSoundItem(
      id: 'game',
      name: 'Game',
      color: Color(0xFF38B2AC),
      category: 'Gentle',
      assetPath: 'alarm_set/Gentle/Game.mp3'),
  AlarmSoundItem(
      id: 'game_2',
      name: 'Game 2',
      color: Color(0xFF4FD1C5),
      category: 'Gentle',
      assetPath: 'alarm_set/Gentle/Game 2.mp3'),
  AlarmSoundItem(
      id: 'oversimplified',
      name: 'Oversimplified',
      color: Color(0xFFED8936),
      category: 'Gentle',
      assetPath: 'alarm_set/Gentle/Oversimplified.mp3'),
  AlarmSoundItem(
      id: 'smooth',
      name: 'Smooth',
      color: Color(0xFF76E4F7),
      category: 'Gentle',
      assetPath: 'alarm_set/Gentle/Smooth 1.mp3'),
  // Musical
  AlarmSoundItem(
      id: 'acoustic',
      name: 'Acoustic',
      color: Color(0xFFD69E2E),
      category: 'Musical',
      assetPath: 'alarm_set/Musical/Acoustic.mp3'),
  AlarmSoundItem(
      id: 'coming',
      name: 'Coming',
      color: Color(0xFFE53E3E),
      category: 'Musical',
      assetPath: 'alarm_set/Musical/Coming.mp3'),
  AlarmSoundItem(
      id: 'cyber',
      name: 'Cyber',
      color: Color(0xFF5DADE2),
      category: 'Musical',
      assetPath: 'alarm_set/Musical/Cyber.mp3'),
  AlarmSoundItem(
      id: 'determination',
      name: 'Determination',
      color: Color(0xFFE8B400),
      category: 'Musical',
      assetPath: 'alarm_set/Musical/Determination.mp3'),
  AlarmSoundItem(
      id: 'dubstep',
      name: 'Dubstep',
      color: Color(0xFFB83280),
      category: 'Musical',
      assetPath: 'alarm_set/Musical/Dubstep.mp3'),
  AlarmSoundItem(
      id: 'hiphop',
      name: 'Hiphop',
      color: Color(0xFFFF8C42),
      category: 'Musical',
      assetPath: 'alarm_set/Musical/Hiphop.mp3'),
  AlarmSoundItem(
      id: 'piano',
      name: 'Piano',
      color: Color(0xFF2D6A4F),
      category: 'Musical',
      assetPath: 'alarm_set/Musical/Piano.mp3'),
  AlarmSoundItem(
      id: 'tropical',
      name: 'Tropical',
      color: Color(0xFF1FAB89),
      category: 'Musical',
      assetPath: 'alarm_set/Musical/Tropical.mp3'),
  // Ringstone
  AlarmSoundItem(
      id: 'ringstone_1',
      name: 'Ringstone 1',
      color: Color(0xFFCC79B8),
      category: 'Ringstone',
      assetPath: 'alarm_set/Ringstone/Ringstone 1.mp3'),
  AlarmSoundItem(
      id: 'ringstone_2',
      name: 'Ringstone 2',
      color: Color(0xFFED64A6),
      category: 'Ringstone',
      assetPath: 'alarm_set/Ringstone/Ringstone 2.mp3'),
  AlarmSoundItem(
      id: 'ringstone_3',
      name: 'Ringstone 3',
      color: Color(0xFFD53F8C),
      category: 'Ringstone',
      assetPath: 'alarm_set/Ringstone/Ringstone 3.mp3'),
  // Violent
  AlarmSoundItem(
      id: 'alarm',
      name: 'Alarm',
      color: Color(0xFFC53030),
      category: 'Violent',
      assetPath: 'alarm_set/Violent/Alarm.mp3'),
  AlarmSoundItem(
      id: 'hardcore',
      name: 'Hardcore',
      color: Color(0xFF9B2C2C),
      category: 'Violent',
      assetPath: 'alarm_set/Violent/Hardcore.mp3'),
];

const soundCategories = ['Clock', 'Gentle', 'Musical', 'Ringstone', 'Violent'];
const soundCategoryIcons = {
  'Clock': '⏰',
  'Gentle': '🌿',
  'Musical': '🎵',
  'Ringstone': '📱',
  'Violent': '⚡',
};

/// Returns the asset path for a preset sound ID, or null if not found.
String? soundAssetPath(String id) {
  final sound = alarmSounds.where((s) => s.id == id).firstOrNull;
  return sound?.assetPath;
}

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
