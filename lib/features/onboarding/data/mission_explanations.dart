import 'package:levio/l10n/generated/app_localizations.dart';
import '../../missions/models/mission.dart';

/// Returns localized mission explanation strings keyed by title/subtitle/body.
Map<MissionType, Map<String, String>> getMissionExplanations(
    AppLocalizations l10n) => {
  MissionType.pushUps: {
    'title': l10n.missionExplPushUpsTitle,
    'subtitle': l10n.missionExplPushUpsSubtitle,
    'body': l10n.missionExplPushUpsBody,
  },
  MissionType.squats: {
    'title': l10n.missionExplSquatsTitle,
    'subtitle': l10n.missionExplSquatsSubtitle,
    'body': l10n.missionExplSquatsBody,
  },
  MissionType.shakePhone: {
    'title': l10n.missionExplShakeTitle,
    'subtitle': l10n.missionExplShakeSubtitle,
    'body': l10n.missionExplShakeBody,
  },
  MissionType.math: {
    'title': l10n.missionExplMathTitle,
    'subtitle': l10n.missionExplMathSubtitle,
    'body': l10n.missionExplMathBody,
  },
  MissionType.skyPhoto: {
    'title': l10n.missionExplSkyPhotoTitle,
    'subtitle': l10n.missionExplSkyPhotoSubtitle,
    'body': l10n.missionExplSkyPhotoBody,
  },
  MissionType.makeBed: {
    'title': l10n.missionExplMakeBedTitle,
    'subtitle': l10n.missionExplMakeBedSubtitle,
    'body': l10n.missionExplMakeBedBody,
  },
  MissionType.objectHunt: {
    'title': l10n.missionExplObjectHuntTitle,
    'subtitle': l10n.missionExplObjectHuntSubtitle,
    'body': l10n.missionExplObjectHuntBody,
  },
  MissionType.petHunt: {
    'title': l10n.missionExplPetHuntTitle,
    'subtitle': l10n.missionExplPetHuntSubtitle,
    'body': l10n.missionExplPetHuntBody,
  },
  MissionType.natureHunt: {
    'title': l10n.missionExplNatureHuntTitle,
    'subtitle': l10n.missionExplNatureHuntSubtitle,
    'body': l10n.missionExplNatureHuntBody,
  },
  MissionType.touchGrass: {
    'title': l10n.missionExplTouchGrassTitle,
    'subtitle': l10n.missionExplTouchGrassSubtitle,
    'body': l10n.missionExplTouchGrassBody,
  },
  MissionType.affirmation: {
    'title': l10n.missionExplAffirmationTitle,
    'subtitle': l10n.missionExplAffirmationSubtitle,
    'body': l10n.missionExplAffirmationBody,
  },
  MissionType.flappyBird: {
    'title': l10n.missionExplFlappyBirdTitle,
    'subtitle': l10n.missionExplFlappyBirdSubtitle,
    'body': l10n.missionExplFlappyBirdBody,
  },
};
