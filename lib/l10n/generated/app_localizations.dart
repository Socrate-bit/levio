import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Levio'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navAlarms.
  ///
  /// In en, this message translates to:
  /// **'Alarms'**
  String get navAlarms;

  /// No description provided for @navInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get navInsights;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @alarmsTitle.
  ///
  /// In en, this message translates to:
  /// **'Alarms'**
  String get alarmsTitle;

  /// No description provided for @alarmsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No alarms yet'**
  String get alarmsEmpty;

  /// No description provided for @alarmsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Tap + to create your first alarm'**
  String get alarmsEmptyHint;

  /// No description provided for @alarmsMissionAlarm.
  ///
  /// In en, this message translates to:
  /// **'Mission Alarm'**
  String get alarmsMissionAlarm;

  /// No description provided for @alarmsMissionAlarmSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Finish a task first'**
  String get alarmsMissionAlarmSubtitle;

  /// No description provided for @alarmsNormalAlarm.
  ///
  /// In en, this message translates to:
  /// **'Normal Alarm'**
  String get alarmsNormalAlarm;

  /// No description provided for @alarmsNormalAlarmSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Just an alarm'**
  String get alarmsNormalAlarmSubtitle;

  /// No description provided for @alarmsDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Alarm #{number}'**
  String alarmsDefaultName(int number);

  /// No description provided for @alarmsMissionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Missions'**
  String alarmsMissionsCount(int count);

  /// No description provided for @alarmsOneTime.
  ///
  /// In en, this message translates to:
  /// **'One-time'**
  String get alarmsOneTime;

  /// No description provided for @alarmsEveryDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get alarmsEveryDay;

  /// No description provided for @alarmsWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Mon, Tue, Wed, Thu, Fri'**
  String get alarmsWeekdays;

  /// No description provided for @daySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get daySun;

  /// No description provided for @dayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get dayMon;

  /// No description provided for @dayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get dayTue;

  /// No description provided for @dayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get dayWed;

  /// No description provided for @dayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get dayThu;

  /// No description provided for @dayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get dayFri;

  /// No description provided for @daySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get daySat;

  /// No description provided for @daySundayFull.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get daySundayFull;

  /// No description provided for @dayMondayFull.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get dayMondayFull;

  /// No description provided for @dayTuesdayFull.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get dayTuesdayFull;

  /// No description provided for @dayWednesdayFull.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get dayWednesdayFull;

  /// No description provided for @dayThursdayFull.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get dayThursdayFull;

  /// No description provided for @dayFridayFull.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get dayFridayFull;

  /// No description provided for @daySaturdayFull.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get daySaturdayFull;

  /// No description provided for @daySingleS.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get daySingleS;

  /// No description provided for @daySingleM.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get daySingleM;

  /// No description provided for @daySingleT.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get daySingleT;

  /// No description provided for @daySingleW.
  ///
  /// In en, this message translates to:
  /// **'W'**
  String get daySingleW;

  /// No description provided for @daySingleF.
  ///
  /// In en, this message translates to:
  /// **'F'**
  String get daySingleF;

  /// No description provided for @alarmFormSetTime.
  ///
  /// In en, this message translates to:
  /// **'Set Time'**
  String get alarmFormSetTime;

  /// No description provided for @alarmFormDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get alarmFormDone;

  /// No description provided for @alarmFormEditAlarm.
  ///
  /// In en, this message translates to:
  /// **'Edit Alarm'**
  String get alarmFormEditAlarm;

  /// No description provided for @alarmFormNewAlarm.
  ///
  /// In en, this message translates to:
  /// **'New Alarm'**
  String get alarmFormNewAlarm;

  /// No description provided for @alarmFormAlarmName.
  ///
  /// In en, this message translates to:
  /// **'Alarm name'**
  String get alarmFormAlarmName;

  /// No description provided for @alarmFormAlarmTime.
  ///
  /// In en, this message translates to:
  /// **'Alarm Time'**
  String get alarmFormAlarmTime;

  /// No description provided for @alarmFormScheduled.
  ///
  /// In en, this message translates to:
  /// **'↻  Scheduled'**
  String get alarmFormScheduled;

  /// No description provided for @alarmFormOneTime.
  ///
  /// In en, this message translates to:
  /// **'📅  One-time'**
  String get alarmFormOneTime;

  /// No description provided for @alarmFormRepeatOn.
  ///
  /// In en, this message translates to:
  /// **'Repeat on:'**
  String get alarmFormRepeatOn;

  /// No description provided for @alarmFormAddMission.
  ///
  /// In en, this message translates to:
  /// **'Add Mission ({count} of 3)'**
  String alarmFormAddMission(int count);

  /// No description provided for @alarmFormStackMissions.
  ///
  /// In en, this message translates to:
  /// **'Stack missions & complete to turn off alarm'**
  String get alarmFormStackMissions;

  /// No description provided for @alarmFormSound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get alarmFormSound;

  /// No description provided for @alarmFormUpdateAlarm.
  ///
  /// In en, this message translates to:
  /// **'Update Alarm'**
  String get alarmFormUpdateAlarm;

  /// No description provided for @alarmFormSaveAlarm.
  ///
  /// In en, this message translates to:
  /// **'Save Alarm'**
  String get alarmFormSaveAlarm;

  /// No description provided for @alarmFormMissionIndex.
  ///
  /// In en, this message translates to:
  /// **'Mission {index}'**
  String alarmFormMissionIndex(int index);

  /// No description provided for @soundPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Alarm Sound'**
  String get soundPickerTitle;

  /// No description provided for @soundPickerYourSounds.
  ///
  /// In en, this message translates to:
  /// **'Your Sounds'**
  String get soundPickerYourSounds;

  /// No description provided for @soundPickerUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload Sound'**
  String get soundPickerUpload;

  /// No description provided for @soundPickerSelect.
  ///
  /// In en, this message translates to:
  /// **'Select Sound'**
  String get soundPickerSelect;

  /// No description provided for @soundPickerNew.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get soundPickerNew;

  /// No description provided for @soundPickerCredit.
  ///
  /// In en, this message translates to:
  /// **'1 credit'**
  String get soundPickerCredit;

  /// No description provided for @soundDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get soundDefault;

  /// No description provided for @soundClock2.
  ///
  /// In en, this message translates to:
  /// **'Clock 2'**
  String get soundClock2;

  /// No description provided for @soundClock3.
  ///
  /// In en, this message translates to:
  /// **'Clock 3'**
  String get soundClock3;

  /// No description provided for @soundClock4.
  ///
  /// In en, this message translates to:
  /// **'Clock 4'**
  String get soundClock4;

  /// No description provided for @soundFunny.
  ///
  /// In en, this message translates to:
  /// **'Funny'**
  String get soundFunny;

  /// No description provided for @soundCelestial.
  ///
  /// In en, this message translates to:
  /// **'Celestial'**
  String get soundCelestial;

  /// No description provided for @soundChiptune.
  ///
  /// In en, this message translates to:
  /// **'Chiptune'**
  String get soundChiptune;

  /// No description provided for @soundDreamscape.
  ///
  /// In en, this message translates to:
  /// **'Dreamscape'**
  String get soundDreamscape;

  /// No description provided for @soundGame.
  ///
  /// In en, this message translates to:
  /// **'Game'**
  String get soundGame;

  /// No description provided for @soundGame2.
  ///
  /// In en, this message translates to:
  /// **'Game 2'**
  String get soundGame2;

  /// No description provided for @soundOversimplified.
  ///
  /// In en, this message translates to:
  /// **'Oversimplified'**
  String get soundOversimplified;

  /// No description provided for @soundSmooth.
  ///
  /// In en, this message translates to:
  /// **'Smooth'**
  String get soundSmooth;

  /// No description provided for @soundAcoustic.
  ///
  /// In en, this message translates to:
  /// **'Acoustic'**
  String get soundAcoustic;

  /// No description provided for @soundComing.
  ///
  /// In en, this message translates to:
  /// **'Coming'**
  String get soundComing;

  /// No description provided for @soundCyber.
  ///
  /// In en, this message translates to:
  /// **'Cyber'**
  String get soundCyber;

  /// No description provided for @soundDetermination.
  ///
  /// In en, this message translates to:
  /// **'Determination'**
  String get soundDetermination;

  /// No description provided for @soundDubstep.
  ///
  /// In en, this message translates to:
  /// **'Dubstep'**
  String get soundDubstep;

  /// No description provided for @soundHiphop.
  ///
  /// In en, this message translates to:
  /// **'Hiphop'**
  String get soundHiphop;

  /// No description provided for @soundPiano.
  ///
  /// In en, this message translates to:
  /// **'Piano'**
  String get soundPiano;

  /// No description provided for @soundTropical.
  ///
  /// In en, this message translates to:
  /// **'Tropical'**
  String get soundTropical;

  /// No description provided for @soundRingstone1.
  ///
  /// In en, this message translates to:
  /// **'Ringstone 1'**
  String get soundRingstone1;

  /// No description provided for @soundRingstone2.
  ///
  /// In en, this message translates to:
  /// **'Ringstone 2'**
  String get soundRingstone2;

  /// No description provided for @soundRingstone3.
  ///
  /// In en, this message translates to:
  /// **'Ringstone 3'**
  String get soundRingstone3;

  /// No description provided for @soundAlarm.
  ///
  /// In en, this message translates to:
  /// **'Alarm'**
  String get soundAlarm;

  /// No description provided for @soundHardcore.
  ///
  /// In en, this message translates to:
  /// **'Hardcore'**
  String get soundHardcore;

  /// No description provided for @soundCategoryClock.
  ///
  /// In en, this message translates to:
  /// **'Clock'**
  String get soundCategoryClock;

  /// No description provided for @soundCategoryGentle.
  ///
  /// In en, this message translates to:
  /// **'Gentle'**
  String get soundCategoryGentle;

  /// No description provided for @soundCategoryMusical.
  ///
  /// In en, this message translates to:
  /// **'Musical'**
  String get soundCategoryMusical;

  /// No description provided for @soundCategoryRingstone.
  ///
  /// In en, this message translates to:
  /// **'Ringstone'**
  String get soundCategoryRingstone;

  /// No description provided for @soundCategoryViolent.
  ///
  /// In en, this message translates to:
  /// **'Violent'**
  String get soundCategoryViolent;

  /// No description provided for @homeNextWakeUp.
  ///
  /// In en, this message translates to:
  /// **'Next Wake Up'**
  String get homeNextWakeUp;

  /// No description provided for @homeTodaysWakeup.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Wakeup'**
  String get homeTodaysWakeup;

  /// No description provided for @homeSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get homeSeeAll;

  /// No description provided for @homeNoActiveAlarm.
  ///
  /// In en, this message translates to:
  /// **'No active alarm'**
  String get homeNoActiveAlarm;

  /// No description provided for @homeNoActiveAlarmHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to create one with a mission'**
  String get homeNoActiveAlarmHint;

  /// No description provided for @homeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get homeToday;

  /// No description provided for @homeTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get homeTomorrow;

  /// No description provided for @homePastAlarm.
  ///
  /// In en, this message translates to:
  /// **'Past alarm'**
  String get homePastAlarm;

  /// No description provided for @homeRingsIn.
  ///
  /// In en, this message translates to:
  /// **'Rings in {hours}h {minutes}m'**
  String homeRingsIn(int hours, int minutes);

  /// No description provided for @homeMission.
  ///
  /// In en, this message translates to:
  /// **'Mission'**
  String get homeMission;

  /// No description provided for @homeSound.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get homeSound;

  /// No description provided for @homeNoWakeupsYet.
  ///
  /// In en, this message translates to:
  /// **'No wakeups yet'**
  String get homeNoWakeupsYet;

  /// No description provided for @homeSetAlarmToStart.
  ///
  /// In en, this message translates to:
  /// **'Set an alarm to get started'**
  String get homeSetAlarmToStart;

  /// No description provided for @monthJan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get monthDec;

  /// No description provided for @missionPushUps.
  ///
  /// In en, this message translates to:
  /// **'Push Ups'**
  String get missionPushUps;

  /// No description provided for @missionPushUpsDesc.
  ///
  /// In en, this message translates to:
  /// **'Video yourself doing push-ups'**
  String get missionPushUpsDesc;

  /// No description provided for @missionSquats.
  ///
  /// In en, this message translates to:
  /// **'Squats'**
  String get missionSquats;

  /// No description provided for @missionSquatsDesc.
  ///
  /// In en, this message translates to:
  /// **'Video yourself doing squats'**
  String get missionSquatsDesc;

  /// No description provided for @missionShakePhone.
  ///
  /// In en, this message translates to:
  /// **'Shake Phone'**
  String get missionShakePhone;

  /// No description provided for @missionShakePhoneDesc.
  ///
  /// In en, this message translates to:
  /// **'Shake your phone to wake up'**
  String get missionShakePhoneDesc;

  /// No description provided for @missionMath.
  ///
  /// In en, this message translates to:
  /// **'Math'**
  String get missionMath;

  /// No description provided for @missionMathDesc.
  ///
  /// In en, this message translates to:
  /// **'Solve math problems to wake up'**
  String get missionMathDesc;

  /// No description provided for @missionSkyPhoto.
  ///
  /// In en, this message translates to:
  /// **'Sky Photo'**
  String get missionSkyPhoto;

  /// No description provided for @missionSkyPhotoDesc.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of the sky'**
  String get missionSkyPhotoDesc;

  /// No description provided for @missionMakeBed.
  ///
  /// In en, this message translates to:
  /// **'Make Bed'**
  String get missionMakeBed;

  /// No description provided for @missionMakeBedDesc.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of your made bed'**
  String get missionMakeBedDesc;

  /// No description provided for @missionObjectHunt.
  ///
  /// In en, this message translates to:
  /// **'Object Hunt'**
  String get missionObjectHunt;

  /// No description provided for @missionObjectHuntDesc.
  ///
  /// In en, this message translates to:
  /// **'Find and photograph a household object'**
  String get missionObjectHuntDesc;

  /// No description provided for @missionPetHunt.
  ///
  /// In en, this message translates to:
  /// **'Pet Hunt'**
  String get missionPetHunt;

  /// No description provided for @missionPetHuntDesc.
  ///
  /// In en, this message translates to:
  /// **'Find and photograph your pet'**
  String get missionPetHuntDesc;

  /// No description provided for @missionNatureHunt.
  ///
  /// In en, this message translates to:
  /// **'Nature Hunt'**
  String get missionNatureHunt;

  /// No description provided for @missionNatureHuntDesc.
  ///
  /// In en, this message translates to:
  /// **'Find and photograph something in nature'**
  String get missionNatureHuntDesc;

  /// No description provided for @missionTouchGrass.
  ///
  /// In en, this message translates to:
  /// **'Touch Grass'**
  String get missionTouchGrass;

  /// No description provided for @missionTouchGrassDesc.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of the grass'**
  String get missionTouchGrassDesc;

  /// No description provided for @missionAffirmation.
  ///
  /// In en, this message translates to:
  /// **'Affirmation'**
  String get missionAffirmation;

  /// No description provided for @missionAffirmationDesc.
  ///
  /// In en, this message translates to:
  /// **'Read an affirmation out loud'**
  String get missionAffirmationDesc;

  /// No description provided for @missionRandom.
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get missionRandom;

  /// No description provided for @missionRandomDesc.
  ///
  /// In en, this message translates to:
  /// **'Surprise mission each morning'**
  String get missionRandomDesc;

  /// No description provided for @missionNone.
  ///
  /// In en, this message translates to:
  /// **'No mission'**
  String get missionNone;

  /// No description provided for @missionNoneDesc.
  ///
  /// In en, this message translates to:
  /// **'Simple alarm with no task'**
  String get missionNoneDesc;

  /// No description provided for @photoTargetSky.
  ///
  /// In en, this message translates to:
  /// **'the sky'**
  String get photoTargetSky;

  /// No description provided for @photoTargetMadeBed.
  ///
  /// In en, this message translates to:
  /// **'your made bed'**
  String get photoTargetMadeBed;

  /// No description provided for @photoTargetGrass.
  ///
  /// In en, this message translates to:
  /// **'grass'**
  String get photoTargetGrass;

  /// No description provided for @missionPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Mission'**
  String get missionPickerTitle;

  /// No description provided for @missionPickerAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get missionPickerAll;

  /// No description provided for @missionPickerTrending.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get missionPickerTrending;

  /// No description provided for @missionPickerHunts.
  ///
  /// In en, this message translates to:
  /// **'Hunts'**
  String get missionPickerHunts;

  /// No description provided for @missionPickerPhysical.
  ///
  /// In en, this message translates to:
  /// **'Physical'**
  String get missionPickerPhysical;

  /// No description provided for @missionPickerPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get missionPickerPreview;

  /// No description provided for @missionConfigNumberOfShakes.
  ///
  /// In en, this message translates to:
  /// **'Number of shakes'**
  String get missionConfigNumberOfShakes;

  /// No description provided for @missionConfigNumberOfReps.
  ///
  /// In en, this message translates to:
  /// **'Number of reps'**
  String get missionConfigNumberOfReps;

  /// No description provided for @missionConfigNumberOfProblems.
  ///
  /// In en, this message translates to:
  /// **'Number of problems'**
  String get missionConfigNumberOfProblems;

  /// No description provided for @missionConfigDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get missionConfigDifficulty;

  /// No description provided for @missionConfigEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get missionConfigEasy;

  /// No description provided for @missionConfigMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get missionConfigMedium;

  /// No description provided for @missionConfigHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get missionConfigHard;

  /// No description provided for @missionConfigChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose This Mission'**
  String get missionConfigChoose;

  /// No description provided for @missionConfigNumberOfAffirmations.
  ///
  /// In en, this message translates to:
  /// **'Number of affirmations'**
  String get missionConfigNumberOfAffirmations;

  /// No description provided for @itemPickerSelectItems.
  ///
  /// In en, this message translates to:
  /// **'Select Items'**
  String get itemPickerSelectItems;

  /// No description provided for @itemPickerRandomItem.
  ///
  /// In en, this message translates to:
  /// **'A random item will be chosen each morning'**
  String get itemPickerRandomItem;

  /// No description provided for @itemPickerHouseholdItems.
  ///
  /// In en, this message translates to:
  /// **'Household Items'**
  String get itemPickerHouseholdItems;

  /// No description provided for @itemPickerFunItems.
  ///
  /// In en, this message translates to:
  /// **'Fun Items'**
  String get itemPickerFunItems;

  /// No description provided for @itemPickerSelectPets.
  ///
  /// In en, this message translates to:
  /// **'Select Your Pets'**
  String get itemPickerSelectPets;

  /// No description provided for @itemPickerPetsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select which pets you have at home'**
  String get itemPickerPetsSubtitle;

  /// No description provided for @itemPickerSelectNature.
  ///
  /// In en, this message translates to:
  /// **'Select Nature Items'**
  String get itemPickerSelectNature;

  /// No description provided for @itemPickerNatureSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A random nature item will be chosen each morning'**
  String get itemPickerNatureSubtitle;

  /// No description provided for @itemPickerSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String itemPickerSelected(int count);

  /// No description provided for @itemPickerSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get itemPickerSelectAll;

  /// No description provided for @itemPickerDeselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get itemPickerDeselectAll;

  /// No description provided for @itemPickerAddOwn.
  ///
  /// In en, this message translates to:
  /// **'Add your own item'**
  String get itemPickerAddOwn;

  /// No description provided for @itemPickerDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get itemPickerDone;

  /// No description provided for @itemPickerCustomItems.
  ///
  /// In en, this message translates to:
  /// **'Custom Items'**
  String get itemPickerCustomItems;

  /// No description provided for @affirmationPickerCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get affirmationPickerCustom;

  /// No description provided for @itemToothbrush.
  ///
  /// In en, this message translates to:
  /// **'Toothbrush'**
  String get itemToothbrush;

  /// No description provided for @itemRunningFaucet.
  ///
  /// In en, this message translates to:
  /// **'Running Faucet'**
  String get itemRunningFaucet;

  /// No description provided for @itemShoes.
  ///
  /// In en, this message translates to:
  /// **'Shoes'**
  String get itemShoes;

  /// No description provided for @itemFridge.
  ///
  /// In en, this message translates to:
  /// **'Fridge'**
  String get itemFridge;

  /// No description provided for @itemKeys.
  ///
  /// In en, this message translates to:
  /// **'Keys'**
  String get itemKeys;

  /// No description provided for @itemCoffeeMug.
  ///
  /// In en, this message translates to:
  /// **'Coffee Mug'**
  String get itemCoffeeMug;

  /// No description provided for @itemMirror.
  ///
  /// In en, this message translates to:
  /// **'Mirror'**
  String get itemMirror;

  /// No description provided for @itemWaterBottle.
  ///
  /// In en, this message translates to:
  /// **'Water Bottle'**
  String get itemWaterBottle;

  /// No description provided for @itemDustpan.
  ///
  /// In en, this message translates to:
  /// **'Dustpan'**
  String get itemDustpan;

  /// No description provided for @itemToilet.
  ///
  /// In en, this message translates to:
  /// **'Toilet'**
  String get itemToilet;

  /// No description provided for @itemBook.
  ///
  /// In en, this message translates to:
  /// **'Book'**
  String get itemBook;

  /// No description provided for @itemLamp.
  ///
  /// In en, this message translates to:
  /// **'Lamp'**
  String get itemLamp;

  /// No description provided for @itemTvRemote.
  ///
  /// In en, this message translates to:
  /// **'TV Remote'**
  String get itemTvRemote;

  /// No description provided for @itemFrontDoor.
  ///
  /// In en, this message translates to:
  /// **'Front Door'**
  String get itemFrontDoor;

  /// No description provided for @itemStove.
  ///
  /// In en, this message translates to:
  /// **'Stove'**
  String get itemStove;

  /// No description provided for @itemLotionBottle.
  ///
  /// In en, this message translates to:
  /// **'Lotion Bottle'**
  String get itemLotionBottle;

  /// No description provided for @itemSoap.
  ///
  /// In en, this message translates to:
  /// **'Soap'**
  String get itemSoap;

  /// No description provided for @itemPlant.
  ///
  /// In en, this message translates to:
  /// **'Plant'**
  String get itemPlant;

  /// No description provided for @itemPlate.
  ///
  /// In en, this message translates to:
  /// **'Plate'**
  String get itemPlate;

  /// No description provided for @itemTowel.
  ///
  /// In en, this message translates to:
  /// **'Towel'**
  String get itemTowel;

  /// No description provided for @itemBackpack.
  ///
  /// In en, this message translates to:
  /// **'Backpack'**
  String get itemBackpack;

  /// No description provided for @itemHeadphones.
  ///
  /// In en, this message translates to:
  /// **'Headphones'**
  String get itemHeadphones;

  /// No description provided for @itemShower.
  ///
  /// In en, this message translates to:
  /// **'Shower'**
  String get itemShower;

  /// No description provided for @itemTape.
  ///
  /// In en, this message translates to:
  /// **'Tape'**
  String get itemTape;

  /// No description provided for @itemKimKardashian.
  ///
  /// In en, this message translates to:
  /// **'Kim Kardashian'**
  String get itemKimKardashian;

  /// No description provided for @itemSnoopDogg.
  ///
  /// In en, this message translates to:
  /// **'Snoop Dogg'**
  String get itemSnoopDogg;

  /// No description provided for @itemRubberDuck.
  ///
  /// In en, this message translates to:
  /// **'Rubber Duck'**
  String get itemRubberDuck;

  /// No description provided for @itemBanana.
  ///
  /// In en, this message translates to:
  /// **'Banana'**
  String get itemBanana;

  /// No description provided for @itemPickle.
  ///
  /// In en, this message translates to:
  /// **'Pickle'**
  String get itemPickle;

  /// No description provided for @itemCroc.
  ///
  /// In en, this message translates to:
  /// **'Croc'**
  String get itemCroc;

  /// No description provided for @itemLavaLamp.
  ///
  /// In en, this message translates to:
  /// **'Lava Lamp'**
  String get itemLavaLamp;

  /// No description provided for @itemPingPongPaddle.
  ///
  /// In en, this message translates to:
  /// **'Ping Pong Paddle'**
  String get itemPingPongPaddle;

  /// No description provided for @itemEgg.
  ///
  /// In en, this message translates to:
  /// **'Egg'**
  String get itemEgg;

  /// No description provided for @petDog.
  ///
  /// In en, this message translates to:
  /// **'Dog'**
  String get petDog;

  /// No description provided for @petCat.
  ///
  /// In en, this message translates to:
  /// **'Cat'**
  String get petCat;

  /// No description provided for @petBird.
  ///
  /// In en, this message translates to:
  /// **'Bird'**
  String get petBird;

  /// No description provided for @petFish.
  ///
  /// In en, this message translates to:
  /// **'Fish'**
  String get petFish;

  /// No description provided for @petHamster.
  ///
  /// In en, this message translates to:
  /// **'Hamster'**
  String get petHamster;

  /// No description provided for @petRabbit.
  ///
  /// In en, this message translates to:
  /// **'Rabbit'**
  String get petRabbit;

  /// No description provided for @petTurtle.
  ///
  /// In en, this message translates to:
  /// **'Turtle'**
  String get petTurtle;

  /// No description provided for @petGuineaPig.
  ///
  /// In en, this message translates to:
  /// **'Guinea Pig'**
  String get petGuineaPig;

  /// No description provided for @petLizard.
  ///
  /// In en, this message translates to:
  /// **'Lizard'**
  String get petLizard;

  /// No description provided for @petSnake.
  ///
  /// In en, this message translates to:
  /// **'Snake'**
  String get petSnake;

  /// No description provided for @natureTree.
  ///
  /// In en, this message translates to:
  /// **'Tree'**
  String get natureTree;

  /// No description provided for @natureFlower.
  ///
  /// In en, this message translates to:
  /// **'Flower'**
  String get natureFlower;

  /// No description provided for @natureRock.
  ///
  /// In en, this message translates to:
  /// **'Rock'**
  String get natureRock;

  /// No description provided for @natureLeaf.
  ///
  /// In en, this message translates to:
  /// **'Leaf'**
  String get natureLeaf;

  /// No description provided for @natureGrass.
  ///
  /// In en, this message translates to:
  /// **'Grass'**
  String get natureGrass;

  /// No description provided for @natureBush.
  ///
  /// In en, this message translates to:
  /// **'Bush'**
  String get natureBush;

  /// No description provided for @natureStick.
  ///
  /// In en, this message translates to:
  /// **'Stick'**
  String get natureStick;

  /// No description provided for @naturePinecone.
  ///
  /// In en, this message translates to:
  /// **'Pinecone'**
  String get naturePinecone;

  /// No description provided for @affirmationPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Affirmations'**
  String get affirmationPickerTitle;

  /// No description provided for @affirmationPickerSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String affirmationPickerSelected(int count);

  /// No description provided for @affirmationPickerSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get affirmationPickerSelectAll;

  /// No description provided for @affirmationPickerDeselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get affirmationPickerDeselectAll;

  /// No description provided for @affirmationPickerAddOwn.
  ///
  /// In en, this message translates to:
  /// **'Add your own affirmation'**
  String get affirmationPickerAddOwn;

  /// No description provided for @affirmationPickerDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get affirmationPickerDone;

  /// No description provided for @randomPoolTitle.
  ///
  /// In en, this message translates to:
  /// **'Random Pool'**
  String get randomPoolTitle;

  /// No description provided for @randomPoolSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select missions to include in random rotation'**
  String get randomPoolSubtitle;

  /// No description provided for @randomPoolSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String randomPoolSelected(int count);

  /// No description provided for @randomPoolSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get randomPoolSelectAll;

  /// No description provided for @randomPoolDeselectAll.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get randomPoolDeselectAll;

  /// No description provided for @randomPoolDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get randomPoolDone;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAnonymousUser.
  ///
  /// In en, this message translates to:
  /// **'Anonymous User'**
  String get settingsAnonymousUser;

  /// No description provided for @settingsAccountType.
  ///
  /// In en, this message translates to:
  /// **'Account type: {type}'**
  String settingsAccountType(String type);

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsUserType.
  ///
  /// In en, this message translates to:
  /// **'User Type'**
  String get settingsUserType;

  /// No description provided for @settingsEnterReferralCode.
  ///
  /// In en, this message translates to:
  /// **'Enter Referral Code'**
  String get settingsEnterReferralCode;

  /// No description provided for @settingsApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get settingsApp;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get settingsDarkMode;

  /// No description provided for @settingsAlarmDuringMission.
  ///
  /// In en, this message translates to:
  /// **'Alarm During Mission'**
  String get settingsAlarmDuringMission;

  /// No description provided for @settingsDefaultSound.
  ///
  /// In en, this message translates to:
  /// **'Default Sound'**
  String get settingsDefaultSound;

  /// No description provided for @settingsDefaultMission.
  ///
  /// In en, this message translates to:
  /// **'Default Mission'**
  String get settingsDefaultMission;

  /// No description provided for @settingsNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get settingsNone;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get settingsTermsOfService;

  /// No description provided for @settingsAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin (debug only)'**
  String get settingsAdmin;

  /// No description provided for @settingsPrintAllAlarms.
  ///
  /// In en, this message translates to:
  /// **'Print All Alarms'**
  String get settingsPrintAllAlarms;

  /// No description provided for @settingsPrintRawAlarms.
  ///
  /// In en, this message translates to:
  /// **'Print Raw AlarmKit Alarms'**
  String get settingsPrintRawAlarms;

  /// No description provided for @settingsPrintSharedPreferences.
  ///
  /// In en, this message translates to:
  /// **'Print SharedPreferences'**
  String get settingsPrintSharedPreferences;

  /// No description provided for @settingsDeleteAllAlarms.
  ///
  /// In en, this message translates to:
  /// **'Delete All Alarms'**
  String get settingsDeleteAllAlarms;

  /// No description provided for @settingsLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get settingsLogout;

  /// No description provided for @settingsLogoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get settingsLogoutTitle;

  /// No description provided for @settingsLogoutBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll be signed out of this device. Local settings and scheduled alarms will be cleared.'**
  String get settingsLogoutBody;

  /// No description provided for @settingsLogoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get settingsLogoutConfirm;

  /// No description provided for @settingsLogoutCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsLogoutCancel;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get settingsDeleteAccountTitle;

  /// No description provided for @settingsDeleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your account, alarms, sessions, and streak history. This action cannot be undone.'**
  String get settingsDeleteAccountBody;

  /// No description provided for @settingsDeleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get settingsDeleteAccountConfirm;

  /// No description provided for @settingsDeleteAccountCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get settingsDeleteAccountCancel;

  /// No description provided for @settingsDeleteAccountReauthRequired.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again, then retry deleting your account.'**
  String get settingsDeleteAccountReauthRequired;

  /// No description provided for @settingsDeleteAccountError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete your account. Please try again.'**
  String get settingsDeleteAccountError;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Levio v0.1.0'**
  String get settingsVersion;

  /// No description provided for @referralTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter Referral Code'**
  String get referralTitle;

  /// No description provided for @referralCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Referral Code'**
  String get referralCodeLabel;

  /// No description provided for @referralApplied.
  ///
  /// In en, this message translates to:
  /// **'Referral code applied! You are now: {type}'**
  String referralApplied(String type);

  /// No description provided for @referralInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid referral code'**
  String get referralInvalid;

  /// No description provided for @referralUsageLimit.
  ///
  /// In en, this message translates to:
  /// **'This code has reached its usage limit'**
  String get referralUsageLimit;

  /// No description provided for @referralError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong, please try again'**
  String get referralError;

  /// No description provided for @referralCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get referralCancel;

  /// No description provided for @referralSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get referralSubmit;

  /// No description provided for @insightsTitle.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insightsTitle;

  /// No description provided for @insightsStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get insightsStats;

  /// No description provided for @insightsAvgWakeTime.
  ///
  /// In en, this message translates to:
  /// **'Avg Wake Time'**
  String get insightsAvgWakeTime;

  /// No description provided for @insightsAvgResponse.
  ///
  /// In en, this message translates to:
  /// **'Avg Response'**
  String get insightsAvgResponse;

  /// No description provided for @insightsFavoriteMission.
  ///
  /// In en, this message translates to:
  /// **'Favorite Mission'**
  String get insightsFavoriteMission;

  /// No description provided for @insightsFavoriteSound.
  ///
  /// In en, this message translates to:
  /// **'Favorite Sound'**
  String get insightsFavoriteSound;

  /// No description provided for @insightsWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get insightsWeek;

  /// No description provided for @insightsMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get insightsMonth;

  /// No description provided for @insightsAllTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get insightsAllTime;

  /// No description provided for @insightsDayStreak.
  ///
  /// In en, this message translates to:
  /// **'Day Streak'**
  String get insightsDayStreak;

  /// No description provided for @insightsBadgesEarned.
  ///
  /// In en, this message translates to:
  /// **'Badges Earned'**
  String get insightsBadgesEarned;

  /// No description provided for @insightsConsistency.
  ///
  /// In en, this message translates to:
  /// **'Consistency'**
  String get insightsConsistency;

  /// No description provided for @insightsNeed3Wakeups.
  ///
  /// In en, this message translates to:
  /// **'Need 3+ wake ups'**
  String get insightsNeed3Wakeups;

  /// No description provided for @insightsConsistencyVariable.
  ///
  /// In en, this message translates to:
  /// **'Variable'**
  String get insightsConsistencyVariable;

  /// No description provided for @insightsConsistencyImproving.
  ///
  /// In en, this message translates to:
  /// **'Improving'**
  String get insightsConsistencyImproving;

  /// No description provided for @insightsConsistencyRegular.
  ///
  /// In en, this message translates to:
  /// **'Regular'**
  String get insightsConsistencyRegular;

  /// No description provided for @insightsConsistencyConsistent.
  ///
  /// In en, this message translates to:
  /// **'Consistent'**
  String get insightsConsistencyConsistent;

  /// No description provided for @insightsConsistencyScoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Consistency Score'**
  String get insightsConsistencyScoreTitle;

  /// No description provided for @insightsConsistencyScoreBody.
  ///
  /// In en, this message translates to:
  /// **'Your consistency score measures how regularly you wake up with Levio. It improves as your streak grows.'**
  String get insightsConsistencyScoreBody;

  /// No description provided for @insightsOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get insightsOk;

  /// No description provided for @milestonesTitle.
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get milestonesTitle;

  /// No description provided for @milestonesDayStreak.
  ///
  /// In en, this message translates to:
  /// **'Day Streak'**
  String get milestonesDayStreak;

  /// No description provided for @milestonesLongestStreak.
  ///
  /// In en, this message translates to:
  /// **'{count} day'**
  String milestonesLongestStreak(int count);

  /// No description provided for @milestonesLongestStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'longest streak'**
  String get milestonesLongestStreakLabel;

  /// No description provided for @milestonesStreakBadges.
  ///
  /// In en, this message translates to:
  /// **'Streak Badges'**
  String get milestonesStreakBadges;

  /// No description provided for @milestonesAchievementBadges.
  ///
  /// In en, this message translates to:
  /// **'Achievement Badges'**
  String get milestonesAchievementBadges;

  /// No description provided for @milestonesBadgesEarned.
  ///
  /// In en, this message translates to:
  /// **'Badges Earned'**
  String get milestonesBadgesEarned;

  /// No description provided for @milestonesBadgeCount.
  ///
  /// In en, this message translates to:
  /// **'{earned}/{total} badges'**
  String milestonesBadgeCount(int earned, int total);

  /// No description provided for @milestonesHowStreaksWork.
  ///
  /// In en, this message translates to:
  /// **'How Streaks Work'**
  String get milestonesHowStreaksWork;

  /// No description provided for @milestonesStreakExplanation.
  ///
  /// In en, this message translates to:
  /// **'Wake up with Levio daily to build your streak. You get 2 freeze days per week to skip without losing progress. If you miss a day without a freeze, your streak drops by 3 instead of resetting to zero.'**
  String get milestonesStreakExplanation;

  /// No description provided for @badgeRisen.
  ///
  /// In en, this message translates to:
  /// **'Risen'**
  String get badgeRisen;

  /// No description provided for @badgeRisenReq.
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get badgeRisenReq;

  /// No description provided for @badgeRisenQuote.
  ///
  /// In en, this message translates to:
  /// **'The journey of a thousand mornings begins with one alarm.'**
  String get badgeRisenQuote;

  /// No description provided for @badgeIgnite.
  ///
  /// In en, this message translates to:
  /// **'Ignite'**
  String get badgeIgnite;

  /// No description provided for @badgeIgniteReq.
  ///
  /// In en, this message translates to:
  /// **'3 days'**
  String get badgeIgniteReq;

  /// No description provided for @badgeIgniteQuote.
  ///
  /// In en, this message translates to:
  /// **'Three days in. The flame is growing.'**
  String get badgeIgniteQuote;

  /// No description provided for @badgeHorizon.
  ///
  /// In en, this message translates to:
  /// **'Horizon'**
  String get badgeHorizon;

  /// No description provided for @badgeHorizonReq.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get badgeHorizonReq;

  /// No description provided for @badgeHorizonQuote.
  ///
  /// In en, this message translates to:
  /// **'A week of mornings — you\'re rewriting your story.'**
  String get badgeHorizonQuote;

  /// No description provided for @badgeAurora.
  ///
  /// In en, this message translates to:
  /// **'Aurora'**
  String get badgeAurora;

  /// No description provided for @badgeAuroraReq.
  ///
  /// In en, this message translates to:
  /// **'14 days'**
  String get badgeAuroraReq;

  /// No description provided for @badgeAuroraQuote.
  ///
  /// In en, this message translates to:
  /// **'Two weeks of sunrise. Keep chasing the light.'**
  String get badgeAuroraQuote;

  /// No description provided for @badgeCelestial.
  ///
  /// In en, this message translates to:
  /// **'Celestial'**
  String get badgeCelestial;

  /// No description provided for @badgeCelestialReq.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get badgeCelestialReq;

  /// No description provided for @badgeCelestialQuote.
  ///
  /// In en, this message translates to:
  /// **'A full month of rising. You are unstoppable.'**
  String get badgeCelestialQuote;

  /// No description provided for @badgeNebula.
  ///
  /// In en, this message translates to:
  /// **'Nebula'**
  String get badgeNebula;

  /// No description provided for @badgeNebulaReq.
  ///
  /// In en, this message translates to:
  /// **'100 days'**
  String get badgeNebulaReq;

  /// No description provided for @badgeNebulaQuote.
  ///
  /// In en, this message translates to:
  /// **'One hundred mornings. A new you has been born.'**
  String get badgeNebulaQuote;

  /// No description provided for @badgeEternal.
  ///
  /// In en, this message translates to:
  /// **'Eternal'**
  String get badgeEternal;

  /// No description provided for @badgeEternalReq.
  ///
  /// In en, this message translates to:
  /// **'365 days'**
  String get badgeEternalReq;

  /// No description provided for @badgeEternalQuote.
  ///
  /// In en, this message translates to:
  /// **'A full year of mornings. You are legendary.'**
  String get badgeEternalQuote;

  /// No description provided for @badgeVersatile.
  ///
  /// In en, this message translates to:
  /// **'Versatile'**
  String get badgeVersatile;

  /// No description provided for @badgeVersatileReq.
  ///
  /// In en, this message translates to:
  /// **'Use all 13 mission types'**
  String get badgeVersatileReq;

  /// No description provided for @badgeVersatileQuote.
  ///
  /// In en, this message translates to:
  /// **'Mastery comes from variety.'**
  String get badgeVersatileQuote;

  /// No description provided for @badgeFirstLight.
  ///
  /// In en, this message translates to:
  /// **'First Light'**
  String get badgeFirstLight;

  /// No description provided for @badgeFirstLightReq.
  ///
  /// In en, this message translates to:
  /// **'Wake up before 5:30 AM'**
  String get badgeFirstLightReq;

  /// No description provided for @badgeFirstLightQuote.
  ///
  /// In en, this message translates to:
  /// **'The early bird catches the sunrise.'**
  String get badgeFirstLightQuote;

  /// No description provided for @badgeBlitz.
  ///
  /// In en, this message translates to:
  /// **'Blitz'**
  String get badgeBlitz;

  /// No description provided for @badgeBlitzReq.
  ///
  /// In en, this message translates to:
  /// **'Turn off alarm in under 15s'**
  String get badgeBlitzReq;

  /// No description provided for @badgeBlitzQuote.
  ///
  /// In en, this message translates to:
  /// **'Speed of light. Speed of life.'**
  String get badgeBlitzQuote;

  /// No description provided for @badgeNoDaysOff.
  ///
  /// In en, this message translates to:
  /// **'No Days Off'**
  String get badgeNoDaysOff;

  /// No description provided for @badgeNoDaysOffReq.
  ///
  /// In en, this message translates to:
  /// **'30 consecutive wakeups'**
  String get badgeNoDaysOffReq;

  /// No description provided for @badgeNoDaysOffQuote.
  ///
  /// In en, this message translates to:
  /// **'Weekends are just weekdays in disguise.'**
  String get badgeNoDaysOffQuote;

  /// No description provided for @badgeConverted.
  ///
  /// In en, this message translates to:
  /// **'Converted'**
  String get badgeConverted;

  /// No description provided for @badgeConvertedReq.
  ///
  /// In en, this message translates to:
  /// **'Reach a 7-day streak'**
  String get badgeConvertedReq;

  /// No description provided for @badgeConvertedQuote.
  ///
  /// In en, this message translates to:
  /// **'Even night owls can learn to love the dawn.'**
  String get badgeConvertedQuote;

  /// No description provided for @badgeAudiophile.
  ///
  /// In en, this message translates to:
  /// **'Audiophile'**
  String get badgeAudiophile;

  /// No description provided for @badgeAudiophileReq.
  ///
  /// In en, this message translates to:
  /// **'Use 4+ different alarm sounds'**
  String get badgeAudiophileReq;

  /// No description provided for @badgeAudiophileQuote.
  ///
  /// In en, this message translates to:
  /// **'Every morning deserves its own soundtrack.'**
  String get badgeAudiophileQuote;

  /// No description provided for @wakeupTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Wakeup'**
  String get wakeupTitle;

  /// No description provided for @wakeupStartMyDay.
  ///
  /// In en, this message translates to:
  /// **'Start My Day'**
  String get wakeupStartMyDay;

  /// No description provided for @wakeupCongratulations.
  ///
  /// In en, this message translates to:
  /// **'Congratulations.'**
  String get wakeupCongratulations;

  /// No description provided for @wakeupThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks to Levio, you woke up today.'**
  String get wakeupThanks;

  /// No description provided for @wakeupTimeTaken.
  ///
  /// In en, this message translates to:
  /// **'Time Taken'**
  String get wakeupTimeTaken;

  /// No description provided for @wakeupDayStreak.
  ///
  /// In en, this message translates to:
  /// **'Day Streak'**
  String get wakeupDayStreak;

  /// No description provided for @wakeupWakeups.
  ///
  /// In en, this message translates to:
  /// **'Wakeups'**
  String get wakeupWakeups;

  /// No description provided for @wakeupDailyQuote.
  ///
  /// In en, this message translates to:
  /// **'Daily Quote'**
  String get wakeupDailyQuote;

  /// No description provided for @wakeupContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get wakeupContinue;

  /// No description provided for @wakeupWakeUp.
  ///
  /// In en, this message translates to:
  /// **'Wake Up'**
  String get wakeupWakeUp;

  /// No description provided for @sessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'All Wakeups'**
  String get sessionsTitle;

  /// No description provided for @sessionsNoWakeups.
  ///
  /// In en, this message translates to:
  /// **'No wakeups yet'**
  String get sessionsNoWakeups;

  /// No description provided for @sessionsMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get sessionsMissed;

  /// No description provided for @quoteEinstein.
  ///
  /// In en, this message translates to:
  /// **'In the middle of every difficulty lies opportunity.'**
  String get quoteEinstein;

  /// No description provided for @quoteEinsteinAuthor.
  ///
  /// In en, this message translates to:
  /// **'Albert Einstein'**
  String get quoteEinsteinAuthor;

  /// No description provided for @quoteTwain.
  ///
  /// In en, this message translates to:
  /// **'The secret of getting ahead is getting started.'**
  String get quoteTwain;

  /// No description provided for @quoteTwainAuthor.
  ///
  /// In en, this message translates to:
  /// **'Mark Twain'**
  String get quoteTwainAuthor;

  /// No description provided for @quoteConfucius.
  ///
  /// In en, this message translates to:
  /// **'It does not matter how slowly you go as long as you do not stop.'**
  String get quoteConfucius;

  /// No description provided for @quoteConfuciusAuthor.
  ///
  /// In en, this message translates to:
  /// **'Confucius'**
  String get quoteConfuciusAuthor;

  /// No description provided for @quoteChurchill.
  ///
  /// In en, this message translates to:
  /// **'Success is not final, failure is not fatal.'**
  String get quoteChurchill;

  /// No description provided for @quoteChurchillAuthor.
  ///
  /// In en, this message translates to:
  /// **'Winston Churchill'**
  String get quoteChurchillAuthor;

  /// No description provided for @quoteRoosevelt.
  ///
  /// In en, this message translates to:
  /// **'Believe you can and you\'re halfway there.'**
  String get quoteRoosevelt;

  /// No description provided for @quoteRooseveltAuthor.
  ///
  /// In en, this message translates to:
  /// **'Theodore Roosevelt'**
  String get quoteRooseveltAuthor;

  /// No description provided for @quoteJobs.
  ///
  /// In en, this message translates to:
  /// **'The only way to do great work is to love what you do.'**
  String get quoteJobs;

  /// No description provided for @quoteJobsAuthor.
  ///
  /// In en, this message translates to:
  /// **'Steve Jobs'**
  String get quoteJobsAuthor;

  /// No description provided for @quoteUnknown.
  ///
  /// In en, this message translates to:
  /// **'Wake up with determination, go to bed with satisfaction.'**
  String get quoteUnknown;

  /// No description provided for @quoteUnknownAuthor.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get quoteUnknownAuthor;

  /// No description provided for @quoteBuddha.
  ///
  /// In en, this message translates to:
  /// **'Every morning we are born again. What we do today matters most.'**
  String get quoteBuddha;

  /// No description provided for @quoteBuddhaAuthor.
  ///
  /// In en, this message translates to:
  /// **'Buddha'**
  String get quoteBuddhaAuthor;

  /// No description provided for @dismissStopAlarm.
  ///
  /// In en, this message translates to:
  /// **'Stop Alarm'**
  String get dismissStopAlarm;

  /// No description provided for @dismissShakePrompt.
  ///
  /// In en, this message translates to:
  /// **'Shake your phone to stop the alarm'**
  String get dismissShakePrompt;

  /// No description provided for @dismissMathProgress.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String dismissMathProgress(int current, int total);

  /// No description provided for @dismissMathWrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong — try again!'**
  String get dismissMathWrong;

  /// No description provided for @dismissMathConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get dismissMathConfirm;

  /// No description provided for @dismissPhotoPrompt.
  ///
  /// In en, this message translates to:
  /// **'Take a photo of {target} to stop the alarm'**
  String dismissPhotoPrompt(String target);

  /// No description provided for @dismissPhotoChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking for {target}…'**
  String dismissPhotoChecking(String target);

  /// No description provided for @dismissPhotoStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting camera…'**
  String get dismissPhotoStarting;

  /// No description provided for @dismissPhotoNotDetected.
  ///
  /// In en, this message translates to:
  /// **'No {target} detected — try again'**
  String dismissPhotoNotDetected(String target);

  /// No description provided for @dismissPhotoError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String dismissPhotoError(String error);

  /// No description provided for @dismissPhotoTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'TAKE A PHOTO OF'**
  String get dismissPhotoTakePhoto;

  /// No description provided for @dismissPhotoPickingTarget.
  ///
  /// In en, this message translates to:
  /// **'Picking your target…'**
  String get dismissPhotoPickingTarget;

  /// No description provided for @dismissSpeechSay.
  ///
  /// In en, this message translates to:
  /// **'Say:'**
  String get dismissSpeechSay;

  /// No description provided for @dismissSpeechListening.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get dismissSpeechListening;

  /// No description provided for @dismissSpeechTapToSpeak.
  ///
  /// In en, this message translates to:
  /// **'Tap to speak'**
  String get dismissSpeechTapToSpeak;

  /// No description provided for @dismissSpeechTryAgain.
  ///
  /// In en, this message translates to:
  /// **'{score}% — try again'**
  String dismissSpeechTryAgain(int score);

  /// No description provided for @dismissSpeechMicUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Microphone unavailable'**
  String get dismissSpeechMicUnavailable;

  /// No description provided for @dismissSpeechProgress.
  ///
  /// In en, this message translates to:
  /// **'{current}/{total}'**
  String dismissSpeechProgress(int current, int total);

  /// No description provided for @dismissRepStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting camera…'**
  String get dismissRepStarting;

  /// No description provided for @dismissRepPrompt.
  ///
  /// In en, this message translates to:
  /// **'Do {target} {mission} to stop the alarm'**
  String dismissRepPrompt(int target, String mission);

  /// No description provided for @dismissRepOf.
  ///
  /// In en, this message translates to:
  /// **'of {target}'**
  String dismissRepOf(int target);

  /// No description provided for @dismissMissionTimeToWakeUp.
  ///
  /// In en, this message translates to:
  /// **'Time to Wake Up!'**
  String get dismissMissionTimeToWakeUp;

  /// No description provided for @dismissMissionLabel.
  ///
  /// In en, this message translates to:
  /// **'Mission {current}/{total}: {name}'**
  String dismissMissionLabel(int current, int total, String name);

  /// No description provided for @dismissStartMission.
  ///
  /// In en, this message translates to:
  /// **'Start Mission'**
  String get dismissStartMission;

  /// No description provided for @dismissFeedbackMoveIntoFrame.
  ///
  /// In en, this message translates to:
  /// **'Move your whole body into frame'**
  String get dismissFeedbackMoveIntoFrame;

  /// No description provided for @dismissFeedbackKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'Yes, keep going!'**
  String get dismissFeedbackKeepGoing;

  /// No description provided for @dismissFeedbackPushupPosition.
  ///
  /// In en, this message translates to:
  /// **'Lie down in push-up position'**
  String get dismissFeedbackPushupPosition;

  /// No description provided for @dismissFeedbackStartPushups.
  ///
  /// In en, this message translates to:
  /// **'Start doing your push-ups!'**
  String get dismissFeedbackStartPushups;

  /// No description provided for @dismissFeedbackPushupGoDeeper.
  ///
  /// In en, this message translates to:
  /// **'Go deeper, your chest should touch the ground!'**
  String get dismissFeedbackPushupGoDeeper;

  /// No description provided for @dismissFeedbackSquatPosition.
  ///
  /// In en, this message translates to:
  /// **'Stand up to start squats'**
  String get dismissFeedbackSquatPosition;

  /// No description provided for @dismissFeedbackStartSquats.
  ///
  /// In en, this message translates to:
  /// **'Start doing your squats!'**
  String get dismissFeedbackStartSquats;

  /// No description provided for @dismissFeedbackSquatGoDeeper.
  ///
  /// In en, this message translates to:
  /// **'Go deeper, your thighs should be parallel to the ground!'**
  String get dismissFeedbackSquatGoDeeper;

  /// No description provided for @onboardingMorningPerson.
  ///
  /// In en, this message translates to:
  /// **'Do you feel like a morning person?'**
  String get onboardingMorningPerson;

  /// No description provided for @onboardingYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get onboardingYes;

  /// No description provided for @onboardingNotYet.
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get onboardingNotYet;

  /// No description provided for @onboardingAgeRange.
  ///
  /// In en, this message translates to:
  /// **'What\'s your age range?'**
  String get onboardingAgeRange;

  /// No description provided for @onboardingDescribesYou.
  ///
  /// In en, this message translates to:
  /// **'What best describes you?'**
  String get onboardingDescribesYou;

  /// No description provided for @onboardingMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get onboardingMale;

  /// No description provided for @onboardingFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get onboardingFemale;

  /// No description provided for @onboardingOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get onboardingOther;

  /// No description provided for @onboardingKeepsInBed.
  ///
  /// In en, this message translates to:
  /// **'What keeps you in bed after the alarm?'**
  String get onboardingKeepsInBed;

  /// No description provided for @onboardingPhoneScrolling.
  ///
  /// In en, this message translates to:
  /// **'Phone scrolling'**
  String get onboardingPhoneScrolling;

  /// No description provided for @onboardingSnoozeLoop.
  ///
  /// In en, this message translates to:
  /// **'Snooze loop'**
  String get onboardingSnoozeLoop;

  /// No description provided for @onboardingSleepThrough.
  ///
  /// In en, this message translates to:
  /// **'Sleep through alarms'**
  String get onboardingSleepThrough;

  /// No description provided for @onboardingStayInBed.
  ///
  /// In en, this message translates to:
  /// **'I wake up but stay in bed'**
  String get onboardingStayInBed;

  /// No description provided for @onboardingFirstThought.
  ///
  /// In en, this message translates to:
  /// **'First thought when the alarm goes off?'**
  String get onboardingFirstThought;

  /// No description provided for @onboardingImUp.
  ///
  /// In en, this message translates to:
  /// **'I\'m up'**
  String get onboardingImUp;

  /// No description provided for @onboardingFiveMore.
  ///
  /// In en, this message translates to:
  /// **'Just 5 more minutes'**
  String get onboardingFiveMore;

  /// No description provided for @onboardingSetAnother.
  ///
  /// In en, this message translates to:
  /// **'I\'ll set another alarm'**
  String get onboardingSetAnother;

  /// No description provided for @onboardingWhyDidI.
  ///
  /// In en, this message translates to:
  /// **'Why did I do this?'**
  String get onboardingWhyDidI;

  /// No description provided for @onboardingGetsYouOut.
  ///
  /// In en, this message translates to:
  /// **'Levio gets you out of bed'**
  String get onboardingGetsYouOut;

  /// No description provided for @onboardingAvoidGroggy.
  ///
  /// In en, this message translates to:
  /// **'Avoid the \'groggy zone\'. Levio launches you straight into alertness.'**
  String get onboardingAvoidGroggy;

  /// No description provided for @onboardingHowManyAlarms.
  ///
  /// In en, this message translates to:
  /// **'How many alarms do you set?'**
  String get onboardingHowManyAlarms;

  /// No description provided for @onboardingOne.
  ///
  /// In en, this message translates to:
  /// **'One'**
  String get onboardingOne;

  /// No description provided for @onboardingTwoThree.
  ///
  /// In en, this message translates to:
  /// **'2-3'**
  String get onboardingTwoThree;

  /// No description provided for @onboardingFourPlus.
  ///
  /// In en, this message translates to:
  /// **'4+'**
  String get onboardingFourPlus;

  /// No description provided for @onboardingOneAlarmWakeUp.
  ///
  /// In en, this message translates to:
  /// **'If you set one alarm, would you wake up?'**
  String get onboardingOneAlarmWakeUp;

  /// No description provided for @onboardingSometimes.
  ///
  /// In en, this message translates to:
  /// **'Sometimes'**
  String get onboardingSometimes;

  /// No description provided for @onboardingNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get onboardingNo;

  /// No description provided for @onboardingTurnOffGoBack.
  ///
  /// In en, this message translates to:
  /// **'Do you ever turn off the alarm and go back to sleep?'**
  String get onboardingTurnOffGoBack;

  /// No description provided for @onboardingOften.
  ///
  /// In en, this message translates to:
  /// **'Often'**
  String get onboardingOften;

  /// No description provided for @onboardingRarely.
  ///
  /// In en, this message translates to:
  /// **'Rarely'**
  String get onboardingRarely;

  /// No description provided for @onboardingNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get onboardingNever;

  /// No description provided for @onboardingOneAlarmOneMission.
  ///
  /// In en, this message translates to:
  /// **'One alarm. One mission.'**
  String get onboardingOneAlarmOneMission;

  /// No description provided for @onboardingFeelSettingAlarm.
  ///
  /// In en, this message translates to:
  /// **'How do you feel setting your alarm at night?'**
  String get onboardingFeelSettingAlarm;

  /// No description provided for @onboardingMotivated.
  ///
  /// In en, this message translates to:
  /// **'Motivated'**
  String get onboardingMotivated;

  /// No description provided for @onboardingAnxiousSleep.
  ///
  /// In en, this message translates to:
  /// **'Anxious about sleep'**
  String get onboardingAnxiousSleep;

  /// No description provided for @onboardingDefeated.
  ///
  /// In en, this message translates to:
  /// **'Defeated'**
  String get onboardingDefeated;

  /// No description provided for @onboardingNeutral.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get onboardingNeutral;

  /// No description provided for @onboardingFeelAfterWaking.
  ///
  /// In en, this message translates to:
  /// **'How do you feel right after waking up?'**
  String get onboardingFeelAfterWaking;

  /// No description provided for @onboardingReadyToGo.
  ///
  /// In en, this message translates to:
  /// **'Ready to go'**
  String get onboardingReadyToGo;

  /// No description provided for @onboardingGroggy.
  ///
  /// In en, this message translates to:
  /// **'Groggy'**
  String get onboardingGroggy;

  /// No description provided for @onboardingAnxiousStressed.
  ///
  /// In en, this message translates to:
  /// **'Anxious or stressed'**
  String get onboardingAnxiousStressed;

  /// No description provided for @onboardingHowLongAwake.
  ///
  /// In en, this message translates to:
  /// **'How long until you feel fully awake?'**
  String get onboardingHowLongAwake;

  /// No description provided for @onboardingInstantly.
  ///
  /// In en, this message translates to:
  /// **'Instantly'**
  String get onboardingInstantly;

  /// No description provided for @onboardingTenFifteen.
  ///
  /// In en, this message translates to:
  /// **'10-15 minutes'**
  String get onboardingTenFifteen;

  /// No description provided for @onboardingThirtyPlus.
  ///
  /// In en, this message translates to:
  /// **'30 minutes or more'**
  String get onboardingThirtyPlus;

  /// No description provided for @onboardingBiologyTitle.
  ///
  /// In en, this message translates to:
  /// **'Biology, Not Laziness'**
  String get onboardingBiologyTitle;

  /// No description provided for @onboardingBiologyBody.
  ///
  /// In en, this message translates to:
  /// **'Your brain takes 15–30 min to clear sleep inertia. Snoozing resets the cycle, making it worse.\n\nLevio forces immediate action — skipping the groggy zone entirely.'**
  String get onboardingBiologyBody;

  /// No description provided for @onboarding5xFaster.
  ///
  /// In en, this message translates to:
  /// **'Get out of bed 5x faster with Levio vs on your own'**
  String get onboarding5xFaster;

  /// No description provided for @onboardingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get onboardingContinue;

  /// No description provided for @onboardingSetAlarmFor.
  ///
  /// In en, this message translates to:
  /// **'Set alarm for {time}'**
  String onboardingSetAlarmFor(String time);

  /// No description provided for @onboardingAlarmDuringMission.
  ///
  /// In en, this message translates to:
  /// **'Play your alarm during the mission?'**
  String get onboardingAlarmDuringMission;

  /// No description provided for @onboardingAlarmKeepRinging.
  ///
  /// In en, this message translates to:
  /// **'Keep alarm ringing while completing the mission.'**
  String get onboardingAlarmKeepRinging;

  /// No description provided for @onboardingAlarmStopRinging.
  ///
  /// In en, this message translates to:
  /// **'Stop alarm ringing unless I leave the app during the mission.'**
  String get onboardingAlarmStopRinging;

  /// No description provided for @onboardingWhereHeard.
  ///
  /// In en, this message translates to:
  /// **'Where did you hear about us?'**
  String get onboardingWhereHeard;

  /// No description provided for @onboardingYouTube.
  ///
  /// In en, this message translates to:
  /// **'YouTube'**
  String get onboardingYouTube;

  /// No description provided for @onboardingFacebook.
  ///
  /// In en, this message translates to:
  /// **'Facebook'**
  String get onboardingFacebook;

  /// No description provided for @onboardingTwitter.
  ///
  /// In en, this message translates to:
  /// **'Twitter'**
  String get onboardingTwitter;

  /// No description provided for @onboardingReddit.
  ///
  /// In en, this message translates to:
  /// **'Reddit'**
  String get onboardingReddit;

  /// No description provided for @onboardingAppStore.
  ///
  /// In en, this message translates to:
  /// **'App Store'**
  String get onboardingAppStore;

  /// No description provided for @onboardingFriendFamily.
  ///
  /// In en, this message translates to:
  /// **'Friend or family'**
  String get onboardingFriendFamily;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Stop hitting snooze.\nStart winning mornings.'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'One alarm. One mission. You\'re up.'**
  String get onboardingWelcomeSubtitle;

  /// No description provided for @onboardingBuildPlan.
  ///
  /// In en, this message translates to:
  /// **'Build my plan'**
  String get onboardingBuildPlan;

  /// No description provided for @onboardingJoin500k.
  ///
  /// In en, this message translates to:
  /// **'Join 500k+ people waking up with Levio'**
  String get onboardingJoin500k;

  /// No description provided for @onboardingAlreadyAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get onboardingAlreadyAccount;

  /// No description provided for @onboardingSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get onboardingSignIn;

  /// No description provided for @onboardingSignInApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get onboardingSignInApple;

  /// No description provided for @onboardingSignInGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get onboardingSignInGoogle;

  /// No description provided for @onboardingSkipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get onboardingSkipForNow;

  /// No description provided for @onboardingGoogleFailed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed. Please try again.'**
  String get onboardingGoogleFailed;

  /// No description provided for @onboardingAppleFailed.
  ///
  /// In en, this message translates to:
  /// **'Apple sign-in failed. Please try again.'**
  String get onboardingAppleFailed;

  /// No description provided for @onboardingAccountNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found. Please complete onboarding to create one.'**
  String get onboardingAccountNotFound;

  /// No description provided for @onboardingDayPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Which days should Levio ring?'**
  String get onboardingDayPickerTitle;

  /// No description provided for @onboardingDayPickerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick the days you want to lock in.'**
  String get onboardingDayPickerSubtitle;

  /// No description provided for @onboardingLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Setting everything up\nfor you'**
  String get onboardingLoadingTitle;

  /// No description provided for @onboardingLoadingStep1.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your sleep habits'**
  String get onboardingLoadingStep1;

  /// No description provided for @onboardingLoadingStep2.
  ///
  /// In en, this message translates to:
  /// **'Configuring your goals'**
  String get onboardingLoadingStep2;

  /// No description provided for @onboardingLoadingStep3.
  ///
  /// In en, this message translates to:
  /// **'Setting your mission'**
  String get onboardingLoadingStep3;

  /// No description provided for @onboardingLoadingStep4.
  ///
  /// In en, this message translates to:
  /// **'Calibrating alarm tone'**
  String get onboardingLoadingStep4;

  /// No description provided for @onboardingLoadingStep5.
  ///
  /// In en, this message translates to:
  /// **'Scheduling your alarm'**
  String get onboardingLoadingStep5;

  /// No description provided for @onboardingLoadingStep6.
  ///
  /// In en, this message translates to:
  /// **'Finalizing your plan'**
  String get onboardingLoadingStep6;

  /// No description provided for @onboardingMissionPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your wake up mission'**
  String get onboardingMissionPickerTitle;

  /// No description provided for @onboardingMissionPickerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ll do this to turn off your alarm.'**
  String get onboardingMissionPickerSubtitle;

  /// No description provided for @onboardingMorningPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Morning Plan'**
  String get onboardingMorningPlanTitle;

  /// No description provided for @onboardingMorningPlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Here\'s what tomorrow looks like at {time}'**
  String onboardingMorningPlanSubtitle(String time);

  /// No description provided for @onboardingStartsIn.
  ///
  /// In en, this message translates to:
  /// **'Starts in {countdown}'**
  String onboardingStartsIn(String countdown);

  /// No description provided for @onboardingHeresTomorrow.
  ///
  /// In en, this message translates to:
  /// **'HERE\'S TOMORROW'**
  String get onboardingHeresTomorrow;

  /// No description provided for @onboardingAlarmRings.
  ///
  /// In en, this message translates to:
  /// **'{time} — Alarm rings'**
  String onboardingAlarmRings(String time);

  /// No description provided for @onboardingCompleteMission.
  ///
  /// In en, this message translates to:
  /// **'Complete {mission}'**
  String onboardingCompleteMission(String mission);

  /// No description provided for @onboardingYoureUp.
  ///
  /// In en, this message translates to:
  /// **'You\'re up. Day started.'**
  String get onboardingYoureUp;

  /// No description provided for @onboardingNoSnooze.
  ///
  /// In en, this message translates to:
  /// **'No snooze loops. One action, then your day starts with momentum.'**
  String get onboardingNoSnooze;

  /// No description provided for @onboardingWakeReceipt.
  ///
  /// In en, this message translates to:
  /// **'Wake Receipt\n(Image placeholder)'**
  String get onboardingWakeReceipt;

  /// No description provided for @onboardingRiseAndRepeat.
  ///
  /// In en, this message translates to:
  /// **'Rise and repeat.'**
  String get onboardingRiseAndRepeat;

  /// No description provided for @onboardingAlarmFrequency.
  ///
  /// In en, this message translates to:
  /// **'Your alarm fires {count}x a week. Build the streak.'**
  String onboardingAlarmFrequency(int count);

  /// No description provided for @onboardingNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Stay on track with reminders'**
  String get onboardingNotificationTitle;

  /// No description provided for @onboardingNotificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a gentle nudge so you never miss your wake-up time.'**
  String get onboardingNotificationSubtitle;

  /// No description provided for @onboardingNotificationEnable.
  ///
  /// In en, this message translates to:
  /// **'Enable'**
  String get onboardingNotificationEnable;

  /// No description provided for @onboardingNotificationNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get onboardingNotificationNotNow;

  /// No description provided for @onboardingPaywallTitle.
  ///
  /// In en, this message translates to:
  /// **'We want you to\ntry Levio for free.'**
  String get onboardingPaywallTitle;

  /// No description provided for @onboardingPaywallSecondsRemaining.
  ///
  /// In en, this message translates to:
  /// **'seconds remaining'**
  String get onboardingPaywallSecondsRemaining;

  /// No description provided for @onboardingPaywallKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going! Do your push ups'**
  String get onboardingPaywallKeepGoing;

  /// No description provided for @onboardingPaywallNoPayment.
  ///
  /// In en, this message translates to:
  /// **'No Payment Due Now'**
  String get onboardingPaywallNoPayment;

  /// No description provided for @onboardingPaywallTryFree.
  ///
  /// In en, this message translates to:
  /// **'Try For \$0.00'**
  String get onboardingPaywallTryFree;

  /// No description provided for @onboardingPaywallNoCommitment.
  ///
  /// In en, this message translates to:
  /// **'No commitment, cancel anytime.'**
  String get onboardingPaywallNoCommitment;

  /// No description provided for @onboardingPaywallPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get onboardingPaywallPrivacy;

  /// No description provided for @onboardingPaywallRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchase'**
  String get onboardingPaywallRestore;

  /// No description provided for @onboardingPaywallTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get onboardingPaywallTerms;

  /// No description provided for @onboardingPaywallEula.
  ///
  /// In en, this message translates to:
  /// **'EULA'**
  String get onboardingPaywallEula;

  /// No description provided for @onboardingRatingTitle.
  ///
  /// In en, this message translates to:
  /// **'Give us a rating'**
  String get onboardingRatingTitle;

  /// No description provided for @onboardingRatingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Levio was made for\npeople like you'**
  String get onboardingRatingSubtitle;

  /// No description provided for @onboardingRatingMarc.
  ///
  /// In en, this message translates to:
  /// **'Marc L.'**
  String get onboardingRatingMarc;

  /// No description provided for @onboardingRatingMarcReview.
  ///
  /// In en, this message translates to:
  /// **'I used to set 5 alarms every morning. Now I wake up on the first one and actually feel good about it.'**
  String get onboardingRatingMarcReview;

  /// No description provided for @onboardingRatingSophie.
  ///
  /// In en, this message translates to:
  /// **'Sophie D.'**
  String get onboardingRatingSophie;

  /// No description provided for @onboardingRatingSophieReview.
  ///
  /// In en, this message translates to:
  /// **'The mission feature is brilliant. Doing push-ups at 6am sounds crazy, but it genuinely wakes me up faster than coffee.'**
  String get onboardingRatingSophieReview;

  /// No description provided for @onboardingRatingAlex.
  ///
  /// In en, this message translates to:
  /// **'Alex T.'**
  String get onboardingRatingAlex;

  /// No description provided for @onboardingRatingAlexReview.
  ///
  /// In en, this message translates to:
  /// **'Finally an alarm app that actually works. I\'ve tried everything and Levio is the only one that gets me out of bed.'**
  String get onboardingRatingAlexReview;

  /// No description provided for @onboardingReferralTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter referral code\n(optional)'**
  String get onboardingReferralTitle;

  /// No description provided for @onboardingReferralSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can skip this step'**
  String get onboardingReferralSubtitle;

  /// No description provided for @onboardingReferralLabel.
  ///
  /// In en, this message translates to:
  /// **'Referral Code'**
  String get onboardingReferralLabel;

  /// No description provided for @onboardingReferralSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get onboardingReferralSubmit;

  /// No description provided for @onboardingReferralApplied.
  ///
  /// In en, this message translates to:
  /// **'Referral code applied!'**
  String get onboardingReferralApplied;

  /// No description provided for @onboardingReferralInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid referral code'**
  String get onboardingReferralInvalid;

  /// No description provided for @onboardingReferralLimit.
  ///
  /// In en, this message translates to:
  /// **'This code has reached its usage limit'**
  String get onboardingReferralLimit;

  /// No description provided for @onboardingSignatureTitle.
  ///
  /// In en, this message translates to:
  /// **'Lock in your\ncommitment'**
  String get onboardingSignatureTitle;

  /// No description provided for @onboardingSignatureSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign below to get out of bed at {time}. Feet on the floor.'**
  String onboardingSignatureSubtitle(String time);

  /// No description provided for @onboardingSignatureCommit.
  ///
  /// In en, this message translates to:
  /// **'I Commit'**
  String get onboardingSignatureCommit;

  /// No description provided for @onboardingTimePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Set your first Levio time'**
  String get onboardingTimePickerTitle;

  /// No description provided for @onboardingTimePickerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll wake you at {time} with your mission.'**
  String onboardingTimePickerSubtitle(String time);

  /// No description provided for @onboardingSoundPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick your alarm sound'**
  String get onboardingSoundPickerTitle;

  /// No description provided for @onboardingTimelineTypical.
  ///
  /// In en, this message translates to:
  /// **'TYPICAL MORNING'**
  String get onboardingTimelineTypical;

  /// No description provided for @onboardingTimelineLevio.
  ///
  /// In en, this message translates to:
  /// **'LEVIO MORNING'**
  String get onboardingTimelineLevio;

  /// No description provided for @onboardingTimelineAlarm.
  ///
  /// In en, this message translates to:
  /// **'Alarm'**
  String get onboardingTimelineAlarm;

  /// No description provided for @onboardingTimelineSnooze.
  ///
  /// In en, this message translates to:
  /// **'Snooze'**
  String get onboardingTimelineSnooze;

  /// No description provided for @onboardingTimelinePanic.
  ///
  /// In en, this message translates to:
  /// **'Panic'**
  String get onboardingTimelinePanic;

  /// No description provided for @onboardingTimelineMission.
  ///
  /// In en, this message translates to:
  /// **'Mission'**
  String get onboardingTimelineMission;

  /// No description provided for @onboardingTimelineStarted.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get onboardingTimelineStarted;

  /// No description provided for @onboardingTimelineGained.
  ///
  /// In en, this message translates to:
  /// **'GAINED'**
  String get onboardingTimelineGained;

  /// No description provided for @onboardingTimelineMins.
  ///
  /// In en, this message translates to:
  /// **'25 MINS'**
  String get onboardingTimelineMins;

  /// No description provided for @onboardingTrialTitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send you\na reminder before\nyour free trial ends'**
  String get onboardingTrialTitle;

  /// No description provided for @onboardingTrialNoPayment.
  ///
  /// In en, this message translates to:
  /// **'No Payment Due Now'**
  String get onboardingTrialNoPayment;

  /// No description provided for @onboardingTrialContinueFree.
  ///
  /// In en, this message translates to:
  /// **'Continue For Free'**
  String get onboardingTrialContinueFree;

  /// No description provided for @onboardingTrialPrice.
  ///
  /// In en, this message translates to:
  /// **'Just \$29.99 per year (\$2.50/mo)'**
  String get onboardingTrialPrice;

  /// No description provided for @onboardingEnergyTitle.
  ///
  /// In en, this message translates to:
  /// **'Morning Energy Levels'**
  String get onboardingEnergyTitle;

  /// No description provided for @onboardingEnergyLevio.
  ///
  /// In en, this message translates to:
  /// **'Levio Protocol'**
  String get onboardingEnergyLevio;

  /// No description provided for @onboardingEnergySnoozeCycle.
  ///
  /// In en, this message translates to:
  /// **'Snooze Cycle'**
  String get onboardingEnergySnoozeCycle;

  /// No description provided for @onboardingEnergyGroggyZone.
  ///
  /// In en, this message translates to:
  /// **'GROGGY ZONE'**
  String get onboardingEnergyGroggyZone;

  /// No description provided for @onboardingSpeedometerSlow.
  ///
  /// In en, this message translates to:
  /// **'Slow'**
  String get onboardingSpeedometerSlow;

  /// No description provided for @onboardingSpeedometerGroggy.
  ///
  /// In en, this message translates to:
  /// **'Groggy'**
  String get onboardingSpeedometerGroggy;

  /// No description provided for @onboardingSpeedometerInstant.
  ///
  /// In en, this message translates to:
  /// **'Instant'**
  String get onboardingSpeedometerInstant;

  /// No description provided for @onboardingSpeedometerActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get onboardingSpeedometerActive;

  /// No description provided for @onboardingSpeedometerBody.
  ///
  /// In en, this message translates to:
  /// **'Levio eliminates snooze friction for\ninstant wake ups.'**
  String get onboardingSpeedometerBody;

  /// No description provided for @onboardingSpeedometerFaster.
  ///
  /// In en, this message translates to:
  /// **'FASTER'**
  String get onboardingSpeedometerFaster;

  /// No description provided for @onboardingSpeedometerMultiplier.
  ///
  /// In en, this message translates to:
  /// **'5.0x'**
  String get onboardingSpeedometerMultiplier;

  /// No description provided for @missionExplPushUpsTitle.
  ///
  /// In en, this message translates to:
  /// **'Why doing push ups wakes you up'**
  String get missionExplPushUpsTitle;

  /// No description provided for @missionExplPushUpsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Gets your blood pumping right away'**
  String get missionExplPushUpsSubtitle;

  /// No description provided for @missionExplPushUpsBody.
  ///
  /// In en, this message translates to:
  /// **'Push-ups activate your chest, arms, and core — flooding your brain with oxygen and spiking your heart rate. Within seconds, your body shifts from sleep mode to fully alert. It\'s the fastest way to kill morning grogginess.'**
  String get missionExplPushUpsBody;

  /// No description provided for @missionExplSquatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Why doing squats wakes you up'**
  String get missionExplSquatsTitle;

  /// No description provided for @missionExplSquatsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Activates your largest muscles'**
  String get missionExplSquatsSubtitle;

  /// No description provided for @missionExplSquatsBody.
  ///
  /// In en, this message translates to:
  /// **'Squats fire up your glutes, quads, and hamstrings — the biggest muscle groups in your body. This triggers a rush of blood flow and raises your core temperature fast. Your brain gets the signal: it\'s go time.'**
  String get missionExplSquatsBody;

  /// No description provided for @missionExplShakeTitle.
  ///
  /// In en, this message translates to:
  /// **'Why shaking your phone wakes you up'**
  String get missionExplShakeTitle;

  /// No description provided for @missionExplShakeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Forces you to move'**
  String get missionExplShakeSubtitle;

  /// No description provided for @missionExplShakeBody.
  ///
  /// In en, this message translates to:
  /// **'Shaking your phone forces arm movement and coordination, pulling your brain out of autopilot. The repetitive motion activates your motor cortex and gets your blood circulating — turning a groggy moment into physical engagement.'**
  String get missionExplShakeBody;

  /// No description provided for @missionExplMathTitle.
  ///
  /// In en, this message translates to:
  /// **'Why solving math wakes you up'**
  String get missionExplMathTitle;

  /// No description provided for @missionExplMathSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Wakes up your brain'**
  String get missionExplMathSubtitle;

  /// No description provided for @missionExplMathBody.
  ///
  /// In en, this message translates to:
  /// **'Math problems force your prefrontal cortex to engage — the part of your brain responsible for logic and decision-making. Even simple arithmetic snaps you out of sleep inertia by demanding focused, conscious thought.'**
  String get missionExplMathBody;

  /// No description provided for @missionExplSkyPhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Why taking a sky photo wakes you up'**
  String get missionExplSkyPhotoTitle;

  /// No description provided for @missionExplSkyPhotoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Gets you to the window'**
  String get missionExplSkyPhotoSubtitle;

  /// No description provided for @missionExplSkyPhotoBody.
  ///
  /// In en, this message translates to:
  /// **'Walking to a window and looking at the sky exposes you to natural light — the most powerful signal to shut down melatonin production. Even on cloudy days, outdoor light intensity is far greater than indoor lighting, resetting your circadian clock fast.'**
  String get missionExplSkyPhotoBody;

  /// No description provided for @missionExplMakeBedTitle.
  ///
  /// In en, this message translates to:
  /// **'Why making your bed wakes you up'**
  String get missionExplMakeBedTitle;

  /// No description provided for @missionExplMakeBedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Starts your day with a win'**
  String get missionExplMakeBedSubtitle;

  /// No description provided for @missionExplMakeBedBody.
  ///
  /// In en, this message translates to:
  /// **'Making your bed is a micro-accomplishment that triggers a small dopamine hit. It signals to your brain that the day has started and removes the temptation to climb back in. One completed task creates momentum for the next.'**
  String get missionExplMakeBedBody;

  /// No description provided for @missionExplObjectHuntTitle.
  ///
  /// In en, this message translates to:
  /// **'Why an object hunt wakes you up'**
  String get missionExplObjectHuntTitle;

  /// No description provided for @missionExplObjectHuntSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Gets you out of bed'**
  String get missionExplObjectHuntSubtitle;

  /// No description provided for @missionExplObjectHuntBody.
  ///
  /// In en, this message translates to:
  /// **'Searching for a specific object forces you out of bed and into motion. Your brain switches from passive rest to active problem-solving — scanning, recognizing, and moving. By the time you find it, sleep inertia is gone.'**
  String get missionExplObjectHuntBody;

  /// No description provided for @missionExplPetHuntTitle.
  ///
  /// In en, this message translates to:
  /// **'Why finding your pet wakes you up'**
  String get missionExplPetHuntTitle;

  /// No description provided for @missionExplPetHuntSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Morning bonding time'**
  String get missionExplPetHuntSubtitle;

  /// No description provided for @missionExplPetHuntBody.
  ///
  /// In en, this message translates to:
  /// **'Interacting with your pet releases oxytocin — the bonding hormone that naturally elevates your mood and alertness. Moving through your home to find them adds physical activity, while the emotional connection gives your morning a positive anchor.'**
  String get missionExplPetHuntBody;

  /// No description provided for @missionExplNatureHuntTitle.
  ///
  /// In en, this message translates to:
  /// **'Why a nature hunt wakes you up'**
  String get missionExplNatureHuntTitle;

  /// No description provided for @missionExplNatureHuntSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Connects you to the outdoors'**
  String get missionExplNatureHuntSubtitle;

  /// No description provided for @missionExplNatureHuntBody.
  ///
  /// In en, this message translates to:
  /// **'Stepping outside to find something in nature combines movement, fresh air, and natural light — the three most effective wake-up signals. The sensory shift from bedroom to outdoors jolts your nervous system into full alertness.'**
  String get missionExplNatureHuntBody;

  /// No description provided for @missionExplTouchGrassTitle.
  ///
  /// In en, this message translates to:
  /// **'Why touching grass wakes you up'**
  String get missionExplTouchGrassTitle;

  /// No description provided for @missionExplTouchGrassSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ground yourself in the morning'**
  String get missionExplTouchGrassSubtitle;

  /// No description provided for @missionExplTouchGrassBody.
  ///
  /// In en, this message translates to:
  /// **'Going outside to photograph grass exposes you to sunlight and fresh air simultaneously. The act of bending down and focusing on nature engages your body and senses, creating a full mind-body wake-up that no alarm sound can match.'**
  String get missionExplTouchGrassBody;

  /// No description provided for @missionExplAffirmationTitle.
  ///
  /// In en, this message translates to:
  /// **'Why affirmations wake you up'**
  String get missionExplAffirmationTitle;

  /// No description provided for @missionExplAffirmationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sets your mindset for the day'**
  String get missionExplAffirmationSubtitle;

  /// No description provided for @missionExplAffirmationBody.
  ///
  /// In en, this message translates to:
  /// **'Speaking an affirmation out loud activates your voice, breath, and focus simultaneously. The act of reading and repeating engages multiple brain regions — shifting you from passive drowsiness to intentional, conscious thought.'**
  String get missionExplAffirmationBody;

  /// No description provided for @generalOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get generalOk;

  /// No description provided for @generalCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get generalCancel;

  /// No description provided for @generalSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get generalSubmit;

  /// No description provided for @generalContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get generalContinue;

  /// No description provided for @generalNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get generalNone;

  /// No description provided for @generalDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get generalDefault;

  /// No description provided for @generalDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get generalDelete;

  /// No description provided for @onboardingUsualWakeTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'What time do you usually get out of bed?'**
  String get onboardingUsualWakeTimeTitle;

  /// No description provided for @onboardingUsualWakeTimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This helps us set a realistic first target.'**
  String get onboardingUsualWakeTimeSubtitle;

  /// No description provided for @onboardingIdealWakeTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'What time do you want to\nbe up?'**
  String get onboardingIdealWakeTimeTitle;

  /// No description provided for @onboardingIdealWakeTimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your ideal daily wake up time.'**
  String get onboardingIdealWakeTimeSubtitle;

  /// No description provided for @onboardingTargetWakeTime.
  ///
  /// In en, this message translates to:
  /// **'Waking up at {time} is your target.'**
  String onboardingTargetWakeTime(String time);

  /// No description provided for @onboardingDeltaPerMorning.
  ///
  /// In en, this message translates to:
  /// **'+{delta} minutes every morning'**
  String onboardingDeltaPerMorning(int delta);

  /// No description provided for @onboardingDeltaPerMonth.
  ///
  /// In en, this message translates to:
  /// **'+{hours} hours this month'**
  String onboardingDeltaPerMonth(int hours);

  /// No description provided for @onboardingQuoteWinMorning.
  ///
  /// In en, this message translates to:
  /// **'If you win\nthe morning,\nyou win the day.'**
  String get onboardingQuoteWinMorning;

  /// No description provided for @onboardingQuoteWinMorningAuthor.
  ///
  /// In en, this message translates to:
  /// **'— Tim Ferriss'**
  String get onboardingQuoteWinMorningAuthor;

  /// No description provided for @onboardingSignInCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get onboardingSignInCreateTitle;

  /// No description provided for @onboardingSignInCreateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save your progress and sync your plan.'**
  String get onboardingSignInCreateSubtitle;

  /// No description provided for @onboardingSignInTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get onboardingSignInTitle;

  /// No description provided for @onboardingSignInSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to restore your plan.'**
  String get onboardingSignInSubtitle;

  /// No description provided for @soundPickerFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File too large (max 10 MB)'**
  String get soundPickerFileTooLarge;

  /// No description provided for @soundPickerDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Sound'**
  String get soundPickerDeleteTitle;

  /// No description provided for @soundPickerDeleteContent.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\"?'**
  String soundPickerDeleteContent(String name);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
