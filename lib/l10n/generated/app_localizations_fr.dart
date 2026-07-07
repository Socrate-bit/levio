// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Levio';

  @override
  String get navHome => 'Accueil';

  @override
  String get navAlarms => 'Alarmes';

  @override
  String get navInsights => 'Statistiques';

  @override
  String get navSettings => 'Réglages';

  @override
  String get alarmsTitle => 'Alarmes';

  @override
  String get alarmsEmpty => 'Aucune alarme';

  @override
  String get alarmsEmptyHint => 'Appuie sur + pour créer ta première alarme';

  @override
  String get alarmsMissionAlarm => 'Alarme Mission';

  @override
  String get alarmsMissionAlarmSubtitle => 'Complète une tâche d\'abord';

  @override
  String get alarmsNormalAlarm => 'Alarme Normale';

  @override
  String get alarmsNormalAlarmSubtitle => 'Juste une alarme';

  @override
  String alarmsDefaultName(int number) {
    return 'Alarme #$number';
  }

  @override
  String alarmsMissionsCount(int count) {
    return '$count Missions';
  }

  @override
  String get alarmsOneTime => 'Une fois';

  @override
  String get alarmsEveryDay => 'Tous les jours';

  @override
  String get alarmsWeekdays => 'Lun, Mar, Mer, Jeu, Ven';

  @override
  String get daySun => 'Dim';

  @override
  String get dayMon => 'Lun';

  @override
  String get dayTue => 'Mar';

  @override
  String get dayWed => 'Mer';

  @override
  String get dayThu => 'Jeu';

  @override
  String get dayFri => 'Ven';

  @override
  String get daySat => 'Sam';

  @override
  String get daySundayFull => 'Dimanche';

  @override
  String get dayMondayFull => 'Lundi';

  @override
  String get dayTuesdayFull => 'Mardi';

  @override
  String get dayWednesdayFull => 'Mercredi';

  @override
  String get dayThursdayFull => 'Jeudi';

  @override
  String get dayFridayFull => 'Vendredi';

  @override
  String get daySaturdayFull => 'Samedi';

  @override
  String get daySingleSun => 'D';

  @override
  String get daySingleMon => 'L';

  @override
  String get daySingleTue => 'M';

  @override
  String get daySingleWed => 'M';

  @override
  String get daySingleThu => 'J';

  @override
  String get daySingleFri => 'V';

  @override
  String get daySingleSat => 'S';

  @override
  String get alarmFormSetTime => 'Régler l\'heure';

  @override
  String get alarmFormDone => 'Terminé';

  @override
  String get alarmFormEditAlarm => 'Modifier l\'alarme';

  @override
  String get alarmFormNewAlarm => 'Nouvelle alarme';

  @override
  String get alarmFormAlarmName => 'Nom de l\'alarme';

  @override
  String get alarmFormAlarmTime => 'Heure de l\'alarme';

  @override
  String get alarmFormScheduled => '↻  Programmée';

  @override
  String get alarmFormOneTime => '📅  Une fois';

  @override
  String get alarmFormRepeatOn => 'Répéter les :';

  @override
  String alarmFormAddMission(int count) {
    return 'Ajouter une mission ($count sur 3)';
  }

  @override
  String get alarmFormStackMissions =>
      'Empile les missions et complète-les pour éteindre l\'alarme';

  @override
  String get alarmFormSound => 'Son';

  @override
  String get alarmFormUpdateAlarm => 'Modifier l\'alarme';

  @override
  String get alarmFormSaveAlarm => 'Enregistrer l\'alarme';

  @override
  String alarmFormMissionIndex(int index) {
    return 'Mission $index';
  }

  @override
  String get alarmFormWakeUp => 'Réveil';

  @override
  String get alarmFormSleep => 'Sommeil';

  @override
  String get alarmFormRingStyle => 'Type de sonnerie';

  @override
  String get alarmFormGentle => 'Douce';

  @override
  String get alarmFormLoud => 'Forte';

  @override
  String get alarmFormReminder => 'Rappel du coucher';

  @override
  String get alarmFormReminderHint => 'Sois notifié avant que l\'alarme sonne';

  @override
  String alarmFormReminderBefore(int minutes) {
    return '$minutes min avant';
  }

  @override
  String get reminderNotificationTitle => 'Il est temps de te détendre';

  @override
  String get reminderNotificationBody => 'Ton alarme du coucher approche';

  @override
  String get soundPickerTitle => 'Son de l\'alarme';

  @override
  String get soundPickerYourSounds => 'Tes sons';

  @override
  String get soundPickerUpload => 'Importer un son';

  @override
  String get soundPickerSelect => 'Choisir le son';

  @override
  String get soundPickerNew => 'NOUVEAU';

  @override
  String get soundPickerCredit => '1 crédit';

  @override
  String get soundDefault => 'Par défaut';

  @override
  String get soundClock2 => 'Horloge 2';

  @override
  String get soundClock3 => 'Horloge 3';

  @override
  String get soundClock4 => 'Horloge 4';

  @override
  String get soundFunny => 'Drôle';

  @override
  String get soundCelestial => 'Céleste';

  @override
  String get soundChiptune => 'Chiptune';

  @override
  String get soundDreamscape => 'Rêverie';

  @override
  String get soundGame => 'Jeu';

  @override
  String get soundGame2 => 'Jeu 2';

  @override
  String get soundOversimplified => 'Simplifié';

  @override
  String get soundSmooth => 'Doux';

  @override
  String get soundAcoustic => 'Acoustique';

  @override
  String get soundComing => 'Coming';

  @override
  String get soundCyber => 'Cyber';

  @override
  String get soundDetermination => 'Détermination';

  @override
  String get soundDubstep => 'Dubstep';

  @override
  String get soundHiphop => 'Hiphop';

  @override
  String get soundPiano => 'Piano';

  @override
  String get soundTropical => 'Tropical';

  @override
  String get soundRingstone1 => 'Sonnerie 1';

  @override
  String get soundRingstone2 => 'Sonnerie 2';

  @override
  String get soundRingstone3 => 'Sonnerie 3';

  @override
  String get soundAlarm => 'Alarme';

  @override
  String get soundHardcore => 'Hardcore';

  @override
  String get soundCategoryClock => 'Horloge';

  @override
  String get soundCategoryGentle => 'Doux';

  @override
  String get soundCategoryMusical => 'Musical';

  @override
  String get soundCategoryRingstone => 'Sonnerie';

  @override
  String get soundCategoryViolent => 'Violent';

  @override
  String get homeNextWakeUp => 'Prochain réveil';

  @override
  String get homeTodaysWakeup => 'Réveil du jour';

  @override
  String get homeSeeAll => 'Tout voir';

  @override
  String get homeNoActiveAlarm => 'Aucune alarme active';

  @override
  String get homeNoActiveAlarmHint =>
      'Appuie pour en créer une avec une mission';

  @override
  String get homeToday => 'Aujourd\'hui';

  @override
  String get homeTomorrow => 'Demain';

  @override
  String get homePastAlarm => 'Alarme passée';

  @override
  String homeRingsIn(int hours, int minutes) {
    return 'Sonne dans ${hours}h ${minutes}m';
  }

  @override
  String get homeMission => 'Mission';

  @override
  String get homeSound => 'Son';

  @override
  String get homeNoWakeupsYet => 'Aucun réveil encore';

  @override
  String get homeSetAlarmToStart => 'Crée une alarme pour commencer';

  @override
  String get homeCurrentStreak => 'série actuelle';

  @override
  String homeBestStreak(int days) {
    return 'Record · $days';
  }

  @override
  String homeDayBadge(int days) {
    return 'Badge $days jours';
  }

  @override
  String homeNextBadge(int days) {
    return 'Prochain badge · $days jours';
  }

  @override
  String get homeAllBadgesEarned => 'Tous les badges obtenus';

  @override
  String get homeNextWake => 'Prochain · Réveil';

  @override
  String get homeNextSleep => 'Prochain · Coucher';

  @override
  String get homeInBed => 'au lit';

  @override
  String get homeBedtime => 'Coucher';

  @override
  String get homeWakeUp => 'Réveil';

  @override
  String get homeSetBedtime => 'Définir le coucher';

  @override
  String get homeSetWakeUp => 'Définir le réveil';

  @override
  String get homeScreenBlocker => 'Blocage d\'écran';

  @override
  String get homeManage => 'Gérer';

  @override
  String homeBlockerActiveUntil(String time) {
    return 'Actif jusqu\'à $time';
  }

  @override
  String homeBlockerActiveIn(int hours, int minutes) {
    return 'Actif dans ${hours}h ${minutes}m';
  }

  @override
  String get homeBlockerOff => 'Désactivé';

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Fév';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Avr';

  @override
  String get monthMay => 'Mai';

  @override
  String get monthJun => 'Juin';

  @override
  String get monthJul => 'Juil';

  @override
  String get monthAug => 'Août';

  @override
  String get monthSep => 'Sep';

  @override
  String get monthOct => 'Oct';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Déc';

  @override
  String get missionPushUps => 'Pompes';

  @override
  String get missionPushUpsDesc => 'Filme-toi en faisant des pompes';

  @override
  String get missionSquats => 'Squats';

  @override
  String get missionSquatsDesc => 'Filme-toi en faisant des squats';

  @override
  String get missionShakePhone => 'Secouer le téléphone';

  @override
  String get missionShakePhoneDesc => 'Secoue ton téléphone pour te réveiller';

  @override
  String get missionMath => 'Maths';

  @override
  String get missionMathDesc => 'Résous des problèmes de maths';

  @override
  String get missionSkyPhoto => 'Photo du ciel';

  @override
  String get missionSkyPhotoDesc => 'Prends une photo du ciel';

  @override
  String get missionMakeBed => 'Faire le lit';

  @override
  String get missionMakeBedDesc => 'Prends une photo de ton lit fait';

  @override
  String get missionObjectHunt => 'Chasse aux objets';

  @override
  String get missionObjectHuntDesc =>
      'Trouve et photographie un objet de la maison';

  @override
  String get missionPetHunt => 'Chasse aux animaux';

  @override
  String get missionPetHuntDesc => 'Trouve et photographie ton animal';

  @override
  String get missionNatureHunt => 'Chasse nature';

  @override
  String get missionNatureHuntDesc =>
      'Trouve et photographie un élément naturel';

  @override
  String get missionTouchGrass => 'Toucher l\'herbe';

  @override
  String get missionTouchGrassDesc => 'Prends une photo de l\'herbe';

  @override
  String get missionAffirmation => 'Affirmation';

  @override
  String get missionAffirmationDesc => 'Lis une affirmation à voix haute';

  @override
  String get missionRoutine => 'Routine';

  @override
  String get missionRoutineDesc => 'Complète ta liste d\'étapes';

  @override
  String get missionBreathing => 'Respiration';

  @override
  String get missionBreathingDesc => 'Suis un exercice de respiration guidé';

  @override
  String get missionGratefulness => 'Gratitude';

  @override
  String get missionGratefulnessDesc =>
      'Réponds à 3 questions pour bien commencer';

  @override
  String get missionMeditation => 'Méditation';

  @override
  String get missionMeditationDesc =>
      'Écoute une méditation guidée de 2 minutes';

  @override
  String get missionBed => 'Lit';

  @override
  String get missionBedDesc => 'Prends une photo de ton lit';

  @override
  String get missionRandom => 'Aléatoire';

  @override
  String get missionRandomDesc => 'Mission surprise chaque matin';

  @override
  String get missionNone => 'Pas de mission';

  @override
  String get missionNoneDesc => 'Alarme simple sans tâche';

  @override
  String get routinePickerTitle => 'Compose ta routine';

  @override
  String get routinePickerSubtitle =>
      'Choisis les étapes à compléter. Touche ＋ pour ajouter la tienne.';

  @override
  String get routineAddStep => 'Ajouter une étape';

  @override
  String get routineValidate => 'Valider la routine';

  @override
  String routineStepsCount(int count) {
    return '$count étapes';
  }

  @override
  String get routineTapToComplete => 'Touche chaque étape une fois complétée';

  @override
  String get routineDrinkWater => 'Boire un verre d\'eau';

  @override
  String get routineDimLight => 'Tamiser la lumière';

  @override
  String get routineCloseComputer => 'Fermer ton ordinateur';

  @override
  String get routineBrushTeeth => 'Se brosser les dents';

  @override
  String get routinePrepareClothes => 'Préparer tes vêtements';

  @override
  String get routineTodoList => 'Liste de tâches pour demain';

  @override
  String get routineJournaling => 'Journal intime';

  @override
  String get routineBreathing => 'Respiration';

  @override
  String get routineRead => 'Lire';

  @override
  String get photoTargetSky => 'le ciel';

  @override
  String get photoTargetMadeBed => 'ton lit fait';

  @override
  String get photoTargetBed => 'ton lit';

  @override
  String get photoTargetGrass => 'l\'herbe';

  @override
  String get missionPickerTitle => 'Choisir une mission';

  @override
  String get missionPickerAll => 'Tout';

  @override
  String get missionPickerWakeup => 'Réveil';

  @override
  String get missionPickerSleep => 'Sommeil';

  @override
  String get missionPickerTrending => 'Tendance';

  @override
  String get missionPickerHunts => 'Chasses';

  @override
  String get missionPickerPhysical => 'Physique';

  @override
  String get missionPickerPreview => 'Aperçu';

  @override
  String get missionConfigNumberOfShakes => 'Nombre de secousses';

  @override
  String get missionConfigNumberOfReps => 'Nombre de répétitions';

  @override
  String get missionConfigNumberOfRounds => 'Nombre de cycles';

  @override
  String get missionConfigMinutes => 'Minutes minimum';

  @override
  String get missionConfigNumberOfProblems => 'Nombre de problèmes';

  @override
  String get missionConfigDifficulty => 'Difficulté';

  @override
  String get missionConfigEasy => 'Facile';

  @override
  String get missionConfigMedium => 'Moyen';

  @override
  String get missionConfigHard => 'Difficile';

  @override
  String get missionConfigChoose => 'Choisir cette mission';

  @override
  String get missionConfigNumberOfAffirmations => 'Nombre d\'affirmations';

  @override
  String get breathingMusicOn => 'Musique activée';

  @override
  String get breathingMusicOff => 'Musique coupée';

  @override
  String get breathingPhaseInhale => 'Inspire';

  @override
  String get breathingPhaseExhale => 'Expire';

  @override
  String get breathingPhaseHold => 'Retiens';

  @override
  String breathingRoundLabel(int current, int total) {
    return 'Cycle $current sur $total';
  }

  @override
  String get gratefulnessQuestion1 =>
      'Pour quoi es-tu reconnaissant aujourd\'hui ?';

  @override
  String get gratefulnessQuestion2 =>
      'Quelle bonne chose t\'est arrivée récemment ?';

  @override
  String get gratefulnessQuestion3 =>
      'Qu\'attends-tu avec impatience aujourd\'hui ?';

  @override
  String gratefulnessProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String get gratefulnessHint => 'Écris ta réponse…';

  @override
  String get gratefulnessNext => 'Suivant';

  @override
  String get gratefulnessFinish => 'Terminer';

  @override
  String get meditationTitle => 'Méditation';

  @override
  String get meditationInstruction =>
      'Ferme les yeux et suis la méditation guidée.';

  @override
  String get meditationRetry => 'Touche pour réessayer';

  @override
  String meditationFinishIn(String time) {
    return 'Terminer dans $time';
  }

  @override
  String get itemPickerSelectItems => 'Sélectionner les objets';

  @override
  String get itemPickerRandomItem =>
      'Un objet aléatoire sera choisi chaque matin';

  @override
  String get itemPickerHouseholdItems => 'Objets de la maison';

  @override
  String get itemPickerFunItems => 'Objets amusants';

  @override
  String get itemPickerSelectPets => 'Sélectionner tes animaux';

  @override
  String get itemPickerPetsSubtitle =>
      'Sélectionne les animaux que tu as à la maison';

  @override
  String get itemPickerSelectNature => 'Sélectionner les éléments naturels';

  @override
  String get itemPickerNatureSubtitle =>
      'Un élément naturel aléatoire sera choisi chaque matin';

  @override
  String itemPickerSelected(int count) {
    return '$count sélectionnés';
  }

  @override
  String get itemPickerSelectAll => 'Tout sélectionner';

  @override
  String get itemPickerDeselectAll => 'Tout désélectionner';

  @override
  String get itemPickerAddOwn => 'Ajoute ton propre objet';

  @override
  String get itemPickerDone => 'Terminé';

  @override
  String get itemPickerCustomItems => 'Objets personnalisés';

  @override
  String get itemPickerAddCustom => 'Ajouter un objet';

  @override
  String get itemPickerNewItemTitle => 'Nouvel objet';

  @override
  String get itemPickerNameHint => 'Nom';

  @override
  String get itemPickerChooseEmoji => 'Choisis un emoji';

  @override
  String get itemPickerAdd => 'Ajouter';

  @override
  String get affirmationPickerCustom => 'Personnalisées';

  @override
  String get itemToothbrush => 'Brosse à dents';

  @override
  String get itemRunningFaucet => 'Robinet ouvert';

  @override
  String get itemShoes => 'Chaussures';

  @override
  String get itemFridge => 'Réfrigérateur';

  @override
  String get itemKeys => 'Clés';

  @override
  String get itemCoffeeMug => 'Tasse à café';

  @override
  String get itemMirror => 'Miroir';

  @override
  String get itemWaterBottle => 'Bouteille d\'eau';

  @override
  String get itemDustpan => 'Pelle à poussière';

  @override
  String get itemToilet => 'Toilettes';

  @override
  String get itemBook => 'Livre';

  @override
  String get itemLamp => 'Lampe';

  @override
  String get itemTvRemote => 'Télécommande';

  @override
  String get itemFrontDoor => 'Porte d\'entrée';

  @override
  String get itemStove => 'Cuisinière';

  @override
  String get itemLotionBottle => 'Flacon de lotion';

  @override
  String get itemSoap => 'Savon';

  @override
  String get itemPlant => 'Plante';

  @override
  String get itemPlate => 'Assiette';

  @override
  String get itemTowel => 'Serviette';

  @override
  String get itemBackpack => 'Sac à dos';

  @override
  String get itemHeadphones => 'Écouteurs';

  @override
  String get itemShower => 'Douche';

  @override
  String get itemTape => 'Ruban adhésif';

  @override
  String get itemKimKardashian => 'Kim Kardashian';

  @override
  String get itemSnoopDogg => 'Snoop Dogg';

  @override
  String get itemRubberDuck => 'Canard en plastique';

  @override
  String get itemBanana => 'Banane';

  @override
  String get itemPickle => 'Cornichon';

  @override
  String get itemCroc => 'Croc';

  @override
  String get itemLavaLamp => 'Lampe à lave';

  @override
  String get itemPingPongPaddle => 'Raquette de ping-pong';

  @override
  String get itemEgg => 'Œuf';

  @override
  String get petDog => 'Chien';

  @override
  String get petCat => 'Chat';

  @override
  String get petBird => 'Oiseau';

  @override
  String get petFish => 'Poisson';

  @override
  String get petHamster => 'Hamster';

  @override
  String get petRabbit => 'Lapin';

  @override
  String get petTurtle => 'Tortue';

  @override
  String get petGuineaPig => 'Cochon d\'Inde';

  @override
  String get petLizard => 'Lézard';

  @override
  String get petSnake => 'Serpent';

  @override
  String get natureTree => 'Arbre';

  @override
  String get natureFlower => 'Fleur';

  @override
  String get natureRock => 'Rocher';

  @override
  String get natureLeaf => 'Feuille';

  @override
  String get natureGrass => 'Herbe';

  @override
  String get natureBush => 'Buisson';

  @override
  String get natureStick => 'Bâton';

  @override
  String get naturePinecone => 'Pomme de pin';

  @override
  String get affirmationPickerTitle => 'Sélectionner les affirmations';

  @override
  String affirmationPickerSelected(int count) {
    return '$count sélectionnées';
  }

  @override
  String get affirmationPickerSelectAll => 'Tout sélectionner';

  @override
  String get affirmationPickerDeselectAll => 'Tout désélectionner';

  @override
  String get affirmationPickerAddOwn => 'Ajoute ta propre affirmation';

  @override
  String get affirmationPickerDone => 'Terminé';

  @override
  String get randomPoolTitle => 'Pool aléatoire';

  @override
  String get randomPoolSubtitle =>
      'Sélectionne les missions à inclure dans la rotation aléatoire';

  @override
  String randomPoolSelected(int count) {
    return '$count sélectionnées';
  }

  @override
  String get randomPoolSelectAll => 'Tout sélectionner';

  @override
  String get randomPoolDeselectAll => 'Tout désélectionner';

  @override
  String get randomPoolDone => 'Terminé';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsAnonymousUser => 'Utilisateur anonyme';

  @override
  String settingsAccountType(String type) {
    return 'Type de compte : $type';
  }

  @override
  String get settingsAccount => 'Compte';

  @override
  String get settingsUserType => 'Type d\'utilisateur';

  @override
  String get settingsCopyUserId => 'Copier l\'identifiant utilisateur';

  @override
  String get settingsUserIdCopied =>
      'Identifiant utilisateur copié dans le presse-papiers';

  @override
  String get settingsEnterReferralCode => 'Entrer un code de parrainage';

  @override
  String get settingsApp => 'Application';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsDarkMode => 'Mode sombre';

  @override
  String get settingsAlarmDuringMission => 'Alarme pendant la mission';

  @override
  String get settingsDefaultSound => 'Son par défaut';

  @override
  String get settingsDefaultMission => 'Mission par défaut';

  @override
  String get settingsNone => 'Aucune';

  @override
  String get settingsAbout => 'À propos';

  @override
  String get settingsPrivacyPolicy => 'Politique de confidentialité';

  @override
  String get settingsTermsOfService => 'Conditions d\'utilisation';

  @override
  String get settingsAdmin => 'Admin (débogage uniquement)';

  @override
  String get settingsPrintAllAlarms => 'Afficher toutes les alarmes';

  @override
  String get settingsPrintRawAlarms => 'Afficher alarmes AlarmKit brutes';

  @override
  String get settingsPrintSharedPreferences => 'Afficher SharedPreferences';

  @override
  String get settingsDeleteAllAlarms => 'Supprimer toutes les alarmes';

  @override
  String get settingsForceQuickAlarm => 'Forcer alarme 5s à l\'ajout';

  @override
  String get settingsForcedHuntTarget => 'Cible forcée (chasse)';

  @override
  String get settingsForcedHuntTargetNone => 'Aléatoire';

  @override
  String get forcedHuntTargetPickerTitle => 'Cible forcée (chasse)';

  @override
  String get forcedHuntTargetPickerSubtitle =>
      'La roulette tournera toujours, mais s\'arrêtera toujours sur cet objet.';

  @override
  String get forcedHuntTargetPickerNone => 'Aucune (aléatoire)';

  @override
  String get forcedHuntTargetPickerObjects => 'Objets';

  @override
  String get forcedHuntTargetPickerPets => 'Animaux';

  @override
  String get forcedHuntTargetPickerNature => 'Nature';

  @override
  String get settingsLogout => 'Se déconnecter';

  @override
  String get settingsLogoutTitle => 'Se déconnecter ?';

  @override
  String get settingsLogoutBody =>
      'Tu seras déconnecté de cet appareil. Les paramètres locaux et les alarmes programmées seront effacés.';

  @override
  String get settingsLogoutConfirm => 'Se déconnecter';

  @override
  String get settingsLogoutCancel => 'Annuler';

  @override
  String get settingsDeleteAccount => 'Supprimer le compte';

  @override
  String get settingsDeleteAccountTitle => 'Supprimer le compte ?';

  @override
  String get settingsDeleteAccountBody =>
      'Cette action supprime définitivement ton compte, tes alarmes, tes sessions et ton historique de séries. Elle est irréversible.';

  @override
  String get settingsDeleteAccountConfirm => 'Supprimer';

  @override
  String get settingsDeleteAccountCancel => 'Annuler';

  @override
  String get settingsDeleteAccountReauthRequired =>
      'Reconnecte-toi, puis réessaie de supprimer ton compte.';

  @override
  String get settingsDeleteAccountError =>
      'Impossible de supprimer ton compte. Réessaie.';

  @override
  String get settingsVersion => 'Levio v0.1.0';

  @override
  String get referralTitle => 'Entrer un code de parrainage';

  @override
  String get referralCodeLabel => 'Code de parrainage';

  @override
  String referralApplied(String type) {
    return 'Code appliqué ! Tu es maintenant : $type';
  }

  @override
  String get referralInvalid => 'Code de parrainage invalide';

  @override
  String get referralUsageLimit => 'Ce code a atteint sa limite d\'utilisation';

  @override
  String get referralError => 'Une erreur est survenue, réessaie';

  @override
  String get referralCancel => 'Annuler';

  @override
  String get referralSubmit => 'Soumettre';

  @override
  String get insightsTitle => 'Statistiques';

  @override
  String get insightsStats => 'Stats';

  @override
  String get insightsAvgWakeTime => 'Heure moy. de réveil';

  @override
  String get insightsAvgResponse => 'Temps moy. de réponse';

  @override
  String get insightsFavoriteMission => 'Mission préférée';

  @override
  String get insightsFavoriteSound => 'Son préféré';

  @override
  String get insightsWeek => 'Semaine';

  @override
  String get insightsMonth => 'Mois';

  @override
  String get insightsAllTime => 'Tout';

  @override
  String get insightsDayStreak => 'Série de jours';

  @override
  String get insightsBadgesEarned => 'Badges obtenus';

  @override
  String get insightsConsistency => 'Régularité';

  @override
  String get insightsNeed3Wakeups => '3+ réveils nécessaires';

  @override
  String get insightsConsistencyVariable => 'Variable';

  @override
  String get insightsConsistencyImproving => 'En progrès';

  @override
  String get insightsConsistencyRegular => 'Régulier';

  @override
  String get insightsConsistencyConsistent => 'Constant';

  @override
  String get insightsConsistencyScoreTitle => 'Score de régularité';

  @override
  String get insightsConsistencyScoreBody =>
      'Ton score de régularité mesure la fréquence à laquelle tu te réveilles avec Levio. Il s\'améliore au fur et à mesure que ta série grandit.';

  @override
  String get insightsOk => 'OK';

  @override
  String get milestonesTitle => 'Étapes';

  @override
  String get milestonesDayStreak => 'Série de jours';

  @override
  String milestonesLongestStreak(int count) {
    return '$count jour';
  }

  @override
  String get milestonesLongestStreakLabel => 'plus longue série';

  @override
  String get milestonesStreakBadges => 'Badges de série';

  @override
  String get milestonesAchievementBadges => 'Réussites du réveil';

  @override
  String get milestonesSleepAchievementBadges => 'Réussites du coucher';

  @override
  String get milestonesBadgesEarned => 'Badges obtenus';

  @override
  String milestonesBadgeCount(int earned, int total) {
    return '$earned/$total badges';
  }

  @override
  String get milestonesHowStreaksWork => 'Comment fonctionnent les séries';

  @override
  String get milestonesStreakExplanation =>
      'Réveille-toi avec Levio chaque jour pour construire ta série. Tu as 2 jours de gel par semaine pour sauter sans perdre ta progression. Si tu manques un jour sans gel, ta série baisse de 3 au lieu de revenir à zéro.';

  @override
  String get badgeRisen => 'Éveillé';

  @override
  String get badgeRisenReq => '1 jour';

  @override
  String get badgeRisenQuote =>
      'Le voyage de mille matins commence par un seul réveil.';

  @override
  String get badgeIgnite => 'Étincelle';

  @override
  String get badgeIgniteReq => '3 jours';

  @override
  String get badgeIgniteQuote => 'Trois jours. La flamme grandit.';

  @override
  String get badgeHorizon => 'Horizon';

  @override
  String get badgeHorizonReq => '7 jours';

  @override
  String get badgeHorizonQuote =>
      'Une semaine de matins — tu réécris ton histoire.';

  @override
  String get badgeAurora => 'Aurore';

  @override
  String get badgeAuroraReq => '14 jours';

  @override
  String get badgeAuroraQuote =>
      'Deux semaines de levers de soleil. Continue à poursuivre la lumière.';

  @override
  String get badgeCelestial => 'Céleste';

  @override
  String get badgeCelestialReq => '30 jours';

  @override
  String get badgeCelestialQuote =>
      'Un mois complet de levers. Tu es inarrêtable.';

  @override
  String get badgeNebula => 'Nébuleuse';

  @override
  String get badgeNebulaReq => '100 jours';

  @override
  String get badgeNebulaQuote => 'Cent matins. Un nouveau toi est né.';

  @override
  String get badgeEternal => 'Éternel';

  @override
  String get badgeEternalReq => '365 jours';

  @override
  String get badgeEternalQuote =>
      'Une année complète de matins. Tu es légendaire.';

  @override
  String get badgeVersatile => 'Polyvalent';

  @override
  String get badgeVersatileReq => 'Utiliser les 13 types de missions';

  @override
  String get badgeVersatileQuote => 'La maîtrise vient de la diversité.';

  @override
  String get badgeFirstLight => 'Première lueur';

  @override
  String get badgeFirstLightReq => 'Se réveiller avant 5h30';

  @override
  String get badgeFirstLightQuote =>
      'L\'avenir appartient à ceux qui se lèvent tôt.';

  @override
  String get badgeBlitz => 'Éclair';

  @override
  String get badgeBlitzReq => 'Éteindre l\'alarme en moins de 15s';

  @override
  String get badgeBlitzQuote =>
      'La vitesse de la lumière. La vitesse de la vie.';

  @override
  String get badgeNoDaysOff => 'Sans relâche';

  @override
  String get badgeNoDaysOffReq => '30 réveils consécutifs';

  @override
  String get badgeNoDaysOffQuote =>
      'Les week-ends ne sont que des jours de semaine déguisés.';

  @override
  String get badgeConverted => 'Converti';

  @override
  String get badgeConvertedReq => 'Atteindre une série de 7 jours';

  @override
  String get badgeConvertedQuote =>
      'Même les couche-tard peuvent apprendre à aimer l\'aube.';

  @override
  String get badgeAudiophile => 'Audiophile';

  @override
  String get badgeAudiophileReq => 'Utiliser 4+ sons d\'alarme différents';

  @override
  String get badgeAudiophileQuote => 'Chaque matin mérite sa propre bande-son.';

  @override
  String get badgeFirstNight => 'Première nuit';

  @override
  String get badgeFirstNightReq => 'Termine ta première détente';

  @override
  String get badgeFirstNightQuote =>
      'Chaque bon matin commence la veille au soir.';

  @override
  String get badgeEarlyToBed => 'Couché tôt';

  @override
  String get badgeEarlyToBedReq => 'Détends-toi avant 22 h';

  @override
  String get badgeEarlyToBedQuote =>
      'Le repos est la fondation sur laquelle se construit la journée.';

  @override
  String get badgeCalmMind => 'Esprit calme';

  @override
  String get badgeCalmMindReq =>
      'Termine une détente méditation ou respiration';

  @override
  String get badgeCalmMindQuote => 'Un esprit apaisé dort plus profondément.';

  @override
  String get badgeDreamer => 'Rêveur';

  @override
  String get badgeDreamerReq => 'Utilise les 6 missions de détente';

  @override
  String get badgeDreamerQuote =>
      'Il y a plus d\'un chemin vers une bonne nuit.';

  @override
  String get badgeWellRested => 'Bien reposé';

  @override
  String get badgeWellRestedReq =>
      'Atteins une série de 7 jours avec une alarme de coucher';

  @override
  String get badgeWellRestedQuote =>
      'Sept nuits d\'intention. Le sommeil devient un rituel.';

  @override
  String get badgeNoNightsOff => 'Aucune nuit de repos';

  @override
  String get badgeNoNightsOffReq => '30 nuits consécutives de détente';

  @override
  String get badgeNoNightsOffQuote =>
      'La constance est le plus discret des super-pouvoirs.';

  @override
  String get wakeupTitle => 'Réveil du jour';

  @override
  String get wakeupStartMyDay => 'Commencer ma journée';

  @override
  String get wakeupCongratulations => 'Félicitations.';

  @override
  String get wakeupThanks => 'Grâce à Levio, tu t\'es réveillé aujourd\'hui.';

  @override
  String get wakeupThanksSleep => 'Grâce à Levio, tu t\'es détendu ce soir.';

  @override
  String get wakeupTimeTaken => 'Temps écoulé';

  @override
  String get wakeupDayStreak => 'Série de jours';

  @override
  String get wakeupWakeups => 'Réveils';

  @override
  String get wakeupDailyQuote => 'Citation du jour';

  @override
  String get wakeupContinue => 'Continuer';

  @override
  String get wakeupWakeUp => 'Réveil';

  @override
  String get sessionsTitle => 'Tous les réveils';

  @override
  String get sessionsNoWakeups => 'Aucun réveil encore';

  @override
  String get sessionsMissed => 'Manqué';

  @override
  String get sessionsScreenTimeDisabled => 'Temps d\'écran désactivé';

  @override
  String get quoteEinstein =>
      'Au milieu de chaque difficulté se trouve une opportunité.';

  @override
  String get quoteEinsteinAuthor => 'Albert Einstein';

  @override
  String get quoteTwain => 'Le secret pour avancer, c\'est de commencer.';

  @override
  String get quoteTwainAuthor => 'Mark Twain';

  @override
  String get quoteConfucius =>
      'Peu importe la lenteur à laquelle tu avances, pourvu que tu ne t\'arrêtes pas.';

  @override
  String get quoteConfuciusAuthor => 'Confucius';

  @override
  String get quoteChurchill =>
      'Le succès n\'est pas définitif, l\'échec n\'est pas fatal.';

  @override
  String get quoteChurchillAuthor => 'Winston Churchill';

  @override
  String get quoteRoosevelt => 'Crois que tu peux et tu es à mi-chemin.';

  @override
  String get quoteRooseveltAuthor => 'Theodore Roosevelt';

  @override
  String get quoteJobs =>
      'La seule façon de faire du bon travail est d\'aimer ce que tu fais.';

  @override
  String get quoteJobsAuthor => 'Steve Jobs';

  @override
  String get quoteUnknown =>
      'Réveille-toi avec détermination, couche-toi avec satisfaction.';

  @override
  String get quoteUnknownAuthor => 'Inconnu';

  @override
  String get quoteBuddha =>
      'Chaque matin nous renaissons. Ce que nous faisons aujourd\'hui compte le plus.';

  @override
  String get quoteBuddhaAuthor => 'Bouddha';

  @override
  String get dismissStopAlarm => 'Arrêter l\'alarme';

  @override
  String get dismissShakePrompt =>
      'Secoue ton téléphone pour arrêter l\'alarme';

  @override
  String get dismissSpinningWheelTitle => 'Gagne un voyage avec Levio';

  @override
  String get dismissSpinningWheelPrompt => 'Lance la roue d\'un geste';

  @override
  String get dismissSpinningWheelFlickHarder => 'Lance plus fort !';

  @override
  String get dismissSpinningWheelWin => 'Tu as gagné un voyage ! ✈️';

  @override
  String get dismissSpinningWheelMissed => 'Meilleure chance demain !';

  @override
  String get dismissSpinningWheelAlreadyUsed =>
      'Tu as déjà tourné aujourd\'hui. Reviens demain ! ✈️';

  @override
  String dismissMathProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String get dismissMathWrong => 'Faux — réessaie !';

  @override
  String get dismissMathConfirm => 'Confirmer';

  @override
  String dismissPhotoPrompt(String target) {
    return 'Prends une photo de $target pour arrêter l\'alarme';
  }

  @override
  String dismissPhotoChecking(String target) {
    return 'Vérification de $target…';
  }

  @override
  String get dismissPhotoStarting => 'Démarrage de la caméra…';

  @override
  String dismissPhotoNotDetected(String target) {
    return 'Aucun $target détecté — réessaie';
  }

  @override
  String dismissPhotoError(String error) {
    return 'Erreur : $error';
  }

  @override
  String get dismissPhotoTakePhoto => 'PRENDS UNE PHOTO DE';

  @override
  String get dismissPhotoFindThis => 'TROUVE ÇA';

  @override
  String get dismissPhotoPickingTarget => 'Sélection de ta cible…';

  @override
  String get dismissSpeechSay => 'Dis :';

  @override
  String get dismissSpeechListening => 'Écoute en cours…';

  @override
  String get dismissSpeechTapToSpeak => 'Appuie pour parler';

  @override
  String dismissSpeechTryAgain(int score) {
    return '$score% — réessaie';
  }

  @override
  String get dismissSpeechMicUnavailable => 'Microphone indisponible';

  @override
  String dismissSpeechProgress(int current, int total) {
    return '$current/$total';
  }

  @override
  String get dismissRepStarting => 'Démarrage de la caméra…';

  @override
  String dismissRepPrompt(int target, String mission) {
    return 'Fais $target $mission pour arrêter l\'alarme';
  }

  @override
  String dismissRepOf(int target) {
    return 'de $target';
  }

  @override
  String get dismissMissionTimeToWakeUp => 'C\'est l\'heure de se réveiller !';

  @override
  String get dismissMissionTimeToWindDown => 'C\'est l\'heure de te détendre !';

  @override
  String dismissMissionStreak(int count) {
    return '🔥 série de $count jours';
  }

  @override
  String dismissMissionLabel(int current, int total, String name) {
    return 'Mission $current/$total : $name';
  }

  @override
  String get dismissStartMission => 'Commencer la mission';

  @override
  String get dismissFeedbackMoveIntoFrame =>
      'Place tout ton corps dans le cadre';

  @override
  String get dismissFeedbackKeepGoing => 'Oui, continue !';

  @override
  String get dismissFeedbackPushupPosition =>
      'Allonge-toi en position de pompe';

  @override
  String get dismissFeedbackStartPushups => 'Commence tes pompes !';

  @override
  String get dismissFeedbackPushupGoDeeper =>
      'Descends plus bas, ta poitrine doit toucher le sol !';

  @override
  String get dismissFeedbackSquatPosition =>
      'Lève-toi pour commencer les squats';

  @override
  String get dismissFeedbackStartSquats => 'Commence tes squats !';

  @override
  String get dismissFeedbackSquatGoDeeper =>
      'Descends plus bas, tes cuisses doivent être parallèles au sol !';

  @override
  String get onboardingMorningPerson => 'Te sens-tu du matin ?';

  @override
  String get onboardingYes => 'Oui';

  @override
  String get onboardingNotYet => 'Pas encore';

  @override
  String get onboardingAgeRange => 'Quelle est ta tranche d\'âge ?';

  @override
  String get onboardingDescribesYou => 'Qu\'est-ce qui te décrit le mieux ?';

  @override
  String get onboardingMale => 'Homme';

  @override
  String get onboardingFemale => 'Femme';

  @override
  String get onboardingOther => 'Autre';

  @override
  String get onboardingKeepsInBed =>
      'Qu\'est-ce qui te retient au lit après l\'alarme ?';

  @override
  String get onboardingPhoneScrolling => 'Scroller sur le téléphone';

  @override
  String get onboardingSnoozeLoop => 'Boucle de snooze';

  @override
  String get onboardingSleepThrough => 'Dormir à travers les alarmes';

  @override
  String get onboardingStayInBed => 'Je me réveille mais reste au lit';

  @override
  String get onboardingFirstThought =>
      'Première pensée quand l\'alarme sonne ?';

  @override
  String get onboardingImUp => 'Je suis debout';

  @override
  String get onboardingFiveMore => 'Encore 5 minutes';

  @override
  String get onboardingSetAnother => 'Je vais en mettre une autre';

  @override
  String get onboardingWhyDidI => 'Pourquoi j\'ai fait ça ?';

  @override
  String get onboardingGetsYouOut => 'Levio te fait sortir du lit';

  @override
  String get onboardingAvoidGroggy =>
      'Évite la « zone de brouillard ». Levio te propulse directement en état d\'alerte.';

  @override
  String get onboardingHowManyAlarms => 'Combien d\'alarmes mets-tu ?';

  @override
  String get onboardingOne => 'Une';

  @override
  String get onboardingTwoThree => '2-3';

  @override
  String get onboardingFourPlus => '4+';

  @override
  String get onboardingOneAlarmWakeUp =>
      'Si tu ne mettais qu\'une alarme, te réveillerais-tu ?';

  @override
  String get onboardingSometimes => 'Parfois';

  @override
  String get onboardingNo => 'Non';

  @override
  String get onboardingTurnOffGoBack =>
      'T\'arrive-t-il d\'éteindre l\'alarme et de te rendormir ?';

  @override
  String get onboardingOften => 'Souvent';

  @override
  String get onboardingRarely => 'Rarement';

  @override
  String get onboardingNever => 'Jamais';

  @override
  String get onboardingOneAlarmOneMission => 'Une alarme. Une mission.';

  @override
  String get onboardingFeelSettingAlarm =>
      'Que ressens-tu en réglant ton alarme le soir ?';

  @override
  String get onboardingMotivated => 'Motivé';

  @override
  String get onboardingAnxiousSleep => 'Anxieux pour le sommeil';

  @override
  String get onboardingDefeated => 'Découragé';

  @override
  String get onboardingNeutral => 'Neutre';

  @override
  String get onboardingFeelAfterWaking =>
      'Comment te sens-tu juste après le réveil ?';

  @override
  String get onboardingReadyToGo => 'Prêt à foncer';

  @override
  String get onboardingGroggy => 'Brouillard';

  @override
  String get onboardingAnxiousStressed => 'Anxieux ou stressé';

  @override
  String get onboardingHowLongAwake =>
      'Combien de temps pour te sentir pleinement éveillé ?';

  @override
  String get onboardingInstantly => 'Instantanément';

  @override
  String get onboardingTenFifteen => '10-15 minutes';

  @override
  String get onboardingThirtyPlus => '30 minutes ou plus';

  @override
  String get onboardingBiologyTitle => 'Ce n\'est pas ta faute !';

  @override
  String get onboardingBiologySubtitle => 'La biologie, pas la paresse';

  @override
  String get onboardingBiologyBody =>
      'L\'inertie du sommeil est réelle : ton cerveau met 30 à 50 min à dissiper complètement la somnolence après le réveil. Le snooze relance le cycle et empire les choses.';

  @override
  String get onboardingBiologyReferences =>
      'Tassi & Muzet (2000). L\'inertie du sommeil. Sleep Medicine Reviews.\nTrotti (2017). Se réveiller est la chose la plus difficile de ma journée. Sleep Medicine Reviews.\nHilditch & McHill (2019). L\'inertie du sommeil : connaissances actuelles. Nature and Science of Sleep.';

  @override
  String get onboardingScienceSays => 'La science le dit !';

  @override
  String get onboarding5xFaster =>
      'Sors du lit 5x plus vite avec Levio vs tout seul';

  @override
  String get onboardingSleepEduTitle => 'L\'heure du coucher change tout';

  @override
  String get onboardingSleepEduBody =>
      'Se coucher à heure régulière est le meilleur moyen de se réveiller reposé. Un rappel du coucher aide à tenir le rythme.';

  @override
  String get onboardingWantSleepAlarm =>
      'Tu veux aussi une alarme de coucher ?';

  @override
  String get onboardingSleepTimeTitle => 'À quelle heure veux-tu te coucher ?';

  @override
  String get onboardingSleepTimeSubtitle =>
      'On te préviendra quand il sera temps de ralentir.';

  @override
  String onboardingSleepDurationBadge(String duration) {
    return '$duration de sommeil';
  }

  @override
  String get onboardingScreenEduTitle => 'Les écrans volent ton sommeil';

  @override
  String get onboardingScreenEduBody =>
      'Scroller tard décale ton horloge interne et réduit le sommeil profond. Bloquer les applis distrayantes le soir protège ton repos.';

  @override
  String get onboardingBlockApps =>
      'Bloquer les applis distrayantes pendant le sommeil ?';

  @override
  String get onboardingBlockStartTitle =>
      'Quand le blocage doit-il commencer ?';

  @override
  String get onboardingBlockStartSubtitle =>
      'Les applis restent bloquées jusqu\'à 20 min après ton réveil. C\'est la valeur par défaut — tu pourras la modifier plus tard dans les Réglages.';

  @override
  String get onboardingRelaxEduTitle => 'Remplace les écrans par du calme';

  @override
  String get onboardingRelaxEduBody =>
      'Échange le scroll contre une courte routine de détente. Ton alarme de coucher te guidera.';

  @override
  String get onboardingRelaxActivitiesTitle =>
      'Qu\'est-ce qui t\'aide à décompresser ?';

  @override
  String get onboardingRelaxActivitiesSubtitle =>
      'Choisis quelques activités pour ta routine du soir.';

  @override
  String get onboardingRelaxActivitiesChoose => 'Choisis ta routine de détente';

  @override
  String onboardingRelaxActivitiesCount(int count) {
    return '$count activités choisies';
  }

  @override
  String get onboardingSleepPlanTitle => 'Ta routine de sommeil';

  @override
  String get onboardingSleepRoutineHeader => 'TA ROUTINE';

  @override
  String onboardingSleepBedtime(String time) {
    return 'Coucher à $time';
  }

  @override
  String onboardingSleepBlocked(String time) {
    return 'Applis bloquées jusqu\'à $time';
  }

  @override
  String onboardingSleepWindDownSteps(String steps) {
    return 'Détente : $steps';
  }

  @override
  String onboardingSignatureSleepSubtitle(String time) {
    return 'Je m\'engage à suivre ma routine de sommeil et à me lever à $time.';
  }

  @override
  String get onboardingContinue => 'Continuer';

  @override
  String onboardingSetAlarmFor(String time) {
    return 'Régler l\'alarme à $time';
  }

  @override
  String get onboardingAlarmDuringMission =>
      'Jouer l\'alarme pendant la mission ?';

  @override
  String get onboardingAlarmKeepRinging =>
      'Garder l\'alarme sonnant pendant la mission.';

  @override
  String get onboardingAlarmStopRinging =>
      'Arrêter l\'alarme sauf si je quitte l\'app pendant la mission.';

  @override
  String get onboardingWhereHeard => 'Où as-tu entendu parler de nous ?';

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
  String get onboardingFriendFamily => 'Ami ou famille';

  @override
  String get onboardingWelcomeTitle =>
      'Arrête de te battre contre ton réveil.\nRéussis ton lever, réussis ta journée !';

  @override
  String get onboardingWelcomeSubtitle =>
      'Une alarme. Une mission. Tu es debout.';

  @override
  String get onboardingBuildPlan => 'Créer mon plan';

  @override
  String get onboardingJoin500k =>
      'Rejoins plus de 500 000 personnes qui se réveillent avec Levio';

  @override
  String get onboardingAppOfTheYear => 'Élue app de l\'année 2026 🎊';

  @override
  String get onboardingAlreadyAccount => 'Tu as déjà un compte ? ';

  @override
  String get onboardingSignIn => 'Se connecter';

  @override
  String get languageSelectTitle => 'Langue';

  @override
  String get onboardingSignInApple => 'Se connecter avec Apple';

  @override
  String get onboardingSignInGoogle => 'Continuer avec Google';

  @override
  String get onboardingSkipForNow => 'Passer pour l\'instant';

  @override
  String get onboardingGoogleFailed =>
      'Échec de la connexion Google. Réessaie.';

  @override
  String get onboardingAppleFailed => 'Échec de la connexion Apple. Réessaie.';

  @override
  String get onboardingAccountNotFound =>
      'Aucun compte trouvé. Crée d\'abord un compte via l\'inscription.';

  @override
  String get onboardingSignInEmail => 'Se connecter avec un email';

  @override
  String get onboardingEmailModalSignInTitle => 'Se connecter avec un email';

  @override
  String get onboardingEmailModalSignUpTitle => 'Créer un compte par email';

  @override
  String get onboardingEmailLabel => 'Email';

  @override
  String get onboardingPasswordLabel => 'Mot de passe';

  @override
  String get onboardingEmailNoAccount => 'Tu n\'as pas de compte ? ';

  @override
  String get onboardingEmailHasAccount => 'Tu as déjà un compte ? ';

  @override
  String get onboardingEmailSignUpAction => 'S\'inscrire';

  @override
  String get onboardingEmailSignInAction => 'Se connecter';

  @override
  String get onboardingEmailEmptyError =>
      'Saisis ton email et ton mot de passe.';

  @override
  String get onboardingDayPickerTitle => 'Quels jours Levio doit-il sonner ?';

  @override
  String get onboardingDayPickerSubtitle => 'Choisis les jours à verrouiller.';

  @override
  String get onboardingLoadingTitle => 'Tout se met en place\npour toi';

  @override
  String get onboardingLoadingStep1 => 'Analyse de tes habitudes de sommeil';

  @override
  String get onboardingLoadingStep2 => 'Configuration de tes objectifs';

  @override
  String get onboardingLoadingStep3 => 'Choix de ta mission';

  @override
  String get onboardingLoadingStep4 => 'Calibrage du son d\'alarme';

  @override
  String get onboardingLoadingStep5 => 'Programmation de ton alarme';

  @override
  String get onboardingLoadingStep6 => 'Finalisation de ton plan';

  @override
  String get onboardingMissionPickerTitle => 'Choisis ta mission de réveil';

  @override
  String get onboardingMissionPickerSubtitle =>
      'Tu feras ceci pour éteindre ton alarme.';

  @override
  String get onboardingV2MissionPickerHint =>
      'Le plus optimal est de bouger quelque part, mais tu peux choisir une autre mission si tu en as envie. Tu pourras éditer tout ça à tout instant.';

  @override
  String get onboardingV2KeepChoosePlace => 'Choisir un endroit';

  @override
  String get onboardingV2ChooseOtherMission => 'Choisir une autre mission';

  @override
  String get onboardingMorningPlanTitle => 'Ton plan matinal';

  @override
  String onboardingMorningPlanSubtitle(String time) {
    return 'Voici à quoi ressemble demain à $time';
  }

  @override
  String onboardingStartsIn(String countdown) {
    return 'Commence dans $countdown';
  }

  @override
  String get onboardingHeresTomorrow => 'VOICI DEMAIN';

  @override
  String onboardingAlarmRings(String time) {
    return '$time — L\'alarme sonne';
  }

  @override
  String onboardingCompleteMission(String mission) {
    return 'Complète $mission';
  }

  @override
  String get onboardingYoureUp =>
      'La journée commence sur une grosse victoire 🏆';

  @override
  String get onboardingNoSnooze =>
      'Pas de boucle de snooze. Une action, puis ta journée démarre avec élan.';

  @override
  String get onboardingWakeReceipt =>
      'Reçu de réveil\n(Espace réservé à l\'image)';

  @override
  String get onboardingRiseAndRepeat => 'Se lever et répéter.';

  @override
  String onboardingAlarmFrequency(int count) {
    return 'Ton alarme sonne ${count}x par semaine. Construis la série.';
  }

  @override
  String get onboardingNotificationTitle => 'Reste sur la bonne voie';

  @override
  String get onboardingNotificationSubtitle =>
      'Nous t\'enverrons un rappel pour ne jamais manquer ton heure de réveil.';

  @override
  String get onboardingNotificationEnable => 'Activer';

  @override
  String get onboardingNotificationNotNow => 'Pas maintenant';

  @override
  String get onboardingPaywallTitle =>
      'Nous voulons te faire \nessayer Levio gratuitement.';

  @override
  String get onboardingPaywallSecondsRemaining => 'secondes restantes';

  @override
  String get onboardingPaywallKeepGoing => 'Continue ! Fais tes pompes';

  @override
  String get onboardingPaywallNoPayment => 'Aucun paiement maintenant';

  @override
  String get onboardingPaywallTryFree => 'Essayer pour 0,00 €';

  @override
  String get onboardingPaywallNoCommitment =>
      'Sans engagement, annule à tout moment.';

  @override
  String get onboardingPaywallPrivacy => 'Politique de confidentialité';

  @override
  String get onboardingPaywallRestore => 'Restaurer l\'achat';

  @override
  String get onboardingPaywallTerms => 'Conditions d\'utilisation';

  @override
  String get onboardingPaywallEula => 'CLUF';

  @override
  String get onboardingRatingTitle => 'Donne-nous une note';

  @override
  String get onboardingRatingSubtitle =>
      'Levio a été fait pour\ndes personnes comme toi';

  @override
  String get onboardingRatingMarc => 'Marc L.';

  @override
  String get onboardingRatingMarcReview =>
      'Avant, je mettais 5 alarmes chaque matin. Maintenant je me réveille à la première et je me sens bien.';

  @override
  String get onboardingRatingSophie => 'Sophie D.';

  @override
  String get onboardingRatingSophieReview =>
      'La fonctionnalité mission est géniale. Faire des pompes à 6h du matin semble fou, mais ça me réveille plus vite que le café.';

  @override
  String get onboardingRatingAlex => 'Alex T.';

  @override
  String get onboardingRatingAlexReview =>
      'Enfin une appli de réveil qui marche. J\'ai tout essayé et Levio est la seule qui me fait sortir du lit.';

  @override
  String get onboardingReferralTitle =>
      'Entrer un code de parrainage\n(optionnel)';

  @override
  String get onboardingReferralSubtitle => 'Tu peux passer cette étape';

  @override
  String get onboardingReferralLabel => 'Code de parrainage';

  @override
  String get onboardingReferralSubmit => 'Soumettre';

  @override
  String get onboardingReferralApplied => 'Code de parrainage appliqué !';

  @override
  String get onboardingReferralInvalid => 'Code de parrainage invalide';

  @override
  String get onboardingReferralLimit =>
      'Ce code a atteint sa limite d\'utilisation';

  @override
  String get onboardingSignatureTitle => 'Engage-toi\nà te lever';

  @override
  String onboardingSignatureSubtitle(String time) {
    return 'Signe ci-dessous pour sortir du lit à $time. Les pieds au sol.';
  }

  @override
  String get onboardingSignatureCommit => 'Je m\'engage';

  @override
  String get onboardingTimePickerTitle =>
      'À quelle heure tu veux te réveiller ?';

  @override
  String onboardingTimePickerSubtitle(String time) {
    return 'Nous te réveillerons à $time avec ta mission.';
  }

  @override
  String get onboardingSoundPickerTitle => 'Choisis ton son d\'alarme';

  @override
  String get onboardingTimelineTypical => 'MATIN TYPIQUE';

  @override
  String get onboardingTimelineLevio => 'MATIN LEVIO';

  @override
  String get onboardingTimelineAlarm => 'Alarme';

  @override
  String get onboardingTimelineSnooze => 'Snooze';

  @override
  String get onboardingTimelinePanic => 'Panique';

  @override
  String get onboardingTimelineMission => 'Mission';

  @override
  String get onboardingTimelineStarted => 'Debout';

  @override
  String get onboardingTimelineGained => 'GAGNÉES';

  @override
  String get onboardingTimelineMins => '25 MINS';

  @override
  String get onboardingTimelineOutcomePanic => 'Panique';

  @override
  String get onboardingTimelineOutcomeStress => 'Stress';

  @override
  String get onboardingTimelineOutcomeFatigue => 'Fatigue';

  @override
  String get onboardingTimelineOutcomeFog => 'Brouillard';

  @override
  String get onboardingTimelineOutcomeSerenity => 'Sérénité';

  @override
  String get onboardingTimelineOutcomeEnergy => 'Énergie';

  @override
  String get onboardingTimelineOutcomeHealth => 'Bonne santé';

  @override
  String get onboardingTrialTitle =>
      'Nous t\'enverrons\nun rappel avant\nla fin de ton essai gratuit';

  @override
  String get onboardingTrialNoPayment => 'Aucun paiement maintenant';

  @override
  String get onboardingTrialContinueFree => 'Continuer gratuitement';

  @override
  String get onboardingTrialPrice => 'Seulement 29,99 €/an (2,50 €/mois)';

  @override
  String get onboardingEnergyTitle => 'Niveaux d\'énergie matinale';

  @override
  String get onboardingEnergyLevio => 'Protocole Levio';

  @override
  String get onboardingEnergySnoozeCycle => 'CYCLE DE SNOOZE';

  @override
  String get onboardingEnergyGroggyZone => 'ZONE DE BROUILLARD';

  @override
  String get onboardingSpeedometerSlow => 'Lent';

  @override
  String get onboardingSpeedometerGroggy => 'Brouillard';

  @override
  String get onboardingSpeedometerInstant => 'Instantané';

  @override
  String get onboardingSpeedometerActive => 'Actif';

  @override
  String get onboardingSpeedometerBody =>
      'Levio élimine la friction du snooze pour\ndes réveils instantanés.';

  @override
  String get onboardingSpeedometerFaster => 'PLUS RAPIDE';

  @override
  String get onboardingSpeedometerMultiplier => '5.0x';

  @override
  String get missionExplPushUpsTitle => 'Pourquoi les pompes te réveillent';

  @override
  String get missionExplPushUpsSubtitle =>
      'Active ta circulation sanguine immédiatement';

  @override
  String get missionExplPushUpsBody =>
      'Les pompes activent ta poitrine, tes bras et ton tronc — inondant ton cerveau d\'oxygène et accélérant ton rythme cardiaque. En quelques secondes, ton corps passe du mode sommeil à pleinement alerte. C\'est le moyen le plus rapide d\'éliminer la somnolence matinale.';

  @override
  String get missionExplSquatsTitle => 'Pourquoi les squats te réveillent';

  @override
  String get missionExplSquatsSubtitle => 'Active tes plus gros muscles';

  @override
  String get missionExplSquatsBody =>
      'Les squats activent tes fessiers, quadriceps et ischio-jambiers — les plus grands groupes musculaires de ton corps. Cela déclenche un afflux de sang et élève rapidement ta température corporelle. Ton cerveau reçoit le signal : c\'est parti.';

  @override
  String get missionExplShakeTitle =>
      'Pourquoi secouer ton téléphone te réveille';

  @override
  String get missionExplShakeSubtitle => 'Te force à bouger';

  @override
  String get missionExplShakeBody =>
      'Secouer ton téléphone force le mouvement des bras et la coordination, sortant ton cerveau du pilote automatique. Le mouvement répétitif active ton cortex moteur et fait circuler ton sang — transformant un moment de somnolence en engagement physique.';

  @override
  String get missionExplMathTitle => 'Pourquoi résoudre des maths te réveille';

  @override
  String get missionExplMathSubtitle => 'Réveille ton cerveau';

  @override
  String get missionExplMathBody =>
      'Les problèmes de maths forcent ton cortex préfrontal à s\'activer — la partie de ton cerveau responsable de la logique et de la prise de décision. Même l\'arithmétique simple te sort de l\'inertie du sommeil en exigeant une pensée concentrée et consciente.';

  @override
  String get missionExplSkyPhotoTitle =>
      'Pourquoi prendre une photo du ciel te réveille';

  @override
  String get missionExplSkyPhotoSubtitle => 'T\'amène à la fenêtre';

  @override
  String get missionExplSkyPhotoBody =>
      'Marcher jusqu\'à une fenêtre et regarder le ciel t\'expose à la lumière naturelle — le signal le plus puissant pour arrêter la production de mélatonine. Même les jours nuageux, l\'intensité lumineuse extérieure est bien supérieure à l\'éclairage intérieur, recalibrant rapidement ton horloge circadienne.';

  @override
  String get missionExplMakeBedTitle => 'Pourquoi faire ton lit te réveille';

  @override
  String get missionExplMakeBedSubtitle =>
      'Commence ta journée par une victoire';

  @override
  String get missionExplMakeBedBody =>
      'Faire ton lit est un micro-accomplissement qui déclenche une petite dose de dopamine. Cela signale à ton cerveau que la journée a commencé et supprime la tentation de te recoucher. Une tâche accomplie crée l\'élan pour la suivante.';

  @override
  String get missionExplObjectHuntTitle =>
      'Pourquoi la chasse aux objets te réveille';

  @override
  String get missionExplObjectHuntSubtitle => 'Te fait sortir du lit';

  @override
  String get missionExplObjectHuntBody =>
      'Chercher un objet spécifique te force à sortir du lit et à bouger. Ton cerveau passe du repos passif à la résolution active de problèmes — balayant, reconnaissant et se déplaçant. Le temps de le trouver, l\'inertie du sommeil a disparu.';

  @override
  String get missionExplPetHuntTitle =>
      'Pourquoi trouver ton animal te réveille';

  @override
  String get missionExplPetHuntSubtitle => 'Moment de complicité matinale';

  @override
  String get missionExplPetHuntBody =>
      'Interagir avec ton animal libère de l\'ocytocine — l\'hormone de l\'attachement qui élève naturellement ton humeur et ta vigilance. Se déplacer dans ta maison pour le trouver ajoute de l\'activité physique, tandis que la connexion émotionnelle donne un ancrage positif à ton matin.';

  @override
  String get missionExplNatureHuntTitle =>
      'Pourquoi la chasse nature te réveille';

  @override
  String get missionExplNatureHuntSubtitle => 'Te connecte à l\'extérieur';

  @override
  String get missionExplNatureHuntBody =>
      'Sortir pour trouver quelque chose dans la nature combine mouvement, air frais et lumière naturelle — les trois signaux de réveil les plus efficaces. Le changement sensoriel de la chambre à l\'extérieur propulse ton système nerveux en pleine alerte.';

  @override
  String get missionExplTouchGrassTitle =>
      'Pourquoi toucher l\'herbe te réveille';

  @override
  String get missionExplTouchGrassSubtitle => 'Ancre-toi dans le matin';

  @override
  String get missionExplTouchGrassBody =>
      'Sortir pour photographier l\'herbe t\'expose simultanément au soleil et à l\'air frais. L\'acte de se pencher et de se concentrer sur la nature engage ton corps et tes sens, créant un réveil complet corps-esprit qu\'aucun son d\'alarme ne peut égaler.';

  @override
  String get missionExplAffirmationTitle =>
      'Pourquoi les affirmations te réveillent';

  @override
  String get missionExplAffirmationSubtitle =>
      'Définit ton état d\'esprit pour la journée';

  @override
  String get missionExplAffirmationBody =>
      'Prononcer une affirmation à voix haute active ta voix, ton souffle et ta concentration simultanément. L\'acte de lire et de répéter engage plusieurs régions du cerveau — te faisant passer de la somnolence passive à la pensée intentionnelle et consciente.';

  @override
  String get generalOk => 'OK';

  @override
  String get generalCancel => 'Annuler';

  @override
  String get generalSubmit => 'Soumettre';

  @override
  String get generalContinue => 'Continuer';

  @override
  String get generalNone => 'Aucun';

  @override
  String get generalDefault => 'Par défaut';

  @override
  String get generalDelete => 'Supprimer';

  @override
  String get onboardingUsualWakeTimeTitle =>
      'À quelle heure sors-tu habituellement du lit ?';

  @override
  String get onboardingUsualWakeTimeSubtitle =>
      'Cela nous aide à fixer un premier objectif réaliste.';

  @override
  String get onboardingIdealWakeTimeTitle =>
      'À quelle heure\nveux-tu te lever ?';

  @override
  String get onboardingIdealWakeTimeSubtitle =>
      'Ton heure de réveil idéale quotidienne.';

  @override
  String onboardingTargetWakeTime(String time) {
    return 'Se réveiller à $time est ton objectif.';
  }

  @override
  String onboardingDeltaPerMorning(int delta) {
    return '+$delta minutes chaque matin';
  }

  @override
  String onboardingDeltaPerMonth(int hours) {
    return '+$hours heures ce mois-ci';
  }

  @override
  String get onboardingQuoteWinMorning =>
      'Si tu gagnes\nle matin,\ntu gagnes la journée.';

  @override
  String get onboardingQuoteWinMorningAuthor => '— Tim Ferriss';

  @override
  String get onboardingSignInCreateTitle => 'Crée ton compte';

  @override
  String get onboardingSignInCreateSubtitle =>
      'Sauvegarde ta progression et synchronise ton plan.';

  @override
  String get onboardingSignInTitle => 'Ravis de te revoir';

  @override
  String get onboardingSignInSubtitle =>
      'Connecte-toi pour restaurer ton plan.';

  @override
  String get soundPickerFileTooLarge => 'Fichier trop volumineux (max 10 Mo)';

  @override
  String get soundPickerDeleteTitle => 'Supprimer le son';

  @override
  String soundPickerDeleteContent(String name) {
    return 'Retirer « $name » ?';
  }

  @override
  String get screenTimeTitle => 'Temps d\'écran';

  @override
  String get screenTimeSubtitle =>
      'Bloque les applis distrayantes pendant ta fenêtre de sommeil.';

  @override
  String get screenTimeStatusInactive => 'Inactif';

  @override
  String screenTimeStatusActiveUntil(String time) {
    return 'Actif jusqu\'à $time';
  }

  @override
  String screenTimeStatusActiveIn(String duration) {
    return 'Actif dans $duration';
  }

  @override
  String get screenTimeActivated => 'Activé';

  @override
  String get screenTimePickApps => 'Applis à bloquer';

  @override
  String screenTimeAppsBlocked(int count) {
    return '$count applis bloquées';
  }

  @override
  String get screenTimeNoAppsSelected => 'Choisir les applis à bloquer';

  @override
  String get screenTimeSchedulesTitle => 'Horaires';

  @override
  String get screenTimeAddSchedule => 'Ajouter';

  @override
  String get screenTimeNoSchedules =>
      'Aucun horaire. Ajoutes-en un pour bloquer les applis sur une plage récurrente.';

  @override
  String get screenTimeScheduleNew => 'Nouvel horaire';

  @override
  String get screenTimeScheduleEdit => 'Modifier l\'horaire';

  @override
  String get screenTimeStartTime => 'Début';

  @override
  String get screenTimeEndTime => 'Fin';

  @override
  String get screenTimeSaveSchedule => 'Enregistrer l\'horaire';

  @override
  String get screenTimeLockedHint =>
      'Les réglages sont verrouillés pendant le blocage pour protéger ton sommeil.';

  @override
  String get screenTimeUnlock => 'Déverrouiller';

  @override
  String get screenTimeUnlockConfirmTitle =>
      'Prends 30 secondes pour y réfléchir';

  @override
  String get screenTimeUnlockConfirmBody =>
      'Il ne faut que 3 à 7 jours pour ancrer une nouvelle routine — et après ça, te réveiller ne te demandera presque aucun effort. Tu es en plein dedans. Ne cède pas ce soir ; ton futur toi compte sur toi. Respire un instant plutôt que de déverrouiller.';

  @override
  String get screenTimeUnlockConfirmCancel => 'Garder verrouillé';

  @override
  String get screenTimeUnlockConfirmBreathe => 'Respirer plutôt';

  @override
  String get screenTimeUnlockConfirmProceed => 'Déverrouiller quand même';

  @override
  String get screenTimeUnlockCountdownTitle => 'Tu peux déverrouiller dans';

  @override
  String get screenTimeUnlockReadyTitle => 'Tu peux déverrouiller maintenant';

  @override
  String get screenTimeUnlockCountdownHint =>
      'Garde Levio ouvert. Quitter l\'appli redémarre le minuteur.';

  @override
  String get screenTimeUnlockStreakWarning => 'Désactiver brisera ta série.';

  @override
  String get screenTimeAuthDenied =>
      'L\'accès au Temps d\'écran est requis. Active-le pour Levio dans les Réglages iOS.';

  @override
  String get osUpdateRequiredTitle => 'Passons à la mise à jour 🚀';

  @override
  String get osUpdateRequiredBody =>
      'Les alarmes de Levio utilisent les dernières technologies d\'Apple : ton iPhone a donc besoin de la version la plus récente d\'iOS pour te réveiller. Ça ne prend que quelques minutes :';

  @override
  String get osUpdateStep1 => 'Ouvre l\'app Réglages';

  @override
  String get osUpdateStep2 => 'Va dans Général → Mise à jour logicielle';

  @override
  String get osUpdateStep3 => 'Installe la mise à jour, puis reviens sur Levio';

  @override
  String get osUpdateButton => 'C\'est compris';

  @override
  String get alarmPermissionTitle => 'Ton alarme ne sonnera pas ⏰';

  @override
  String get alarmPermissionBody =>
      'Levio n\'a pas la permission de programmer des alarmes, il ne peut donc pas te réveiller. Touche ci-dessous et choisis « Autoriser » pour que ton alarme sonne vraiment.';

  @override
  String get alarmPermissionDeniedBody =>
      'L\'accès aux alarmes est désactivé, tes alarmes ne sonneront donc pas. Voici comment le réactiver dans Réglages :';

  @override
  String get alarmPermissionStep1 => 'Ouvre Réglages et trouve Levio';

  @override
  String get alarmPermissionStep2 => 'Active l\'option des alarmes';

  @override
  String get alarmPermissionStep3 => 'Reviens, et tout est prêt';

  @override
  String get alarmPermissionEnable => 'Activer les alarmes';

  @override
  String get alarmPermissionOpenSettings => 'Ouvrir les Réglages';

  @override
  String get alarmPermissionNotNow => 'Plus tard';

  @override
  String get routineOpenCurtains => 'Ouvrir les rideaux ou la lumière';

  @override
  String get routineExercise => 'Faire 10 pompes ou 20 squats';

  @override
  String get routineShower => 'Prendre une douche';

  @override
  String get routineBreakfast => 'Prendre le petit-déjeuner';

  @override
  String get routineGetDressed => 'S\'habiller';

  @override
  String get routinePutPhoneAway => 'Ranger ton téléphone';

  @override
  String get routineLowerTemp => 'Baisser la température de la pièce';

  @override
  String get routineModeWake => 'Matin';

  @override
  String get routineModeNight => 'Soir';

  @override
  String get onboardingV2MultiSelectHint =>
      'Sélectionne tout ce qui s\'applique';

  @override
  String get onboardingV2WakeChallengesTitle =>
      'Qu\'est-ce qui est le plus dur au réveil ?';

  @override
  String get onboardingV2WakeChallengeSleepThrough =>
      'Je n\'entends pas mon alarme';

  @override
  String get onboardingV2WakeChallengeSnooze =>
      'Je suis pris dans la boucle du rappel';

  @override
  String get onboardingV2WakeChallengeStayInBed =>
      'Je reste trop longtemps au lit';

  @override
  String get onboardingV2WakeChallengeScroll =>
      'Je scrolle mon téléphone au réveil';

  @override
  String get onboardingV2WakeChallengeFallAsleep => 'Je me rendors';

  @override
  String get onboardingV2WakeChallengeTired => 'Je me sens complètement épuisé';

  @override
  String get onboardingV2WakeChallengeMindFog => 'J\'ai l\'esprit embrumé';

  @override
  String get onboardingV2WakeChallengeAnxiety =>
      'Je me réveille anxieux ou stressé';

  @override
  String get onboardingV2DesiredFeelingsTitle =>
      'Comment veux-tu te réveiller ?';

  @override
  String get onboardingV2FeelWakeStraight => 'Debout du premier coup';

  @override
  String get onboardingV2FeelEnergy => 'Plein d\'énergie';

  @override
  String get onboardingV2FeelGood => 'Bien dans ma peau';

  @override
  String get onboardingV2FeelConfident => 'En confiance';

  @override
  String get onboardingV2FeelWinDay => 'Prêt à gagner ma journée';

  @override
  String get onboardingV2ProofScientistsTitle =>
      'Conçu par des experts du sommeil';

  @override
  String get onboardingV2ProofScientistsSubtitle =>
      'Validé par la recherche scientifique';

  @override
  String get onboardingV2ProofScientistsBody =>
      'Chaque étape de la méthode Levio s\'appuie sur la recherche sur les rythmes circadiens et l\'inertie du sommeil — pensée avec des experts du sommeil pour vraiment te lever.';

  @override
  String get onboardingV2FirstRoomTitle =>
      'Où vas-tu en premier en sortant du lit ?';

  @override
  String get onboardingV2FirstRoomSubtitle =>
      'Ta mission t\'y mènera — bouger casse l\'inertie du sommeil.';

  @override
  String get onboardingV2RoomKitchen => 'La cuisine';

  @override
  String get onboardingV2RoomBathroom => 'La salle de bain';

  @override
  String get onboardingV2RoomOutside => 'Dehors';

  @override
  String get onboardingV2RoomOther => 'Autre chose';

  @override
  String get onboardingV2WakeRoutineTitle => 'Garde ton élan';

  @override
  String get onboardingV2WakeRoutineSubtitle =>
      'C\'est en surfant sur l\'élan de ta mission que tes matins tiennent dans la durée. Choisis ce que tu fais ensuite.';

  @override
  String get onboardingRoutineModify => 'Modifier la routine';

  @override
  String get onboardingV2WakeRoutineRow => 'Ta routine du matin';

  @override
  String get onboardingV2NightRoutineRow => 'Ta routine du soir';

  @override
  String get onboardingV2SleepTiredTitle =>
      'Te sens-tu fatigué dans la journée ?';

  @override
  String get onboardingV2SleepTiredOften => 'Souvent';

  @override
  String get onboardingV2SleepTiredSometimes => 'Parfois';

  @override
  String get onboardingV2SleepTiredRarely => 'Rarement';

  @override
  String get onboardingV2SleepChallengesTitle =>
      'Qu\'est-ce qui nuit à ton sommeil ?';

  @override
  String get onboardingV2SleepChallengeHardToFall =>
      'J\'ai du mal à m\'endormir';

  @override
  String get onboardingV2SleepChallengeWakeAtNight => 'Je me réveille la nuit';

  @override
  String get onboardingV2SleepChallengeLateBed => 'Je me couche trop tard';

  @override
  String get onboardingV2SleepChallengeRacingMind => 'Mon esprit s\'emballe';

  @override
  String get onboardingV2SleepChallengeNotEnough => 'Je ne dors jamais assez';

  @override
  String get onboardingV2SleepChallengeGroggy => 'Je scrolle sur mon téléphone';

  @override
  String get onboardingV2SleepQualityTitle =>
      'Le sommeil, c\'est le plus important';

  @override
  String get onboardingV2SleepQualitySubtitle =>
      'Facteur premier d\'un réveil facile';

  @override
  String get onboardingV2SleepQualityBody =>
      'Le sommeil est le facteur n°1 de ta capacité à te réveiller, de ta forme dans la journée et de ta santé à long terme. Et une heure de coucher régulière est le levier le plus puissant pour l\'améliorer.';

  @override
  String get onboardingV2SleepQualityReferences =>
      'Windred et al. (2024). La régularité du sommeil prédit mieux la mortalité que sa durée. Sleep.\nPhillips et al. (2017). Des rythmes veille/sommeil irréguliers sont liés à de moins bonnes performances. Scientific Reports.';

  @override
  String get onboardingV2SleepSolutionTitle =>
      'Levio t\'aide à créer une routine';

  @override
  String get onboardingV2SleepSolutionSubtitle => 'Basée sur la science';

  @override
  String get onboardingV2SleepSolutionBody =>
      'Levio crée la routine parfaite pour t\'aider à t\'endormir et installer de la régularité.';

  @override
  String get onboardingV2ConsistencyTitle => 'La régularité change tout';

  @override
  String get onboardingV2ConsistencySubtitle =>
      'Une heure de coucher régulière est le levier n°1 — les utilisateurs avec une alarme de coucher obtiennent _3× de meilleurs résultats_. Tu veux aussi une alarme de coucher ?';

  @override
  String get onboardingV2Recall200kTitle => 'Rejoins 500 000 lève-tôt';

  @override
  String get onboardingV2Recall200kBody =>
      'Tu es sur le point de rejoindre une communauté qui se réveille à ses conditions — chaque matin.';

  @override
  String get onboardingV2LoadingStep1 => 'Personnalisation de ton plan';

  @override
  String get onboardingV2LoadingStep2 =>
      'Configuration de ta mission de réveil';

  @override
  String get onboardingV2LoadingStep3 => 'Création de ta routine du matin';

  @override
  String get onboardingV2LoadingStep4 => 'Création de ta routine de sommeil';

  @override
  String get onboardingV2LoadingStep5 => 'Programmation de tes alarmes';

  @override
  String get onboardingV2LoadingStep6 => 'Finalisation de ton compte';
}
