import 'package:flutter/material.dart';

enum MissionType {
  none,
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
  affirmation,
  routine,
  breathing,
  gratefulness,
  meditation,
  bedPhoto,
  flappyBird,
  random,
}

/// Mission filter tabs ("ships"). `all` is the show-everything sentinel;
/// `wakeup`/`sleep` are goal-based ships; the rest are functional groupings.
enum MissionCategory { all, wakeup, sleep, trending, hunts, physical }

class MissionInfo {
  final MissionType type;
  final String name;
  final String description;
  final Color iconColor;
  final Color iconBg;
  final IconData icon;

  /// Full-color illustration asset shown for the mission. Null falls back to
  /// the Material [icon] (e.g. the `none` mission).
  final String? iconAsset;

  /// Tabs this mission appears under — a mission can belong to a functional
  /// group and one or more ships at once.
  final List<MissionCategory> categories;

  const MissionInfo({
    required this.type,
    required this.name,
    required this.description,
    required this.iconColor,
    required this.iconBg,
    required this.icon,
    required this.categories,
    this.iconAsset,
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
    iconAsset: 'assets/icon_missions/push-up.png',
    categories: [MissionCategory.physical, MissionCategory.wakeup],
  ),
  MissionInfo(
    type: MissionType.squats,
    name: 'Squats',
    description: 'Video yourself doing squats',
    iconColor: Color(0xFF3DAD6F),
    iconBg: Color(0xFFE5F5EC),
    icon: Icons.accessibility_new,
    iconAsset: 'assets/icon_missions/squat.png',
    categories: [MissionCategory.physical, MissionCategory.wakeup],
  ),
  MissionInfo(
    type: MissionType.shakePhone,
    name: 'Shake Phone',
    description: 'Shake your phone to wake up',
    iconColor: Color(0xFF5B8DEF),
    iconBg: Color(0xFFEAF0FD),
    icon: Icons.vibration,
    iconAsset: 'assets/icon_missions/shake.png',
    categories: [MissionCategory.physical, MissionCategory.wakeup],
  ),
  MissionInfo(
    type: MissionType.math,
    name: 'Math',
    description: 'Solve math problems to wake up',
    iconColor: Color(0xFF7B61FF),
    iconBg: Color(0xFFF0EDFF),
    icon: Icons.calculate,
    iconAsset: 'assets/icon_missions/maths.png',
    categories: [MissionCategory.trending, MissionCategory.wakeup],
  ),
  MissionInfo(
    type: MissionType.skyPhoto,
    name: 'Sky Photo',
    description: 'Take a photo of the sky',
    iconColor: Color(0xFFE07B3A),
    iconBg: Color(0xFFFDF0E7),
    icon: Icons.wb_sunny,
    iconAsset: 'assets/icon_missions/cloudy.png',
    categories: [MissionCategory.hunts, MissionCategory.wakeup],
  ),
  MissionInfo(
    type: MissionType.makeBed,
    name: 'Make Bed',
    description: 'Take a photo of your made bed',
    iconColor: Color(0xFF7B61FF),
    iconBg: Color(0xFFF0EDFF),
    icon: Icons.bed,
    iconAsset: 'assets/icon_missions/bed.png',
    categories: [MissionCategory.trending, MissionCategory.wakeup],
  ),
  MissionInfo(
    type: MissionType.objectHunt,
    name: 'Object Hunt',
    description: 'Find and photograph a household object',
    iconColor: Color(0xFF3DAD6F),
    iconBg: Color(0xFFE5F5EC),
    icon: Icons.search,
    iconAsset: 'assets/icon_missions/search.png',
    categories: [MissionCategory.hunts, MissionCategory.wakeup],
  ),
  MissionInfo(
    type: MissionType.petHunt,
    name: 'Pet Hunt',
    description: 'Find and photograph your pet',
    iconColor: Color(0xFFE07B3A),
    iconBg: Color(0xFFFDF0E7),
    icon: Icons.pets,
    iconAsset: 'assets/icon_missions/kitten.png',
    categories: [MissionCategory.hunts, MissionCategory.wakeup],
  ),
  MissionInfo(
    type: MissionType.natureHunt,
    name: 'Nature Hunt',
    description: 'Find and photograph something in nature',
    iconColor: Color(0xFF3DAD6F),
    iconBg: Color(0xFFE5F5EC),
    icon: Icons.park,
    iconAsset: 'assets/icon_missions/plant.png',
    categories: [MissionCategory.hunts, MissionCategory.wakeup],
  ),
  MissionInfo(
    type: MissionType.touchGrass,
    name: 'Touch Grass',
    description: 'Take a photo of the grass',
    iconColor: Color(0xFF3DAD6F),
    iconBg: Color(0xFFE5F5EC),
    icon: Icons.grass,
    iconAsset: 'assets/icon_missions/grass.png',
    categories: [MissionCategory.hunts, MissionCategory.wakeup],
  ),
  MissionInfo(
    type: MissionType.affirmation,
    name: 'Affirmation',
    description: 'Read an affirmation out loud',
    iconColor: Color(0xFFCC4DAA),
    iconBg: Color(0xFFFAE7F5),
    icon: Icons.chat_bubble,
    iconAsset: 'assets/icon_missions/galaxy.png',
    categories: [
      MissionCategory.trending,
      MissionCategory.wakeup,
      MissionCategory.sleep,
    ],
  ),
  MissionInfo(
    type: MissionType.breathing,
    name: 'Breathing',
    description: 'Follow a guided breathing exercise',
    iconColor: Color(0xFF4A90D9),
    iconBg: Color(0xFFE7F1FD),
    icon: Icons.air,
    iconAsset: 'assets/icon_missions/bad-breath.png',
    categories: [MissionCategory.sleep],
  ),
  MissionInfo(
    type: MissionType.gratefulness,
    name: 'Gratefulness',
    description: 'Answer 3 questions to start positive',
    iconColor: Color(0xFFE0566B),
    iconBg: Color(0xFFFDEAEA),
    icon: Icons.favorite_border,
    iconAsset: 'assets/icon_missions/gratitude.png',
    categories: [MissionCategory.wakeup, MissionCategory.sleep],
  ),
  MissionInfo(
    type: MissionType.meditation,
    name: 'Meditation',
    description: 'Listen to a 2-minute guided meditation',
    iconColor: Color(0xFF7B61FF),
    iconBg: Color(0xFFF0EDFF),
    icon: Icons.self_improvement,
    iconAsset: 'assets/icon_missions/meditation.png',
    categories: [MissionCategory.sleep],
  ),
  MissionInfo(
    type: MissionType.bedPhoto,
    name: 'Bed',
    description: 'Take a photo of your bed',
    iconColor: Color(0xFF5B8DEF),
    iconBg: Color(0xFFEAF0FD),
    icon: Icons.king_bed,
    iconAsset: 'assets/icon_missions/bed_plain.png',
    categories: [MissionCategory.sleep],
  ),
  MissionInfo(
    type: MissionType.routine,
    name: 'Routine',
    description: 'Complete your checklist of steps',
    iconColor: Color(0xFF2BA7A0),
    iconBg: Color(0xFFE2F4F2),
    icon: Icons.checklist,
    iconAsset: 'assets/icon_missions/exercise-routine.png',
    categories: [MissionCategory.trending, MissionCategory.sleep],
  ),
  MissionInfo(
    type: MissionType.flappyBird,
    name: 'Flappy Bird',
    description: 'Play Flappy Bird to reach a score',
    iconColor: Color(0xFFF5B400),
    iconBg: Color(0xFFFFF6E0),
    icon: Icons.flutter_dash,
    iconAsset: 'assets/flappybird/sprites/yellowbird-midflap.png',
    categories: [MissionCategory.trending, MissionCategory.wakeup],
  ),
  MissionInfo(
    type: MissionType.random,
    name: 'Random',
    description: 'Surprise mission each morning',
    iconColor: Color(0xFF8E8E93),
    iconBg: Color(0xFFF2F2F7),
    icon: Icons.casino,
    iconAsset: 'assets/icon_missions/dices.png',
    categories: [MissionCategory.trending],
  ),
];

const _noneInfo = MissionInfo(
  type: MissionType.none,
  name: 'No mission',
  description: 'Simple alarm with no task',
  iconColor: Color(0xFF8E8E93),
  iconBg: Color(0xFFF2F2F7),
  icon: Icons.alarm,
  categories: [MissionCategory.all],
);

MissionInfo missionInfoFor(MissionType type) =>
    type == MissionType.none
        ? _noneInfo
        : allMissions.firstWhere((m) => m.type == type);

MissionType missionTypeFromString(String s) {
  switch (s) {
    case 'none':
      return MissionType.none;
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
    case MissionType.bedPhoto:
      return 'Does this image clearly show a bed? Reply with only YES or NO.';
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
