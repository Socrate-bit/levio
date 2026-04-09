import 'package:flutter/material.dart';

enum MissionType {
  pushUps,
  squats,
  shakePhone,
  math,
  skyPhoto,
  makeBed,
  objectHunt,
  petHunt,
  natureHunt,
  touchGrass,
  bibleVerse,
  affirmation,
  random,
}

enum MissionCategory { all, trending, hunts, physical }

class MissionInfo {
  final MissionType type;
  final String name;
  final String description;
  final Color iconColor;
  final Color iconBg;
  final IconData icon;
  final MissionCategory category;

  const MissionInfo({
    required this.type,
    required this.name,
    required this.description,
    required this.iconColor,
    required this.iconBg,
    required this.icon,
    required this.category,
  });
}

const allMissions = <MissionInfo>[
  MissionInfo(
    type: MissionType.pushUps,
    name: 'Push Ups',
    description: 'Video yourself doing push-ups',
    iconColor: Color(0xFFE05C5C),
    iconBg: Color(0xFFFDE8E8),
    icon: Icons.fitness_center,
    category: MissionCategory.physical,
  ),
  MissionInfo(
    type: MissionType.squats,
    name: 'Squats',
    description: 'Video yourself doing squats',
    iconColor: Color(0xFF3DAD6F),
    iconBg: Color(0xFFE5F5EC),
    icon: Icons.accessibility_new,
    category: MissionCategory.physical,
  ),
  MissionInfo(
    type: MissionType.shakePhone,
    name: 'Shake Phone',
    description: 'Shake your phone 30 times',
    iconColor: Color(0xFF5B8DEF),
    iconBg: Color(0xFFEAF0FD),
    icon: Icons.vibration,
    category: MissionCategory.physical,
  ),
  MissionInfo(
    type: MissionType.math,
    name: 'Math',
    description: 'Solve math problems to wake up',
    iconColor: Color(0xFF7B61FF),
    iconBg: Color(0xFFF0EDFF),
    icon: Icons.calculate,
    category: MissionCategory.trending,
  ),
  MissionInfo(
    type: MissionType.skyPhoto,
    name: 'Sky Photo',
    description: 'Take a photo of the sky',
    iconColor: Color(0xFFE07B3A),
    iconBg: Color(0xFFFDF0E7),
    icon: Icons.wb_sunny,
    category: MissionCategory.hunts,
  ),
  MissionInfo(
    type: MissionType.makeBed,
    name: 'Make Bed',
    description: 'Take a photo of your made bed',
    iconColor: Color(0xFF7B61FF),
    iconBg: Color(0xFFF0EDFF),
    icon: Icons.bed,
    category: MissionCategory.trending,
  ),
  MissionInfo(
    type: MissionType.objectHunt,
    name: 'Object Hunt',
    description: 'Find and photograph a household object',
    iconColor: Color(0xFF3DAD6F),
    iconBg: Color(0xFFE5F5EC),
    icon: Icons.search,
    category: MissionCategory.hunts,
  ),
  MissionInfo(
    type: MissionType.petHunt,
    name: 'Pet Hunt',
    description: 'Find and photograph your pet',
    iconColor: Color(0xFFE07B3A),
    iconBg: Color(0xFFFDF0E7),
    icon: Icons.pets,
    category: MissionCategory.hunts,
  ),
  MissionInfo(
    type: MissionType.natureHunt,
    name: 'Nature Hunt',
    description: 'Find and photograph something in nature',
    iconColor: Color(0xFF3DAD6F),
    iconBg: Color(0xFFE5F5EC),
    icon: Icons.park,
    category: MissionCategory.hunts,
  ),
  MissionInfo(
    type: MissionType.touchGrass,
    name: 'Touch Grass',
    description: 'Take a photo of the grass',
    iconColor: Color(0xFF3DAD6F),
    iconBg: Color(0xFFE5F5EC),
    icon: Icons.grass,
    category: MissionCategory.hunts,
  ),
  MissionInfo(
    type: MissionType.bibleVerse,
    name: 'Bible Verse',
    description: 'Read a bible verse out loud',
    iconColor: Color(0xFFCC8B3A),
    iconBg: Color(0xFFFDF5E7),
    icon: Icons.menu_book,
    category: MissionCategory.trending,
  ),
  MissionInfo(
    type: MissionType.affirmation,
    name: 'Affirmation',
    description: 'Read an affirmation out loud',
    iconColor: Color(0xFFCC4DAA),
    iconBg: Color(0xFFFAE7F5),
    icon: Icons.chat_bubble,
    category: MissionCategory.trending,
  ),
  MissionInfo(
    type: MissionType.random,
    name: 'Random',
    description: 'Surprise mission each morning',
    iconColor: Color(0xFF8E8E93),
    iconBg: Color(0xFFF2F2F7),
    icon: Icons.casino,
    category: MissionCategory.trending,
  ),
];

MissionInfo missionInfoFor(MissionType type) =>
    allMissions.firstWhere((m) => m.type == type);

/// Maps old ChallengeType string names (backward compat) + new MissionType names
MissionType missionTypeFromString(String s) {
  switch (s) {
    case 'pushup':
    case 'pushUps':
      return MissionType.pushUps;
    case 'shake':
    case 'shakePhone':
      return MissionType.shakePhone;
    case 'photo':
    case 'skyPhoto':
      return MissionType.skyPhoto;
    case 'speech':
    case 'affirmation':
      return MissionType.affirmation;
    default:
      return MissionType.values.firstWhere(
        (m) => m.name == s,
        orElse: () => MissionType.pushUps,
      );
  }
}

String geminiPromptFor(MissionType type) {
  switch (type) {
    case MissionType.skyPhoto:
      return 'Does this image clearly show an outdoor sky? Reply with only YES or NO.';
    case MissionType.makeBed:
      return 'Does this image clearly show a neatly made bed? Reply with only YES or NO.';
    case MissionType.objectHunt:
      return 'Does this image show a common household object clearly? Reply with only YES or NO.';
    case MissionType.petHunt:
      return 'Does this image clearly show a pet (dog, cat, bird, etc.)? Reply with only YES or NO.';
    case MissionType.natureHunt:
      return 'Does this image show something from nature (plants, trees, flowers, etc.)? Reply with only YES or NO.';
    case MissionType.touchGrass:
      return 'Does this image clearly show grass or a lawn? Reply with only YES or NO.';
    default:
      return 'Does this image show the required subject? Reply with only YES or NO.';
  }
}

String speechPhraseFor(MissionType type) {
  switch (type) {
    case MissionType.bibleVerse:
      return 'The Lord is my shepherd, I shall not want';
    case MissionType.affirmation:
      return 'Today is going to be a great day';
    default:
      return 'Good morning, time to rise and shine';
  }
}
