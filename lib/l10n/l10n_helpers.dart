import 'package:levio/features/missions/models/mission.dart';
import 'package:levio/l10n/generated/app_localizations.dart';

/// Returns the localized name for a [MissionType].
String localizedMissionName(AppLocalizations l10n, MissionType type) {
  switch (type) {
    case MissionType.pushUps:
      return l10n.missionPushUps;
    case MissionType.squats:
      return l10n.missionSquats;
    case MissionType.shakePhone:
      return l10n.missionShakePhone;
    case MissionType.math:
      return l10n.missionMath;
    case MissionType.skyPhoto:
      return l10n.missionSkyPhoto;
    case MissionType.makeBed:
      return l10n.missionMakeBed;
    case MissionType.objectHunt:
      return l10n.missionObjectHunt;
    case MissionType.petHunt:
      return l10n.missionPetHunt;
    case MissionType.natureHunt:
      return l10n.missionNatureHunt;
    case MissionType.touchGrass:
      return l10n.missionTouchGrass;
    case MissionType.affirmation:
      return l10n.missionAffirmation;
    case MissionType.routine:
      return l10n.missionRoutine;
    case MissionType.breathing:
      return l10n.missionBreathing;
    case MissionType.gratefulness:
      return l10n.missionGratefulness;
    case MissionType.meditation:
      return l10n.missionMeditation;
    case MissionType.bedPhoto:
      return l10n.missionBed;
    case MissionType.random:
      return l10n.missionRandom;
    case MissionType.none:
      return l10n.missionNone;
  }
}

/// Returns the localized description for a [MissionType].
String localizedMissionDesc(AppLocalizations l10n, MissionType type) {
  switch (type) {
    case MissionType.pushUps:
      return l10n.missionPushUpsDesc;
    case MissionType.squats:
      return l10n.missionSquatsDesc;
    case MissionType.shakePhone:
      return l10n.missionShakePhoneDesc;
    case MissionType.math:
      return l10n.missionMathDesc;
    case MissionType.skyPhoto:
      return l10n.missionSkyPhotoDesc;
    case MissionType.makeBed:
      return l10n.missionMakeBedDesc;
    case MissionType.objectHunt:
      return l10n.missionObjectHuntDesc;
    case MissionType.petHunt:
      return l10n.missionPetHuntDesc;
    case MissionType.natureHunt:
      return l10n.missionNatureHuntDesc;
    case MissionType.touchGrass:
      return l10n.missionTouchGrassDesc;
    case MissionType.affirmation:
      return l10n.missionAffirmationDesc;
    case MissionType.routine:
      return l10n.missionRoutineDesc;
    case MissionType.breathing:
      return l10n.missionBreathingDesc;
    case MissionType.gratefulness:
      return l10n.missionGratefulnessDesc;
    case MissionType.meditation:
      return l10n.missionMeditationDesc;
    case MissionType.bedPhoto:
      return l10n.missionBedDesc;
    case MissionType.random:
      return l10n.missionRandomDesc;
    case MissionType.none:
      return l10n.missionNoneDesc;
  }
}

/// Returns the localized name for a sound by its ID.
String localizedSoundName(AppLocalizations l10n, String soundId) {
  switch (soundId) {
    case 'default':
      return l10n.soundDefault;
    case 'clock_2':
      return l10n.soundClock2;
    case 'clock_3':
      return l10n.soundClock3;
    case 'clock_4':
      return l10n.soundClock4;
    case 'funny':
      return l10n.soundFunny;
    case 'celestial':
      return l10n.soundCelestial;
    case 'chiptune':
      return l10n.soundChiptune;
    case 'dreamscape':
      return l10n.soundDreamscape;
    case 'game':
      return l10n.soundGame;
    case 'game_2':
      return l10n.soundGame2;
    case 'oversimplified':
      return l10n.soundOversimplified;
    case 'smooth':
      return l10n.soundSmooth;
    case 'acoustic':
      return l10n.soundAcoustic;
    case 'coming':
      return l10n.soundComing;
    case 'cyber':
      return l10n.soundCyber;
    case 'determination':
      return l10n.soundDetermination;
    case 'dubstep':
      return l10n.soundDubstep;
    case 'hiphop':
      return l10n.soundHiphop;
    case 'piano':
      return l10n.soundPiano;
    case 'tropical':
      return l10n.soundTropical;
    case 'ringstone_1':
      return l10n.soundRingstone1;
    case 'ringstone_2':
      return l10n.soundRingstone2;
    case 'ringstone_3':
      return l10n.soundRingstone3;
    case 'alarm':
      return l10n.soundAlarm;
    case 'hardcore':
      return l10n.soundHardcore;
    default:
      return soundId;
  }
}

