// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Levio';

  @override
  String get navHome => 'Home';

  @override
  String get navAlarms => 'Alarms';

  @override
  String get navInsights => 'Insights';

  @override
  String get navSettings => 'Settings';

  @override
  String get alarmsTitle => 'Alarms';

  @override
  String get alarmsEmpty => 'No alarms yet';

  @override
  String get alarmsEmptyHint => 'Tap + to create your first alarm';

  @override
  String get alarmsMissionAlarm => 'Mission Alarm';

  @override
  String get alarmsMissionAlarmSubtitle => 'Finish a task first';

  @override
  String get alarmsNormalAlarm => 'Normal Alarm';

  @override
  String get alarmsNormalAlarmSubtitle => 'Just an alarm';

  @override
  String alarmsDefaultName(int number) {
    return 'Alarm #$number';
  }

  @override
  String alarmsMissionsCount(int count) {
    return '$count Missions';
  }

  @override
  String get alarmsOneTime => 'One-time';

  @override
  String get alarmsEveryDay => 'Every day';

  @override
  String get alarmsWeekdays => 'Mon, Tue, Wed, Thu, Fri';

  @override
  String get daySun => 'Sun';

  @override
  String get dayMon => 'Mon';

  @override
  String get dayTue => 'Tue';

  @override
  String get dayWed => 'Wed';

  @override
  String get dayThu => 'Thu';

  @override
  String get dayFri => 'Fri';

  @override
  String get daySat => 'Sat';

  @override
  String get daySundayFull => 'Sunday';

  @override
  String get dayMondayFull => 'Monday';

  @override
  String get dayTuesdayFull => 'Tuesday';

  @override
  String get dayWednesdayFull => 'Wednesday';

  @override
  String get dayThursdayFull => 'Thursday';

  @override
  String get dayFridayFull => 'Friday';

  @override
  String get daySaturdayFull => 'Saturday';

  @override
  String get daySingleS => 'S';

  @override
  String get daySingleM => 'M';

  @override
  String get daySingleT => 'T';

  @override
  String get daySingleW => 'W';

  @override
  String get daySingleF => 'F';

  @override
  String get alarmFormSetTime => 'Set Time';

  @override
  String get alarmFormDone => 'Done';

  @override
  String get alarmFormEditAlarm => 'Edit Alarm';

  @override
  String get alarmFormNewAlarm => 'New Alarm';

  @override
  String get alarmFormAlarmName => 'Alarm name';

  @override
  String get alarmFormAlarmTime => 'Alarm Time';

  @override
  String get alarmFormScheduled => '↻  Scheduled';

  @override
  String get alarmFormOneTime => '📅  One-time';

  @override
  String get alarmFormRepeatOn => 'Repeat on:';

  @override
  String alarmFormAddMission(int count) {
    return 'Add Mission ($count of 3)';
  }

  @override
  String get alarmFormStackMissions =>
      'Stack missions & complete to turn off alarm';

  @override
  String get alarmFormSound => 'Sound';

  @override
  String get alarmFormUpdateAlarm => 'Update Alarm';

  @override
  String get alarmFormSaveAlarm => 'Save Alarm';

  @override
  String alarmFormMissionIndex(int index) {
    return 'Mission $index';
  }

  @override
  String get soundPickerTitle => 'Alarm Sound';

  @override
  String get soundPickerYourSounds => 'Your Sounds';

  @override
  String get soundPickerUpload => 'Upload Sound';

  @override
  String get soundPickerSelect => 'Select Sound';

  @override
  String get soundPickerNew => 'NEW';

  @override
  String get soundPickerCredit => '1 credit';

  @override
  String get soundDefault => 'Default';

  @override
  String get soundClock2 => 'Clock 2';

  @override
  String get soundClock3 => 'Clock 3';

  @override
  String get soundClock4 => 'Clock 4';

  @override
  String get soundFunny => 'Funny';

  @override
  String get soundCelestial => 'Celestial';

  @override
  String get soundChiptune => 'Chiptune';

  @override
  String get soundDreamscape => 'Dreamscape';

  @override
  String get soundGame => 'Game';

  @override
  String get soundGame2 => 'Game 2';

  @override
  String get soundOversimplified => 'Oversimplified';

  @override
  String get soundSmooth => 'Smooth';

  @override
  String get soundAcoustic => 'Acoustic';

  @override
  String get soundComing => 'Coming';

  @override
  String get soundCyber => 'Cyber';

  @override
  String get soundDetermination => 'Determination';

  @override
  String get soundDubstep => 'Dubstep';

  @override
  String get soundHiphop => 'Hiphop';

  @override
  String get soundPiano => 'Piano';

  @override
  String get soundTropical => 'Tropical';

  @override
  String get soundRingstone1 => 'Ringstone 1';

  @override
  String get soundRingstone2 => 'Ringstone 2';

  @override
  String get soundRingstone3 => 'Ringstone 3';

  @override
  String get soundAlarm => 'Alarm';

  @override
  String get soundHardcore => 'Hardcore';

  @override
  String get soundCategoryClock => 'Clock';

  @override
  String get soundCategoryGentle => 'Gentle';

  @override
  String get soundCategoryMusical => 'Musical';

  @override
  String get soundCategoryRingstone => 'Ringstone';

  @override
  String get soundCategoryViolent => 'Violent';

  @override
  String get homeNextWakeUp => 'Next Wake Up';

  @override
  String get homeTodaysWakeup => 'Today\'s Wakeup';

  @override
  String get homeSeeAll => 'See All';

  @override
  String get homeNoActiveAlarm => 'No active alarm';

  @override
  String get homeNoActiveAlarmHint => 'Tap to create one with a mission';

  @override
  String get homeToday => 'Today';

  @override
  String get homeTomorrow => 'Tomorrow';

  @override
  String get homePastAlarm => 'Past alarm';

  @override
  String homeRingsIn(int hours, int minutes) {
    return 'Rings in ${hours}h ${minutes}m';
  }

  @override
  String get homeMission => 'Mission';

  @override
  String get homeSound => 'Sound';

  @override
  String get homeNoWakeupsYet => 'No wakeups yet';

  @override
  String get homeSetAlarmToStart => 'Set an alarm to get started';

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Aug';

  @override
  String get monthSep => 'Sep';

  @override
  String get monthOct => 'Oct';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dec';

  @override
  String get missionPushUps => 'Push Ups';

  @override
  String get missionPushUpsDesc => 'Video yourself doing push-ups';

  @override
  String get missionSquats => 'Squats';

  @override
  String get missionSquatsDesc => 'Video yourself doing squats';

  @override
  String get missionShakePhone => 'Shake Phone';

  @override
  String get missionShakePhoneDesc => 'Shake your phone to wake up';

  @override
  String get missionMath => 'Math';

  @override
  String get missionMathDesc => 'Solve math problems to wake up';

  @override
  String get missionSkyPhoto => 'Sky Photo';

  @override
  String get missionSkyPhotoDesc => 'Take a photo of the sky';

  @override
  String get missionMakeBed => 'Make Bed';

  @override
  String get missionMakeBedDesc => 'Take a photo of your made bed';

  @override
  String get missionObjectHunt => 'Object Hunt';

  @override
  String get missionObjectHuntDesc => 'Find and photograph a household object';

  @override
  String get missionPetHunt => 'Pet Hunt';

  @override
  String get missionPetHuntDesc => 'Find and photograph your pet';

  @override
  String get missionNatureHunt => 'Nature Hunt';

  @override
  String get missionNatureHuntDesc => 'Find and photograph something in nature';

  @override
  String get missionTouchGrass => 'Touch Grass';

  @override
  String get missionTouchGrassDesc => 'Take a photo of the grass';

  @override
  String get missionAffirmation => 'Affirmation';

  @override
  String get missionAffirmationDesc => 'Read an affirmation out loud';

  @override
  String get missionRandom => 'Random';

  @override
  String get missionRandomDesc => 'Surprise mission each morning';

  @override
  String get missionNone => 'No mission';

  @override
  String get missionNoneDesc => 'Simple alarm with no task';

  @override
  String get photoTargetSky => 'the sky';

  @override
  String get photoTargetMadeBed => 'your made bed';

  @override
  String get photoTargetGrass => 'grass';

  @override
  String get missionPickerTitle => 'Choose Mission';

  @override
  String get missionPickerAll => 'All';

  @override
  String get missionPickerTrending => 'Trending';

  @override
  String get missionPickerHunts => 'Hunts';

  @override
  String get missionPickerPhysical => 'Physical';

  @override
  String get missionPickerPreview => 'Preview';

  @override
  String get missionConfigNumberOfShakes => 'Number of shakes';

  @override
  String get missionConfigNumberOfReps => 'Number of reps';

  @override
  String get missionConfigNumberOfProblems => 'Number of problems';

  @override
  String get missionConfigDifficulty => 'Difficulty';

  @override
  String get missionConfigEasy => 'Easy';

  @override
  String get missionConfigMedium => 'Medium';

  @override
  String get missionConfigHard => 'Hard';

  @override
  String get missionConfigChoose => 'Choose This Mission';

  @override
  String get missionConfigNumberOfAffirmations => 'Number of affirmations';

  @override
  String get itemPickerSelectItems => 'Select Items';

  @override
  String get itemPickerRandomItem =>
      'A random item will be chosen each morning';

  @override
  String get itemPickerHouseholdItems => 'Household Items';

  @override
  String get itemPickerFunItems => 'Fun Items';

  @override
  String get itemPickerSelectPets => 'Select Your Pets';

  @override
  String get itemPickerPetsSubtitle => 'Select which pets you have at home';

  @override
  String get itemPickerSelectNature => 'Select Nature Items';

  @override
  String get itemPickerNatureSubtitle =>
      'A random nature item will be chosen each morning';

  @override
  String itemPickerSelected(int count) {
    return '$count selected';
  }

  @override
  String get itemPickerSelectAll => 'Select All';

  @override
  String get itemPickerDeselectAll => 'Deselect All';

  @override
  String get itemPickerAddOwn => 'Add your own item';

  @override
  String get itemPickerDone => 'Done';

  @override
  String get itemPickerCustomItems => 'Custom Items';

  @override
  String get affirmationPickerCustom => 'Custom';

  @override
  String get itemToothbrush => 'Toothbrush';

  @override
  String get itemRunningFaucet => 'Running Faucet';

  @override
  String get itemShoes => 'Shoes';

  @override
  String get itemFridge => 'Fridge';

  @override
  String get itemKeys => 'Keys';

  @override
  String get itemCoffeeMug => 'Coffee Mug';

  @override
  String get itemMirror => 'Mirror';

  @override
  String get itemWaterBottle => 'Water Bottle';

  @override
  String get itemDustpan => 'Dustpan';

  @override
  String get itemToilet => 'Toilet';

  @override
  String get itemBook => 'Book';

  @override
  String get itemLamp => 'Lamp';

  @override
  String get itemTvRemote => 'TV Remote';

  @override
  String get itemFrontDoor => 'Front Door';

  @override
  String get itemStove => 'Stove';

  @override
  String get itemLotionBottle => 'Lotion Bottle';

  @override
  String get itemSoap => 'Soap';

  @override
  String get itemPlant => 'Plant';

  @override
  String get itemPlate => 'Plate';

  @override
  String get itemTowel => 'Towel';

  @override
  String get itemBackpack => 'Backpack';

  @override
  String get itemHeadphones => 'Headphones';

  @override
  String get itemShower => 'Shower';

  @override
  String get itemTape => 'Tape';

  @override
  String get itemKimKardashian => 'Kim Kardashian';

  @override
  String get itemSnoopDogg => 'Snoop Dogg';

  @override
  String get itemRubberDuck => 'Rubber Duck';

  @override
  String get itemBanana => 'Banana';

  @override
  String get itemPickle => 'Pickle';

  @override
  String get itemCroc => 'Croc';

  @override
  String get itemLavaLamp => 'Lava Lamp';

  @override
  String get itemPingPongPaddle => 'Ping Pong Paddle';

  @override
  String get itemEgg => 'Egg';

  @override
  String get petDog => 'Dog';

  @override
  String get petCat => 'Cat';

  @override
  String get petBird => 'Bird';

  @override
  String get petFish => 'Fish';

  @override
  String get petHamster => 'Hamster';

  @override
  String get petRabbit => 'Rabbit';

  @override
  String get petTurtle => 'Turtle';

  @override
  String get petGuineaPig => 'Guinea Pig';

  @override
  String get petLizard => 'Lizard';

  @override
  String get petSnake => 'Snake';

  @override
  String get natureTree => 'Tree';

  @override
  String get natureFlower => 'Flower';

  @override
  String get natureRock => 'Rock';

  @override
  String get natureLeaf => 'Leaf';

  @override
  String get natureGrass => 'Grass';

  @override
  String get natureBush => 'Bush';

  @override
  String get natureStick => 'Stick';

  @override
  String get naturePinecone => 'Pinecone';

  @override
  String get affirmationPickerTitle => 'Select Affirmations';

  @override
  String affirmationPickerSelected(int count) {
    return '$count selected';
  }

  @override
  String get affirmationPickerSelectAll => 'Select All';

  @override
  String get affirmationPickerDeselectAll => 'Deselect All';

  @override
  String get affirmationPickerAddOwn => 'Add your own affirmation';

  @override
  String get affirmationPickerDone => 'Done';

  @override
  String get randomPoolTitle => 'Random Pool';

  @override
  String get randomPoolSubtitle =>
      'Select missions to include in random rotation';

  @override
  String randomPoolSelected(int count) {
    return '$count selected';
  }

  @override
  String get randomPoolSelectAll => 'Select All';

  @override
  String get randomPoolDeselectAll => 'Deselect All';

  @override
  String get randomPoolDone => 'Done';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAnonymousUser => 'Anonymous User';

  @override
  String settingsAccountType(String type) {
    return 'Account type: $type';
  }

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsUserType => 'User Type';

  @override
  String get settingsEnterReferralCode => 'Enter Referral Code';

  @override
  String get settingsApp => 'App';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsDarkMode => 'Dark Mode';

  @override
  String get settingsAlarmDuringMission => 'Alarm During Mission';

  @override
  String get settingsDefaultSound => 'Default Sound';

  @override
  String get settingsDefaultMission => 'Default Mission';

  @override
  String get settingsNone => 'None';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsTermsOfService => 'Terms of Service';

  @override
  String get settingsAdmin => 'Admin (debug only)';

  @override
  String get settingsPrintAllAlarms => 'Print All Alarms';

  @override
  String get settingsPrintSharedPreferences => 'Print SharedPreferences';

  @override
  String get settingsDeleteAllAlarms => 'Delete All Alarms';

  @override
  String get settingsLogout => 'Log out';

  @override
  String get settingsLogoutTitle => 'Log out?';

  @override
  String get settingsLogoutBody =>
      'You\'ll be signed out of this device. Local settings and scheduled alarms will be cleared.';

  @override
  String get settingsLogoutConfirm => 'Log out';

  @override
  String get settingsLogoutCancel => 'Cancel';

  @override
  String get settingsVersion => 'Levio v0.1.0';

  @override
  String get referralTitle => 'Enter Referral Code';

  @override
  String get referralCodeLabel => 'Referral Code';

  @override
  String referralApplied(String type) {
    return 'Referral code applied! You are now: $type';
  }

  @override
  String get referralInvalid => 'Invalid referral code';

  @override
  String get referralUsageLimit => 'This code has reached its usage limit';

  @override
  String get referralError => 'Something went wrong, please try again';

  @override
  String get referralCancel => 'Cancel';

  @override
  String get referralSubmit => 'Submit';

  @override
  String get insightsTitle => 'Insights';

  @override
  String get insightsStats => 'Stats';

  @override
  String get insightsAvgWakeTime => 'Avg Wake Time';

  @override
  String get insightsAvgResponse => 'Avg Response';

  @override
  String get insightsFavoriteMission => 'Favorite Mission';

  @override
  String get insightsFavoriteSound => 'Favorite Sound';

  @override
  String get insightsWeek => 'Week';

  @override
  String get insightsMonth => 'Month';

  @override
  String get insightsAllTime => 'All Time';

  @override
  String get insightsDayStreak => 'Day Streak';

  @override
  String get insightsBadgesEarned => 'Badges Earned';

  @override
  String get insightsConsistency => 'Consistency';

  @override
  String get insightsNeed3Wakeups => 'Need 3+ wake ups';

  @override
  String get insightsConsistencyVariable => 'Variable';

  @override
  String get insightsConsistencyImproving => 'Improving';

  @override
  String get insightsConsistencyRegular => 'Regular';

  @override
  String get insightsConsistencyConsistent => 'Consistent';

  @override
  String get insightsConsistencyScoreTitle => 'Consistency Score';

  @override
  String get insightsConsistencyScoreBody =>
      'Your consistency score measures how regularly you wake up with Levio. It improves as your streak grows.';

  @override
  String get insightsOk => 'OK';

  @override
  String get milestonesTitle => 'Milestones';

  @override
  String get milestonesDayStreak => 'Day Streak';

  @override
  String milestonesLongestStreak(int count) {
    return '$count day';
  }

  @override
  String get milestonesLongestStreakLabel => 'longest streak';

  @override
  String get milestonesStreakBadges => 'Streak Badges';

  @override
  String get milestonesAchievementBadges => 'Achievement Badges';

  @override
  String get milestonesBadgesEarned => 'Badges Earned';

  @override
  String milestonesBadgeCount(int earned, int total) {
    return '$earned/$total badges';
  }

  @override
  String get milestonesHowStreaksWork => 'How Streaks Work';

  @override
  String get milestonesStreakExplanation =>
      'Wake up with Levio daily to build your streak. You get 2 freeze days per week to skip without losing progress. If you miss a day without a freeze, your streak drops by 3 instead of resetting to zero.';

  @override
  String get badgeRisen => 'Risen';

  @override
  String get badgeRisenReq => '1 day';

  @override
  String get badgeRisenQuote =>
      'The journey of a thousand mornings begins with one alarm.';

  @override
  String get badgeIgnite => 'Ignite';

  @override
  String get badgeIgniteReq => '3 days';

  @override
  String get badgeIgniteQuote => 'Three days in. The flame is growing.';

  @override
  String get badgeHorizon => 'Horizon';

  @override
  String get badgeHorizonReq => '7 days';

  @override
  String get badgeHorizonQuote =>
      'A week of mornings — you\'re rewriting your story.';

  @override
  String get badgeAurora => 'Aurora';

  @override
  String get badgeAuroraReq => '14 days';

  @override
  String get badgeAuroraQuote =>
      'Two weeks of sunrise. Keep chasing the light.';

  @override
  String get badgeCelestial => 'Celestial';

  @override
  String get badgeCelestialReq => '30 days';

  @override
  String get badgeCelestialQuote =>
      'A full month of rising. You are unstoppable.';

  @override
  String get badgeNebula => 'Nebula';

  @override
  String get badgeNebulaReq => '100 days';

  @override
  String get badgeNebulaQuote =>
      'One hundred mornings. A new you has been born.';

  @override
  String get badgeEternal => 'Eternal';

  @override
  String get badgeEternalReq => '365 days';

  @override
  String get badgeEternalQuote => 'A full year of mornings. You are legendary.';

  @override
  String get badgeVersatile => 'Versatile';

  @override
  String get badgeVersatileReq => 'Use all 13 mission types';

  @override
  String get badgeVersatileQuote => 'Mastery comes from variety.';

  @override
  String get badgeFirstLight => 'First Light';

  @override
  String get badgeFirstLightReq => 'Wake up before 5:30 AM';

  @override
  String get badgeFirstLightQuote => 'The early bird catches the sunrise.';

  @override
  String get badgeBlitz => 'Blitz';

  @override
  String get badgeBlitzReq => 'Turn off alarm in under 15s';

  @override
  String get badgeBlitzQuote => 'Speed of light. Speed of life.';

  @override
  String get badgeNoDaysOff => 'No Days Off';

  @override
  String get badgeNoDaysOffReq => '30 consecutive wakeups';

  @override
  String get badgeNoDaysOffQuote => 'Weekends are just weekdays in disguise.';

  @override
  String get badgeConverted => 'Converted';

  @override
  String get badgeConvertedReq => 'Reach a 7-day streak';

  @override
  String get badgeConvertedQuote =>
      'Even night owls can learn to love the dawn.';

  @override
  String get badgeAudiophile => 'Audiophile';

  @override
  String get badgeAudiophileReq => 'Use 4+ different alarm sounds';

  @override
  String get badgeAudiophileQuote =>
      'Every morning deserves its own soundtrack.';

  @override
  String get wakeupTitle => 'Today\'s Wakeup';

  @override
  String get wakeupStartMyDay => 'Start My Day';

  @override
  String get wakeupCongratulations => 'Congratulations.';

  @override
  String get wakeupThanks => 'Thanks to Levio, you woke up today.';

  @override
  String get wakeupTimeTaken => 'Time Taken';

  @override
  String get wakeupDayStreak => 'Day Streak';

  @override
  String get wakeupWakeups => 'Wakeups';

  @override
  String get wakeupDailyQuote => 'Daily Quote';

  @override
  String get wakeupContinue => 'Continue';

  @override
  String get wakeupWakeUp => 'Wake Up';

  @override
  String get sessionsTitle => 'All Wakeups';

  @override
  String get sessionsNoWakeups => 'No wakeups yet';

  @override
  String get sessionsMissed => 'Missed';

  @override
  String get quoteEinstein =>
      'In the middle of every difficulty lies opportunity.';

  @override
  String get quoteEinsteinAuthor => 'Albert Einstein';

  @override
  String get quoteTwain => 'The secret of getting ahead is getting started.';

  @override
  String get quoteTwainAuthor => 'Mark Twain';

  @override
  String get quoteConfucius =>
      'It does not matter how slowly you go as long as you do not stop.';

  @override
  String get quoteConfuciusAuthor => 'Confucius';

  @override
  String get quoteChurchill => 'Success is not final, failure is not fatal.';

  @override
  String get quoteChurchillAuthor => 'Winston Churchill';

  @override
  String get quoteRoosevelt => 'Believe you can and you\'re halfway there.';

  @override
  String get quoteRooseveltAuthor => 'Theodore Roosevelt';

  @override
  String get quoteJobs =>
      'The only way to do great work is to love what you do.';

  @override
  String get quoteJobsAuthor => 'Steve Jobs';

  @override
  String get quoteUnknown =>
      'Wake up with determination, go to bed with satisfaction.';

  @override
  String get quoteUnknownAuthor => 'Unknown';

  @override
  String get quoteBuddha =>
      'Every morning we are born again. What we do today matters most.';

  @override
  String get quoteBuddhaAuthor => 'Buddha';

  @override
  String get dismissStopAlarm => 'Stop Alarm';

  @override
  String get dismissShakePrompt => 'Shake your phone to stop the alarm';

  @override
  String dismissMathProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String get dismissMathWrong => 'Wrong — try again!';

  @override
  String get dismissMathConfirm => 'Confirm';

  @override
  String dismissPhotoPrompt(String target) {
    return 'Take a photo of $target to stop the alarm';
  }

  @override
  String dismissPhotoChecking(String target) {
    return 'Checking for $target…';
  }

  @override
  String get dismissPhotoStarting => 'Starting camera…';

  @override
  String dismissPhotoNotDetected(String target) {
    return 'No $target detected — try again';
  }

  @override
  String dismissPhotoError(String error) {
    return 'Error: $error';
  }

  @override
  String get dismissPhotoTakePhoto => 'TAKE A PHOTO OF';

  @override
  String get dismissSpeechSay => 'Say:';

  @override
  String get dismissSpeechListening => 'Listening…';

  @override
  String get dismissSpeechTapToSpeak => 'Tap to speak';

  @override
  String dismissSpeechTryAgain(int score) {
    return '$score% — try again';
  }

  @override
  String get dismissSpeechMicUnavailable => 'Microphone unavailable';

  @override
  String dismissSpeechProgress(int current, int total) {
    return '$current/$total';
  }

  @override
  String get dismissRepStarting => 'Starting camera…';

  @override
  String dismissRepPrompt(int target, String mission) {
    return 'Do $target $mission to stop the alarm';
  }

  @override
  String dismissRepOf(int target) {
    return 'of $target';
  }

  @override
  String get dismissMissionTimeToWakeUp => 'Time to Wake Up!';

  @override
  String dismissMissionLabel(int current, int total, String name) {
    return 'Mission $current/$total: $name';
  }

  @override
  String get dismissStartMission => 'Start Mission';

  @override
  String get dismissFeedbackMoveIntoFrame => 'Move your whole body into frame';

  @override
  String get dismissFeedbackKeepGoing => 'Yes, keep going!';

  @override
  String get dismissFeedbackPushupPosition => 'Lie down in push-up position';

  @override
  String get dismissFeedbackStartPushups => 'Start doing your push-ups!';

  @override
  String get dismissFeedbackPushupGoDeeper =>
      'Go deeper, your chest should touch the ground!';

  @override
  String get dismissFeedbackSquatPosition => 'Stand up to start squats';

  @override
  String get dismissFeedbackStartSquats => 'Start doing your squats!';

  @override
  String get dismissFeedbackSquatGoDeeper =>
      'Go deeper, your thighs should be parallel to the ground!';

  @override
  String get onboardingMorningPerson => 'Do you feel like a morning person?';

  @override
  String get onboardingYes => 'Yes';

  @override
  String get onboardingNotYet => 'Not yet';

  @override
  String get onboardingAgeRange => 'What\'s your age range?';

  @override
  String get onboardingDescribesYou => 'What best describes you?';

  @override
  String get onboardingMale => 'Male';

  @override
  String get onboardingFemale => 'Female';

  @override
  String get onboardingOther => 'Other';

  @override
  String get onboardingKeepsInBed => 'What keeps you in bed after the alarm?';

  @override
  String get onboardingPhoneScrolling => 'Phone scrolling';

  @override
  String get onboardingSnoozeLoop => 'Snooze loop';

  @override
  String get onboardingSleepThrough => 'Sleep through alarms';

  @override
  String get onboardingStayInBed => 'I wake up but stay in bed';

  @override
  String get onboardingFirstThought => 'First thought when the alarm goes off?';

  @override
  String get onboardingImUp => 'I\'m up';

  @override
  String get onboardingFiveMore => 'Just 5 more minutes';

  @override
  String get onboardingSetAnother => 'I\'ll set another alarm';

  @override
  String get onboardingWhyDidI => 'Why did I do this?';

  @override
  String get onboardingGetsYouOut => 'Levio gets you out of bed';

  @override
  String get onboardingAvoidGroggy =>
      'Avoid the \'groggy zone\'. Levio launches you straight into alertness.';

  @override
  String get onboardingHowManyAlarms => 'How many alarms do you set?';

  @override
  String get onboardingOne => 'One';

  @override
  String get onboardingTwoThree => '2-3';

  @override
  String get onboardingFourPlus => '4+';

  @override
  String get onboardingOneAlarmWakeUp =>
      'If you set one alarm, would you wake up?';

  @override
  String get onboardingSometimes => 'Sometimes';

  @override
  String get onboardingNo => 'No';

  @override
  String get onboardingTurnOffGoBack =>
      'Do you ever turn off the alarm and go back to sleep?';

  @override
  String get onboardingOften => 'Often';

  @override
  String get onboardingRarely => 'Rarely';

  @override
  String get onboardingNever => 'Never';

  @override
  String get onboardingOneAlarmOneMission => 'One alarm. One mission.';

  @override
  String get onboardingFeelSettingAlarm =>
      'How do you feel setting your alarm at night?';

  @override
  String get onboardingMotivated => 'Motivated';

  @override
  String get onboardingAnxiousSleep => 'Anxious about sleep';

  @override
  String get onboardingDefeated => 'Defeated';

  @override
  String get onboardingNeutral => 'Neutral';

  @override
  String get onboardingFeelAfterWaking =>
      'How do you feel right after waking up?';

  @override
  String get onboardingReadyToGo => 'Ready to go';

  @override
  String get onboardingGroggy => 'Groggy';

  @override
  String get onboardingAnxiousStressed => 'Anxious or stressed';

  @override
  String get onboardingHowLongAwake => 'How long until you feel fully awake?';

  @override
  String get onboardingInstantly => 'Instantly';

  @override
  String get onboardingTenFifteen => '10-15 minutes';

  @override
  String get onboardingThirtyPlus => '30 minutes or more';

  @override
  String get onboardingBiologyTitle => 'Biology, Not Laziness';

  @override
  String get onboardingBiologyBody =>
      'Your brain takes 15–30 min to clear sleep inertia. Snoozing resets the cycle, making it worse.\n\nLevio forces immediate action — skipping the groggy zone entirely.';

  @override
  String get onboarding5xFaster =>
      'Get out of bed 5x faster with Levio vs on your own';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String onboardingSetAlarmFor(String time) {
    return 'Set alarm for $time';
  }

  @override
  String get onboardingAlarmDuringMission =>
      'Play your alarm during the mission?';

  @override
  String get onboardingAlarmKeepRinging =>
      'Keep alarm ringing while completing the mission.';

  @override
  String get onboardingAlarmStopRinging =>
      'Stop alarm ringing unless I leave the app during the mission.';

  @override
  String get onboardingWhereHeard => 'Where did you hear about us?';

  @override
  String get onboardingYouTube => 'YouTube';

  @override
  String get onboardingFacebook => 'Facebook';

  @override
  String get onboardingTwitter => 'Twitter';

  @override
  String get onboardingReddit => 'Reddit';

  @override
  String get onboardingAppStore => 'App Store';

  @override
  String get onboardingFriendFamily => 'Friend or family';

  @override
  String get onboardingWelcomeTitle =>
      'Stop hitting snooze.\nStart winning mornings.';

  @override
  String get onboardingWelcomeSubtitle => 'One alarm. One mission. You\'re up.';

  @override
  String get onboardingBuildPlan => 'Build my plan';

  @override
  String get onboardingJoin500k => 'Join 500k+ people waking up with Levio';

  @override
  String get onboardingAlreadyAccount => 'Already have an account? ';

  @override
  String get onboardingSignIn => 'Sign in';

  @override
  String get onboardingSignInApple => 'Sign in with Apple';

  @override
  String get onboardingSignInGoogle => 'Continue with Google';

  @override
  String get onboardingSkipForNow => 'Skip for now';

  @override
  String get onboardingGoogleFailed =>
      'Google sign-in failed. Please try again.';

  @override
  String get onboardingAppleFailed => 'Apple sign-in failed. Please try again.';

  @override
  String get onboardingDayPickerTitle => 'Which days should Levio ring?';

  @override
  String get onboardingDayPickerSubtitle =>
      'Pick the days you want to lock in.';

  @override
  String get onboardingLoadingTitle => 'Setting everything up\nfor you';

  @override
  String get onboardingLoadingStep1 => 'Analyzing your sleep habits';

  @override
  String get onboardingLoadingStep2 => 'Configuring your goals';

  @override
  String get onboardingLoadingStep3 => 'Setting your mission';

  @override
  String get onboardingLoadingStep4 => 'Calibrating alarm tone';

  @override
  String get onboardingLoadingStep5 => 'Scheduling your alarm';

  @override
  String get onboardingLoadingStep6 => 'Finalizing your plan';

  @override
  String get onboardingMissionPickerTitle => 'Choose your wake up mission';

  @override
  String get onboardingMissionPickerSubtitle =>
      'You\'ll do this to turn off your alarm.';

  @override
  String get onboardingMorningPlanTitle => 'Your Morning Plan';

  @override
  String onboardingMorningPlanSubtitle(String time) {
    return 'Here\'s what tomorrow looks like at $time';
  }

  @override
  String onboardingStartsIn(String countdown) {
    return 'Starts in $countdown';
  }

  @override
  String get onboardingHeresTomorrow => 'HERE\'S TOMORROW';

  @override
  String onboardingAlarmRings(String time) {
    return '$time — Alarm rings';
  }

  @override
  String onboardingCompleteMission(String mission) {
    return 'Complete $mission';
  }

  @override
  String get onboardingYoureUp => 'You\'re up. Day started.';

  @override
  String get onboardingNoSnooze =>
      'No snooze loops. One action, then your day starts with momentum.';

  @override
  String get onboardingWakeReceipt => 'Wake Receipt\n(Image placeholder)';

  @override
  String get onboardingRiseAndRepeat => 'Rise and repeat.';

  @override
  String onboardingAlarmFrequency(int count) {
    return 'Your alarm fires ${count}x a week. Build the streak.';
  }

  @override
  String get onboardingNotificationTitle => 'Stay on track with reminders';

  @override
  String get onboardingNotificationSubtitle =>
      'We\'ll send a gentle nudge so you never miss your wake-up time.';

  @override
  String get onboardingNotificationEnable => 'Enable';

  @override
  String get onboardingNotificationNotNow => 'Not now';

  @override
  String get onboardingPaywallTitle => 'We want you to\ntry Levio for free.';

  @override
  String get onboardingPaywallSecondsRemaining => 'seconds remaining';

  @override
  String get onboardingPaywallKeepGoing => 'Keep going! Do your push ups';

  @override
  String get onboardingPaywallNoPayment => 'No Payment Due Now';

  @override
  String get onboardingPaywallTryFree => 'Try For \$0.00';

  @override
  String get onboardingPaywallNoCommitment => 'No commitment, cancel anytime.';

  @override
  String get onboardingPaywallPrivacy => 'Privacy Policy';

  @override
  String get onboardingPaywallRestore => 'Restore Purchase';

  @override
  String get onboardingPaywallTerms => 'Terms of Use';

  @override
  String get onboardingRatingTitle => 'Give us a rating';

  @override
  String get onboardingRatingSubtitle => 'Levio was made for\npeople like you';

  @override
  String get onboardingRatingMarc => 'Marc L.';

  @override
  String get onboardingRatingMarcReview =>
      'I used to set 5 alarms every morning. Now I wake up on the first one and actually feel good about it.';

  @override
  String get onboardingRatingSophie => 'Sophie D.';

  @override
  String get onboardingRatingSophieReview =>
      'The mission feature is brilliant. Doing push-ups at 6am sounds crazy, but it genuinely wakes me up faster than coffee.';

  @override
  String get onboardingRatingAlex => 'Alex T.';

  @override
  String get onboardingRatingAlexReview =>
      'Finally an alarm app that actually works. I\'ve tried everything and Levio is the only one that gets me out of bed.';

  @override
  String get onboardingReferralTitle => 'Enter referral code\n(optional)';

  @override
  String get onboardingReferralSubtitle => 'You can skip this step';

  @override
  String get onboardingReferralLabel => 'Referral Code';

  @override
  String get onboardingReferralSubmit => 'Submit';

  @override
  String get onboardingReferralApplied => 'Referral code applied!';

  @override
  String get onboardingReferralInvalid => 'Invalid referral code';

  @override
  String get onboardingReferralLimit => 'This code has reached its usage limit';

  @override
  String get onboardingSignatureTitle => 'Lock in your\ncommitment';

  @override
  String onboardingSignatureSubtitle(String time) {
    return 'Sign below to get out of bed at $time. Feet on the floor.';
  }

  @override
  String get onboardingSignatureCommit => 'I Commit';

  @override
  String get onboardingTimePickerTitle => 'Set your first Levio time';

  @override
  String onboardingTimePickerSubtitle(String time) {
    return 'We\'ll wake you at $time with your mission.';
  }

  @override
  String get onboardingSoundPickerTitle => 'Pick your alarm sound';

  @override
  String get onboardingTimelineTypical => 'TYPICAL MORNING';

  @override
  String get onboardingTimelineLevio => 'LEVIO MORNING';

  @override
  String get onboardingTimelineAlarm => 'Alarm';

  @override
  String get onboardingTimelineSnooze => 'Snooze';

  @override
  String get onboardingTimelinePanic => 'Panic';

  @override
  String get onboardingTimelineMission => 'Mission';

  @override
  String get onboardingTimelineStarted => 'Started';

  @override
  String get onboardingTimelineGained => 'GAINED';

  @override
  String get onboardingTimelineMins => '25 MINS';

  @override
  String get onboardingTrialTitle =>
      'We\'ll send you\na reminder before\nyour free trial ends';

  @override
  String get onboardingTrialNoPayment => 'No Payment Due Now';

  @override
  String get onboardingTrialContinueFree => 'Continue For Free';

  @override
  String get onboardingTrialPrice => 'Just \$29.99 per year (\$2.50/mo)';

  @override
  String get onboardingEnergyTitle => 'Morning Energy Levels';

  @override
  String get onboardingEnergyLevio => 'Levio Protocol';

  @override
  String get onboardingEnergySnoozeCycle => 'Snooze Cycle';

  @override
  String get onboardingEnergyGroggyZone => 'GROGGY ZONE';

  @override
  String get onboardingSpeedometerSlow => 'Slow';

  @override
  String get onboardingSpeedometerGroggy => 'Groggy';

  @override
  String get onboardingSpeedometerInstant => 'Instant';

  @override
  String get onboardingSpeedometerActive => 'Active';

  @override
  String get onboardingSpeedometerBody =>
      'Levio eliminates snooze friction for\ninstant wake ups.';

  @override
  String get onboardingSpeedometerFaster => 'FASTER';

  @override
  String get onboardingSpeedometerMultiplier => '5.0x';

  @override
  String get missionExplPushUpsTitle => 'Why doing push ups wakes you up';

  @override
  String get missionExplPushUpsSubtitle => 'Gets your blood pumping right away';

  @override
  String get missionExplPushUpsBody =>
      'Push-ups activate your chest, arms, and core — flooding your brain with oxygen and spiking your heart rate. Within seconds, your body shifts from sleep mode to fully alert. It\'s the fastest way to kill morning grogginess.';

  @override
  String get missionExplSquatsTitle => 'Why doing squats wakes you up';

  @override
  String get missionExplSquatsSubtitle => 'Activates your largest muscles';

  @override
  String get missionExplSquatsBody =>
      'Squats fire up your glutes, quads, and hamstrings — the biggest muscle groups in your body. This triggers a rush of blood flow and raises your core temperature fast. Your brain gets the signal: it\'s go time.';

  @override
  String get missionExplShakeTitle => 'Why shaking your phone wakes you up';

  @override
  String get missionExplShakeSubtitle => 'Forces you to move';

  @override
  String get missionExplShakeBody =>
      'Shaking your phone forces arm movement and coordination, pulling your brain out of autopilot. The repetitive motion activates your motor cortex and gets your blood circulating — turning a groggy moment into physical engagement.';

  @override
  String get missionExplMathTitle => 'Why solving math wakes you up';

  @override
  String get missionExplMathSubtitle => 'Wakes up your brain';

  @override
  String get missionExplMathBody =>
      'Math problems force your prefrontal cortex to engage — the part of your brain responsible for logic and decision-making. Even simple arithmetic snaps you out of sleep inertia by demanding focused, conscious thought.';

  @override
  String get missionExplSkyPhotoTitle => 'Why taking a sky photo wakes you up';

  @override
  String get missionExplSkyPhotoSubtitle => 'Gets you to the window';

  @override
  String get missionExplSkyPhotoBody =>
      'Walking to a window and looking at the sky exposes you to natural light — the most powerful signal to shut down melatonin production. Even on cloudy days, outdoor light intensity is far greater than indoor lighting, resetting your circadian clock fast.';

  @override
  String get missionExplMakeBedTitle => 'Why making your bed wakes you up';

  @override
  String get missionExplMakeBedSubtitle => 'Starts your day with a win';

  @override
  String get missionExplMakeBedBody =>
      'Making your bed is a micro-accomplishment that triggers a small dopamine hit. It signals to your brain that the day has started and removes the temptation to climb back in. One completed task creates momentum for the next.';

  @override
  String get missionExplObjectHuntTitle => 'Why an object hunt wakes you up';

  @override
  String get missionExplObjectHuntSubtitle => 'Gets you out of bed';

  @override
  String get missionExplObjectHuntBody =>
      'Searching for a specific object forces you out of bed and into motion. Your brain switches from passive rest to active problem-solving — scanning, recognizing, and moving. By the time you find it, sleep inertia is gone.';

  @override
  String get missionExplPetHuntTitle => 'Why finding your pet wakes you up';

  @override
  String get missionExplPetHuntSubtitle => 'Morning bonding time';

  @override
  String get missionExplPetHuntBody =>
      'Interacting with your pet releases oxytocin — the bonding hormone that naturally elevates your mood and alertness. Moving through your home to find them adds physical activity, while the emotional connection gives your morning a positive anchor.';

  @override
  String get missionExplNatureHuntTitle => 'Why a nature hunt wakes you up';

  @override
  String get missionExplNatureHuntSubtitle => 'Connects you to the outdoors';

  @override
  String get missionExplNatureHuntBody =>
      'Stepping outside to find something in nature combines movement, fresh air, and natural light — the three most effective wake-up signals. The sensory shift from bedroom to outdoors jolts your nervous system into full alertness.';

  @override
  String get missionExplTouchGrassTitle => 'Why touching grass wakes you up';

  @override
  String get missionExplTouchGrassSubtitle => 'Ground yourself in the morning';

  @override
  String get missionExplTouchGrassBody =>
      'Going outside to photograph grass exposes you to sunlight and fresh air simultaneously. The act of bending down and focusing on nature engages your body and senses, creating a full mind-body wake-up that no alarm sound can match.';

  @override
  String get missionExplAffirmationTitle => 'Why affirmations wake you up';

  @override
  String get missionExplAffirmationSubtitle => 'Sets your mindset for the day';

  @override
  String get missionExplAffirmationBody =>
      'Speaking an affirmation out loud activates your voice, breath, and focus simultaneously. The act of reading and repeating engages multiple brain regions — shifting you from passive drowsiness to intentional, conscious thought.';

  @override
  String get generalOk => 'OK';

  @override
  String get generalCancel => 'Cancel';

  @override
  String get generalSubmit => 'Submit';

  @override
  String get generalContinue => 'Continue';

  @override
  String get generalNone => 'None';

  @override
  String get generalDefault => 'Default';
}
