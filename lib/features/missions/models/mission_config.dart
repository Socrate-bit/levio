import 'package:equatable/equatable.dart';

import '../../alarms/cubit/alarm_state.dart';
import 'mission.dart';

/// Per-mission configuration stored on an alarm.
class MissionConfig extends Equatable {
  final MissionType type;

  /// Rep count for pushUps (default 5), squats (default 10), shakePhone (default 15).
  final int? repCount;

  /// Math mission difficulty.
  final MathDifficulty? mathDifficulty;

  /// Number of math problems to solve (default 3).
  final int? mathProblemCount;

  /// Selected items for objectHunt/petHunt/natureHunt pickers.
  final List<String>? selectedItems;

  /// Selected affirmations (includes user-added custom ones).
  final List<String>? selectedAffirmations;

  /// Number of affirmations to say (default 1).
  final int? affirmationCount;

  /// Random pool — null/empty = all missions, 1 = that one, 2+ = random from pool.
  final List<MissionType>? randomPool;

  /// Number of breathing rounds (default 3).
  final int? breathingRounds;

  const MissionConfig({
    required this.type,
    this.repCount,
    this.mathDifficulty,
    this.mathProblemCount,
    this.selectedItems,
    this.selectedAffirmations,
    this.affirmationCount,
    this.randomPool,
    this.breathingRounds,
  });

  Map<String, dynamic> toMap() => {
        'type': type.name,
        if (repCount != null) 'repCount': repCount,
        if (mathDifficulty != null) 'mathDifficulty': mathDifficulty!.name,
        if (mathProblemCount != null) 'mathProblemCount': mathProblemCount,
        if (selectedItems != null) 'selectedItems': selectedItems,
        if (selectedAffirmations != null)
          'selectedAffirmations': selectedAffirmations,
        if (affirmationCount != null) 'affirmationCount': affirmationCount,
        if (randomPool != null)
          'randomPool': randomPool!.map((t) => t.name).toList(),
        if (breathingRounds != null) 'breathingRounds': breathingRounds,
      };

  factory MissionConfig.fromMap(Map<String, dynamic> m) {
    return MissionConfig(
      type: MissionType.values.firstWhere(
        (t) => t.name == m['type'],
        orElse: () => MissionType.none,
      ),
      repCount: m['repCount'] as int?,
      mathDifficulty: m['mathDifficulty'] != null
          ? MathDifficulty.values.firstWhere(
              (d) => d.name == m['mathDifficulty'],
              orElse: () => MathDifficulty.easy,
            )
          : null,
      mathProblemCount: m['mathProblemCount'] as int?,
      selectedItems: (m['selectedItems'] as List?)?.cast<String>(),
      selectedAffirmations:
          (m['selectedAffirmations'] as List?)?.cast<String>(),
      affirmationCount: m['affirmationCount'] as int?,
      randomPool: (m['randomPool'] as List?)
          ?.cast<String>()
          .map((s) => MissionType.values.firstWhere(
                (t) => t.name == s,
                orElse: () => MissionType.none,
              ))
          .where((t) => t != MissionType.none)
          .toList(),
      breathingRounds: m['breathingRounds'] as int?,
    );
  }

  MissionConfig copyWith({
    MissionType? type,
    int? repCount,
    bool clearRepCount = false,
    MathDifficulty? mathDifficulty,
    bool clearMathDifficulty = false,
    int? mathProblemCount,
    bool clearMathProblemCount = false,
    List<String>? selectedItems,
    bool clearSelectedItems = false,
    List<String>? selectedAffirmations,
    bool clearSelectedAffirmations = false,
    int? affirmationCount,
    bool clearAffirmationCount = false,
    List<MissionType>? randomPool,
    bool clearRandomPool = false,
    int? breathingRounds,
    bool clearBreathingRounds = false,
  }) =>
      MissionConfig(
        type: type ?? this.type,
        repCount: clearRepCount ? null : repCount ?? this.repCount,
        mathDifficulty:
            clearMathDifficulty ? null : mathDifficulty ?? this.mathDifficulty,
        mathProblemCount: clearMathProblemCount
            ? null
            : mathProblemCount ?? this.mathProblemCount,
        selectedItems:
            clearSelectedItems ? null : selectedItems ?? this.selectedItems,
        selectedAffirmations: clearSelectedAffirmations
            ? null
            : selectedAffirmations ?? this.selectedAffirmations,
        affirmationCount: clearAffirmationCount
            ? null
            : affirmationCount ?? this.affirmationCount,
        randomPool: clearRandomPool ? null : randomPool ?? this.randomPool,
        breathingRounds: clearBreathingRounds
            ? null
            : breathingRounds ?? this.breathingRounds,
      );

  @override
  List<Object?> get props => [
        type,
        repCount,
        mathDifficulty,
        mathProblemCount,
        selectedItems,
        selectedAffirmations,
        affirmationCount,
        randomPool,
        breathingRounds,
      ];
}