/// Returns the localized category name for a sound category key.
String localizedSoundCategory(AppLocalizations l10n, String category) {
  switch (category) {
    case 'Clock':
      return l10n.soundCategoryClock;
    case 'Gentle':
      return l10n.soundCategoryGentle;
    case 'Musical':
      return l10n.soundCategoryMusical;
    case 'Ringstone':
      return l10n.soundCategoryRingstone;
    case 'Violent':
      return l10n.soundCategoryViolent;
    default:
      return category;
  }
}

/// Returns the localized photo target label for photo-based missions.
/// Falls back to the mission name for hunt missions (target comes from selectedItems).
String localizedPhotoTarget(AppLocalizations l10n, MissionType type) {
  switch (type) {
    case MissionType.skyPhoto:
      return l10n.photoTargetSky;
    case MissionType.makeBed:
      return l10n.photoTargetMadeBed;
    case MissionType.bedPhoto:
      return l10n.photoTargetBed;
    case MissionType.touchGrass:
      return l10n.photoTargetGrass;
    default:
      return localizedMissionName(l10n, type);
  }
}

/// Returns the localized badge name by badge ID.
String localizedBadgeName(AppLocalizations l10n, String badgeId) {
  switch (badgeId) {
    case 'risen':
      return l10n.badgeRisen;
    case 'ignite':
      return l10n.badgeIgnite;
    case 'horizon':
      return l10n.badgeHorizon;
    case 'aurora':
      return l10n.badgeAurora;
    case 'celestial':
      return l10n.badgeCelestial;
    case 'nebula':
      return l10n.badgeNebula;
    case 'eternal':
      return l10n.badgeEternal;
    case 'versatile':
      return l10n.badgeVersatile;
    case 'first_light':
      return l10n.badgeFirstLight;
    case 'blitz':
      return l10n.badgeBlitz;
    case 'no_days_off':
      return l10n.badgeNoDaysOff;
    case 'converted':
      return l10n.badgeConverted;
    case 'audiophile':
      return l10n.badgeAudiophile;
    case 'first_night':
      return l10n.badgeFirstNight;
    case 'early_to_bed':
      return l10n.badgeEarlyToBed;
    case 'calm_mind':
      return l10n.badgeCalmMind;
    case 'dreamer':
      return l10n.badgeDreamer;
    case 'well_rested':
      return l10n.badgeWellRested;
    case 'no_nights_off':
      return l10n.badgeNoNightsOff;
    default:
      return badgeId;
  }
}

/// Returns the localized badge requirement description by badge ID.
String localizedBadgeReq(AppLocalizations l10n, String badgeId) {
  switch (badgeId) {
    case 'risen':
      return l10n.badgeRisenReq;
    case 'ignite':
      return l10n.badgeIgniteReq;
    case 'horizon':
      return l10n.badgeHorizonReq;
    case 'aurora':
      return l10n.badgeAuroraReq;
    case 'celestial':
      return l10n.badgeCelestialReq;
    case 'nebula':
      return l10n.badgeNebulaReq;
    case 'eternal':
      return l10n.badgeEternalReq;
    case 'versatile':
      return l10n.badgeVersatileReq;
    case 'first_light':
      return l10n.badgeFirstLightReq;
    case 'blitz':
      return l10n.badgeBlitzReq;
    case 'no_days_off':
      return l10n.badgeNoDaysOffReq;
    case 'converted':
      return l10n.badgeConvertedReq;
    case 'audiophile':
      return l10n.badgeAudiophileReq;
    case 'first_night':
      return l10n.badgeFirstNightReq;
    case 'early_to_bed':
      return l10n.badgeEarlyToBedReq;
    case 'calm_mind':
      return l10n.badgeCalmMindReq;
    case 'dreamer':
      return l10n.badgeDreamerReq;
    case 'well_rested':
      return l10n.badgeWellRestedReq;
    case 'no_nights_off':
      return l10n.badgeNoNightsOffReq;
    default:
      return '';
  }
}

