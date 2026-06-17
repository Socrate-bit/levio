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
    case MissionType.random:
      return l10n.missionRandom;
    case MissionType.spinningWheel:
      return l10n.missionSpinningWheel;
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
    case MissionType.random:
      return l10n.missionRandomDesc;
    case MissionType.spinningWheel:
      return l10n.missionSpinningWheelDesc;
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
    case 'Kim Kardashian':
      return l10n.itemKimKardashian;
    case 'Snoop Dogg':
      return l10n.itemSnoopDogg;
    case 'Rubber Duck':
      return l10n.itemRubberDuck;
    case 'Banana':
      return l10n.itemBanana;
    case 'Pickle':
      return l10n.itemPickle;
    case 'Croc':
      return l10n.itemCroc;
    case 'Lava Lamp':
      return l10n.itemLavaLamp;
    case 'Ping Pong Paddle':
      return l10n.itemPingPongPaddle;
    case 'Egg':
      return l10n.itemEgg;
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
    default:
      return item;
  }
}