/// Returns the localized badge quote by badge ID.
String localizedBadgeQuote(AppLocalizations l10n, String badgeId) {
  switch (badgeId) {
    case 'risen':
      return l10n.badgeRisenQuote;
    case 'ignite':
      return l10n.badgeIgniteQuote;
    case 'horizon':
      return l10n.badgeHorizonQuote;
    case 'aurora':
      return l10n.badgeAuroraQuote;
    case 'celestial':
      return l10n.badgeCelestialQuote;
    case 'nebula':
      return l10n.badgeNebulaQuote;
    case 'eternal':
      return l10n.badgeEternalQuote;
    case 'versatile':
      return l10n.badgeVersatileQuote;
    case 'first_light':
      return l10n.badgeFirstLightQuote;
    case 'blitz':
      return l10n.badgeBlitzQuote;
    case 'no_days_off':
      return l10n.badgeNoDaysOffQuote;
    case 'converted':
      return l10n.badgeConvertedQuote;
    case 'audiophile':
      return l10n.badgeAudiophileQuote;
    case 'first_night':
      return l10n.badgeFirstNightQuote;
    case 'early_to_bed':
      return l10n.badgeEarlyToBedQuote;
    case 'calm_mind':
      return l10n.badgeCalmMindQuote;
    case 'dreamer':
      return l10n.badgeDreamerQuote;
    case 'well_rested':
      return l10n.badgeWellRestedQuote;
    case 'no_nights_off':
      return l10n.badgeNoNightsOffQuote;
    default:
      return '';
  }
}

/// Returns the localized month abbreviation (1-indexed).
String localizedMonth(AppLocalizations l10n, int month) {
  switch (month) {
    case 1:
      return l10n.monthJan;
    case 2:
      return l10n.monthFeb;
    case 3:
      return l10n.monthMar;
    case 4:
      return l10n.monthApr;
    case 5:
      return l10n.monthMay;
    case 6:
      return l10n.monthJun;
    case 7:
      return l10n.monthJul;
    case 8:
      return l10n.monthAug;
    case 9:
      return l10n.monthSep;
    case 10:
      return l10n.monthOct;
    case 11:
      return l10n.monthNov;
    case 12:
      return l10n.monthDec;
    default:
      return '';
  }
}

/// Returns the short day label (3-letter) for a weekday (0=Sun, 6=Sat).
String localizedDayShort(AppLocalizations l10n, int day) {
  switch (day) {
    case 0:
      return l10n.daySun;
    case 1:
      return l10n.dayMon;
    case 2:
      return l10n.dayTue;
    case 3:
      return l10n.dayWed;
    case 4:
      return l10n.dayThu;
    case 5:
      return l10n.dayFri;
    case 6:
      return l10n.daySat;
    default:
      return '';
  }
}

/// Returns the full day name for a weekday (0=Sun, 6=Sat).
String localizedDayFull(AppLocalizations l10n, int day) {
  switch (day) {
    case 0:
      return l10n.daySundayFull;
    case 1:
      return l10n.dayMondayFull;
    case 2:
      return l10n.dayTuesdayFull;
    case 3:
      return l10n.dayWednesdayFull;
    case 4:
      return l10n.dayThursdayFull;
    case 5:
      return l10n.dayFridayFull;
    case 6:
      return l10n.daySaturdayFull;
    default:
      return '';
  }
}

/// Returns the localized item name for item picker items.
String localizedItemName(AppLocalizations l10n, String item) {
  switch (item) {
    case 'Toothbrush':
      return l10n.itemToothbrush;
    case 'Running Faucet':
      return l10n.itemRunningFaucet;
    case 'Shoes':
      return l10n.itemShoes;
    case 'Fridge':
      return l10n.itemFridge;
    case 'Keys':
      return l10n.itemKeys;
    case 'Coffee Mug':
      return l10n.itemCoffeeMug;
    case 'Mirror':
      return l10n.itemMirror;
    case 'Water Bottle':
      return l10n.itemWaterBottle;
    case 'Dustpan':
      return l10n.itemDustpan;
    case 'Toilet':
      return l10n.itemToilet;
    case 'Book':
      return l10n.itemBook;
    case 'Lamp':
      return l10n.itemLamp;
    case 'TV Remote':
      return l10n.itemTvRemote;
    case 'Front Door':
      return l10n.itemFrontDoor;
    case 'Stove':
      return l10n.itemStove;
    case 'Lotion Bottle':
      return l10n.itemLotionBottle;
    case 'Soap':
      return l10n.itemSoap;
    case 'Plant':
      return l10n.itemPlant;
    case 'Plate':
      return l10n.itemPlate;
    case 'Towel':
      return l10n.itemTowel;
    case 'Backpack':
      return l10n.itemBackpack;
    case 'Headphones':
      return l10n.itemHeadphones;
    case 'Shower':
      return l10n.itemShower;
    case 'Tape':
      return l10n.itemTape;
    case 'Dog':
      return l10n.petDog;
    case 'Cat':
      return l10n.petCat;
    case 'Bird':
      return l10n.petBird;
    case 'Fish':
      return l10n.petFish;
    case 'Hamster':
      return l10n.petHamster;
    case 'Rabbit':
      return l10n.petRabbit;
    case 'Turtle':
      return l10n.petTurtle;
    case 'Guinea Pig':
      return l10n.petGuineaPig;
    case 'Lizard':
      return l10n.petLizard;
    case 'Snake':
      return l10n.petSnake;
    case 'Tree':
      return l10n.natureTree;
    case 'Flower':
      return l10n.natureFlower;
    case 'Rock':
      return l10n.natureRock;
    case 'Leaf':
      return l10n.natureLeaf;
    case 'Grass':
      return l10n.natureGrass;
    case 'Bush':
      return l10n.natureBush;
    case 'Stick':
      return l10n.natureStick;
    case 'Pinecone':
      return l10n.naturePinecone;
    case 'Drink a glass of water':
      return l10n.routineDrinkWater;
    case 'Dim your light':
      return l10n.routineDimLight;
    case 'Close your computer':
      return l10n.routineCloseComputer;
    case 'Brush your teeth':
      return l10n.routineBrushTeeth;
    case 'Prepare your clothes':
      return l10n.routinePrepareClothes;
    case 'Todo list for next day':
      return l10n.routineTodoList;
    case 'Journaling':
      return l10n.routineJournaling;
    case 'Breathing':
      return l10n.routineBreathing;
    case 'Read':
      return l10n.routineRead;
    // Wake-up routine labels.
    case 'Open curtains or lights':
      return l10n.routineOpenCurtains;
    case 'Do 10 push-ups or 20 squats':
      return l10n.routineExercise;
    case 'Take a shower':
      return l10n.routineShower;
    case 'Have breakfast':
      return l10n.routineBreakfast;
    case 'Get dressed':
      return l10n.routineGetDressed;
    // Wind-down routine labels.
    case 'Put your phone away':
      return l10n.routinePutPhoneAway;
    case 'Lower the room temperature':
      return l10n.routineLowerTemp;
    default:
      return item;
  }
}

/// The original built-in routine step labels. Kept unchanged for back-compat
/// with the legacy routine picker (no mode) and v1 onboarding fallbacks.
const routinePresetSteps = <String>[
  'Drink a glass of water',
  'Dim your light',
  'Close your computer',
  'Brush your teeth',
  'Prepare your clothes',
  'Todo list for next day',
  'Journaling',
  'Breathing',
  'Read',
];

/// The built-in wind-down (night) routine step labels for the v2 funnel.
const routineNightPresetSteps = <String>[
  // First 3 are the defaults pre-selected during onboarding.
  'Dim your light',
  'Prepare your clothes',
  'Put your phone away',
  'Lower the room temperature',
  'Take a shower',
  'Brush your teeth',
  'Todo list for next day',
  'Read',
];

/// The built-in wake-up (morning) routine step labels for the v2 funnel.
const routineWakePresetSteps = <String>[
  // First 3 are the defaults pre-selected during onboarding.
  'Take a shower',
  'Brush your teeth',
  'Get dressed',
  'Open curtains or lights',
  'Do 10 push-ups or 20 squats',
  'Drink a glass of water',
  'Have breakfast',
];
