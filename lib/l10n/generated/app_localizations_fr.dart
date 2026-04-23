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
  String get alarmsEmptyHint =>
      'Appuyez sur + pour créer votre première alarme';

  @override
  String get alarmsMissionAlarm => 'Alarme Mission';

  @override
  String get alarmsMissionAlarmSubtitle => 'Complétez une tâche d\'abord';

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
      'Empilez les missions et complétez-les pour éteindre l\'alarme';

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
  String get soundPickerTitle => 'Son de l\'alarme';

  @override
  String get soundPickerYourSounds => 'Vos sons';

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
      'Appuyez pour en créer une avec une mission';

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
  String get homeSetAlarmToStart => 'Créez une alarme pour commencer';

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
  String get missionPushUpsDesc => 'Filmez-vous en faisant des pompes';

  @override
  String get missionSquats => 'Squats';

  @override
  String get missionSquatsDesc => 'Filmez-vous en faisant des squats';

  @override
  String get missionShakePhone => 'Secouer le téléphone';

  @override
  String get missionShakePhoneDesc =>
      'Secouez votre téléphone pour vous réveiller';

  @override
  String get missionMath => 'Maths';

  @override
  String get missionMathDesc => 'Résolvez des problèmes de maths';

  @override
  String get missionSkyPhoto => 'Photo du ciel';

  @override
  String get missionSkyPhotoDesc => 'Prenez une photo du ciel';

  @override
  String get missionMakeBed => 'Faire le lit';

  @override
  String get missionMakeBedDesc => 'Prenez une photo de votre lit fait';

  @override
  String get missionObjectHunt => 'Chasse aux objets';

  @override
  String get missionObjectHuntDesc =>
      'Trouvez et photographiez un objet de la maison';

  @override
  String get missionPetHunt => 'Chasse aux animaux';

  @override
  String get missionPetHuntDesc => 'Trouvez et photographiez votre animal';

  @override
  String get missionNatureHunt => 'Chasse nature';

  @override
  String get missionNatureHuntDesc =>
      'Trouvez et photographiez un élément naturel';

  @override
  String get missionTouchGrass => 'Toucher l\'herbe';

  @override
  String get missionTouchGrassDesc => 'Prenez une photo de l\'herbe';

  @override
  String get missionAffirmation => 'Affirmation';

  @override
  String get missionAffirmationDesc => 'Lisez une affirmation à voix haute';

  @override
  String get missionRandom => 'Aléatoire';

  @override
  String get missionRandomDesc => 'Mission surprise chaque matin';

  @override
  String get missionNone => 'Pas de mission';

  @override
  String get missionNoneDesc => 'Alarme simple sans tâche';

  @override
  String get photoTargetSky => 'le ciel';

  @override
  String get photoTargetMadeBed => 'votre lit fait';

  @override
  String get photoTargetGrass => 'l\'herbe';

  @override
  String get missionPickerTitle => 'Choisir une mission';

  @override
  String get missionPickerAll => 'Tout';

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
  String get itemPickerSelectItems => 'Sélectionner les objets';

  @override
  String get itemPickerRandomItem =>
      'Un objet aléatoire sera choisi chaque matin';

  @override
  String get itemPickerHouseholdItems => 'Objets de la maison';

  @override
  String get itemPickerFunItems => 'Objets amusants';

  @override
  String get itemPickerSelectPets => 'Sélectionner vos animaux';

  @override
  String get itemPickerPetsSubtitle =>
      'Sélectionnez les animaux que vous avez à la maison';

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
  String get itemPickerAddOwn => 'Ajoutez votre propre objet';

  @override
  String get itemPickerDone => 'Terminé';

  @override
  String get itemPickerCustomItems => 'Objets personnalisés';

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
  String get affirmationPickerAddOwn => 'Ajoutez votre propre affirmation';

  @override
  String get affirmationPickerDone => 'Terminé';

  @override
  String get randomPoolTitle => 'Pool aléatoire';

  @override
  String get randomPoolSubtitle =>
      'Sélectionnez les missions à inclure dans la rotation aléatoire';

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
  String get settingsLogout => 'Se déconnecter';

  @override
  String get settingsLogoutTitle => 'Se déconnecter ?';

  @override
  String get settingsLogoutBody =>
      'Vous serez déconnecté de cet appareil. Les paramètres locaux et les alarmes programmées seront effacés.';

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
      'Cette action supprime définitivement votre compte, vos alarmes, vos sessions et votre historique de séries. Elle est irréversible.';

  @override
  String get settingsDeleteAccountConfirm => 'Supprimer';

  @override
  String get settingsDeleteAccountCancel => 'Annuler';

  @override
  String get settingsDeleteAccountReauthRequired =>
      'Veuillez vous reconnecter, puis réessayer de supprimer votre compte.';

  @override
  String get settingsDeleteAccountError =>
      'Impossible de supprimer votre compte. Veuillez réessayer.';

  @override
  String get settingsVersion => 'Levio v0.1.0';

  @override
  String get referralTitle => 'Entrer un code de parrainage';

  @override
  String get referralCodeLabel => 'Code de parrainage';

  @override
  String referralApplied(String type) {
    return 'Code appliqué ! Vous êtes maintenant : $type';
  }

  @override
  String get referralInvalid => 'Code de parrainage invalide';

  @override
  String get referralUsageLimit => 'Ce code a atteint sa limite d\'utilisation';

  @override
  String get referralError => 'Une erreur est survenue, veuillez réessayer';

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
      'Votre score de régularité mesure la fréquence à laquelle vous vous réveillez avec Levio. Il s\'améliore au fur et à mesure que votre série grandit.';

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
  String get milestonesAchievementBadges => 'Badges de réussite';

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
      'Réveillez-vous avec Levio chaque jour pour construire votre série. Vous avez 2 jours de gel par semaine pour sauter sans perdre votre progression. Si vous manquez un jour sans gel, votre série baisse de 3 au lieu de revenir à zéro.';

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
      'Une semaine de matins — vous réécrivez votre histoire.';

  @override
  String get badgeAurora => 'Aurore';

  @override
  String get badgeAuroraReq => '14 jours';

  @override
  String get badgeAuroraQuote =>
      'Deux semaines de levers de soleil. Continuez à poursuivre la lumière.';

  @override
  String get badgeCelestial => 'Céleste';

  @override
  String get badgeCelestialReq => '30 jours';

  @override
  String get badgeCelestialQuote =>
      'Un mois complet de levers. Vous êtes inarrêtable.';

  @override
  String get badgeNebula => 'Nébuleuse';

  @override
  String get badgeNebulaReq => '100 jours';

  @override
  String get badgeNebulaQuote => 'Cent matins. Un nouveau vous est né.';

  @override
  String get badgeEternal => 'Éternel';

  @override
  String get badgeEternalReq => '365 jours';

  @override
  String get badgeEternalQuote =>
      'Une année complète de matins. Vous êtes légendaire.';

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
  String get wakeupTitle => 'Réveil du jour';

  @override
  String get wakeupStartMyDay => 'Commencer ma journée';

  @override
  String get wakeupCongratulations => 'Félicitations.';

  @override
  String get wakeupThanks =>
      'Grâce à Levio, vous vous êtes réveillé aujourd\'hui.';

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
      'Peu importe la lenteur à laquelle vous avancez, pourvu que vous ne vous arrêtiez pas.';

  @override
  String get quoteConfuciusAuthor => 'Confucius';

  @override
  String get quoteChurchill =>
      'Le succès n\'est pas définitif, l\'échec n\'est pas fatal.';

  @override
  String get quoteChurchillAuthor => 'Winston Churchill';

  @override
  String get quoteRoosevelt =>
      'Croyez que vous pouvez et vous êtes à mi-chemin.';

  @override
  String get quoteRooseveltAuthor => 'Theodore Roosevelt';

  @override
  String get quoteJobs =>
      'La seule façon de faire du bon travail est d\'aimer ce que vous faites.';

  @override
  String get quoteJobsAuthor => 'Steve Jobs';

  @override
  String get quoteUnknown =>
      'Réveillez-vous avec détermination, couchez-vous avec satisfaction.';

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
      'Secouez votre téléphone pour arrêter l\'alarme';

  @override
  String dismissMathProgress(int current, int total) {
    return '$current / $total';
  }

  @override
  String get dismissMathWrong => 'Faux — réessayez !';

  @override
  String get dismissMathConfirm => 'Confirmer';

  @override
  String dismissPhotoPrompt(String target) {
    return 'Prenez une photo de $target pour arrêter l\'alarme';
  }

  @override
  String dismissPhotoChecking(String target) {
    return 'Vérification de $target…';
  }

  @override
  String get dismissPhotoStarting => 'Démarrage de la caméra…';

  @override
  String dismissPhotoNotDetected(String target) {
    return 'Aucun $target détecté — réessayez';
  }

  @override
  String dismissPhotoError(String error) {
    return 'Erreur : $error';
  }

  @override
  String get dismissPhotoTakePhoto => 'PRENEZ UNE PHOTO DE';

  @override
  String get dismissSpeechSay => 'Dites :';

  @override
  String get dismissSpeechListening => 'Écoute en cours…';

  @override
  String get dismissSpeechTapToSpeak => 'Appuyez pour parler';

  @override
  String dismissSpeechTryAgain(int score) {
    return '$score% — réessayez';
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
    return 'Faites $target $mission pour arrêter l\'alarme';
  }

  @override
  String dismissRepOf(int target) {
    return 'de $target';
  }

  @override
  String get dismissMissionTimeToWakeUp => 'C\'est l\'heure de se réveiller !';

  @override
  String dismissMissionLabel(int current, int total, String name) {
    return 'Mission $current/$total : $name';
  }

  @override
  String get dismissStartMission => 'Commencer la mission';

  @override
  String get dismissFeedbackMoveIntoFrame =>
      'Placez tout votre corps dans le cadre';

  @override
  String get dismissFeedbackKeepGoing => 'Oui, continuez !';

  @override
  String get dismissFeedbackPushupPosition =>
      'Allongez-vous en position de pompe';

  @override
  String get dismissFeedbackStartPushups => 'Commencez vos pompes !';

  @override
  String get dismissFeedbackPushupGoDeeper =>
      'Descendez plus bas, votre poitrine doit toucher le sol !';

  @override
  String get dismissFeedbackSquatPosition =>
      'Levez-vous pour commencer les squats';

  @override
  String get dismissFeedbackStartSquats => 'Commencez vos squats !';

  @override
  String get dismissFeedbackSquatGoDeeper =>
      'Descendez plus bas, vos cuisses doivent être parallèles au sol !';

  @override
  String get onboardingMorningPerson => 'Vous sentez-vous du matin ?';

  @override
  String get onboardingYes => 'Oui';

  @override
  String get onboardingNotYet => 'Pas encore';

  @override
  String get onboardingAgeRange => 'Quelle est votre tranche d\'âge ?';

  @override
  String get onboardingDescribesYou => 'Qu\'est-ce qui vous décrit le mieux ?';

  @override
  String get onboardingMale => 'Homme';

  @override
  String get onboardingFemale => 'Femme';

  @override
  String get onboardingOther => 'Autre';

  @override
  String get onboardingKeepsInBed =>
      'Qu\'est-ce qui vous retient au lit après l\'alarme ?';

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
  String get onboardingGetsYouOut => 'Levio vous fait sortir du lit';

  @override
  String get onboardingAvoidGroggy =>
      'Évitez la « zone de brouillard ». Levio vous propulse directement en état d\'alerte.';

  @override
  String get onboardingHowManyAlarms => 'Combien d\'alarmes mettez-vous ?';

  @override
  String get onboardingOne => 'Une';

  @override
  String get onboardingTwoThree => '2-3';

  @override
  String get onboardingFourPlus => '4+';

  @override
  String get onboardingOneAlarmWakeUp =>
      'Si vous ne mettiez qu\'une alarme, vous réveillerez-vous ?';

  @override
  String get onboardingSometimes => 'Parfois';

  @override
  String get onboardingNo => 'Non';

  @override
  String get onboardingTurnOffGoBack =>
      'Vous arrive-t-il d\'éteindre l\'alarme et de vous rendormir ?';

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
      'Que ressentez-vous en réglant votre alarme le soir ?';

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
      'Comment vous sentez-vous juste après le réveil ?';

  @override
  String get onboardingReadyToGo => 'Prêt à foncer';

  @override
  String get onboardingGroggy => 'Brouillard';

  @override
  String get onboardingAnxiousStressed => 'Anxieux ou stressé';

  @override
  String get onboardingHowLongAwake =>
      'Combien de temps pour vous sentir pleinement éveillé ?';

  @override
  String get onboardingInstantly => 'Instantanément';

  @override
  String get onboardingTenFifteen => '10-15 minutes';

  @override
  String get onboardingThirtyPlus => '30 minutes ou plus';

  @override
  String get onboardingBiologyTitle => 'Biologie, pas paresse';

  @override
  String get onboardingBiologyBody =>
      'Votre cerveau met 15 à 30 min à éliminer l\'inertie du sommeil. Le snooze relance le cycle, empirant les choses.\n\nLevio force l\'action immédiate en sautant la zone de brouillard.';

  @override
  String get onboarding5xFaster =>
      'Sortez du lit 5x plus vite avec Levio vs tout seul';

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
  String get onboardingWhereHeard => 'Où avez-vous entendu parler de nous ?';

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
      'Arrêtez de snoozer.\nCommencez à gagner vos matins.';

  @override
  String get onboardingWelcomeSubtitle =>
      'Une alarme. Une mission. Vous êtes debout.';

  @override
  String get onboardingBuildPlan => 'Créer mon plan';

  @override
  String get onboardingJoin500k =>
      'Rejoignez 500k+ personnes qui se réveillent avec Levio';

  @override
  String get onboardingAlreadyAccount => 'Vous avez déjà un compte ? ';

  @override
  String get onboardingSignIn => 'Se connecter';

  @override
  String get onboardingSignInApple => 'Se connecter avec Apple';

  @override
  String get onboardingSignInGoogle => 'Continuer avec Google';

  @override
  String get onboardingSkipForNow => 'Passer pour l\'instant';

  @override
  String get onboardingGoogleFailed =>
      'Échec de la connexion Google. Veuillez réessayer.';

  @override
  String get onboardingAppleFailed =>
      'Échec de la connexion Apple. Veuillez réessayer.';

  @override
  String get onboardingAccountNotFound =>
      'Aucun compte trouvé. Veuillez d\'abord créer un compte via l\'inscription.';

  @override
  String get onboardingDayPickerTitle => 'Quels jours Levio doit-il sonner ?';

  @override
  String get onboardingDayPickerSubtitle =>
      'Choisissez les jours à verrouiller.';

  @override
  String get onboardingLoadingTitle => 'Tout se met en place\npour vous';

  @override
  String get onboardingLoadingStep1 => 'Analyse de vos habitudes de sommeil';

  @override
  String get onboardingLoadingStep2 => 'Configuration de vos objectifs';

  @override
  String get onboardingLoadingStep3 => 'Choix de votre mission';

  @override
  String get onboardingLoadingStep4 => 'Calibrage du son d\'alarme';

  @override
  String get onboardingLoadingStep5 => 'Programmation de votre alarme';

  @override
  String get onboardingLoadingStep6 => 'Finalisation de votre plan';

  @override
  String get onboardingMissionPickerTitle =>
      'Choisissez votre mission de réveil';

  @override
  String get onboardingMissionPickerSubtitle =>
      'Vous ferez ceci pour éteindre votre alarme.';

  @override
  String get onboardingMorningPlanTitle => 'Votre plan matinal';

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
    return 'Complétez $mission';
  }

  @override
  String get onboardingYoureUp => 'Vous êtes debout. La journée commence.';

  @override
  String get onboardingNoSnooze =>
      'Pas de boucle de snooze. Une action, puis votre journée démarre avec élan.';

  @override
  String get onboardingWakeReceipt =>
      'Reçu de réveil\n(Espace réservé à l\'image)';

  @override
  String get onboardingRiseAndRepeat => 'Se lever et répéter.';

  @override
  String onboardingAlarmFrequency(int count) {
    return 'Votre alarme sonne ${count}x par semaine. Construisez la série.';
  }

  @override
  String get onboardingNotificationTitle => 'Restez sur la bonne voie';

  @override
  String get onboardingNotificationSubtitle =>
      'Nous vous enverrons un rappel pour ne jamais manquer votre heure de réveil.';

  @override
  String get onboardingNotificationEnable => 'Activer';

  @override
  String get onboardingNotificationNotNow => 'Pas maintenant';

  @override
  String get onboardingPaywallTitle =>
      'Nous voulons vous faire \nessayer Levio gratuitement.';

  @override
  String get onboardingPaywallSecondsRemaining => 'secondes restantes';

  @override
  String get onboardingPaywallKeepGoing => 'Continuez ! Faites vos pompes';

  @override
  String get onboardingPaywallNoPayment => 'Aucun paiement maintenant';

  @override
  String get onboardingPaywallTryFree => 'Essayer pour 0,00 €';

  @override
  String get onboardingPaywallNoCommitment =>
      'Sans engagement, annulez à tout moment.';

  @override
  String get onboardingPaywallPrivacy => 'Politique de confidentialité';

  @override
  String get onboardingPaywallRestore => 'Restaurer l\'achat';

  @override
  String get onboardingPaywallTerms => 'Conditions d\'utilisation';

  @override
  String get onboardingPaywallEula => 'CLUF';

  @override
  String get onboardingRatingTitle => 'Donnez-nous une note';

  @override
  String get onboardingRatingSubtitle =>
      'Levio a été fait pour\ndes personnes comme vous';

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
  String get onboardingReferralSubtitle => 'Vous pouvez passer cette étape';

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
  String get onboardingSignatureTitle => 'Engagez-vous\nà vous lever';

  @override
  String onboardingSignatureSubtitle(String time) {
    return 'Signez ci-dessous pour sortir du lit à $time. Les pieds au sol.';
  }

  @override
  String get onboardingSignatureCommit => 'Je m\'engage';

  @override
  String get onboardingTimePickerTitle => 'Réglez votre première heure Levio';

  @override
  String onboardingTimePickerSubtitle(String time) {
    return 'Nous vous réveillerons à $time avec votre mission.';
  }

  @override
  String get onboardingSoundPickerTitle => 'Choisissez votre son d\'alarme';

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
  String get onboardingTrialTitle =>
      'Nous vous enverrons\nun rappel avant\nla fin de votre essai gratuit';

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
  String get onboardingEnergySnoozeCycle => 'Cycle de snooze';

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
  String get missionExplPushUpsTitle => 'Pourquoi les pompes vous réveillent';

  @override
  String get missionExplPushUpsSubtitle =>
      'Active votre circulation sanguine immédiatement';

  @override
  String get missionExplPushUpsBody =>
      'Les pompes activent votre poitrine, vos bras et votre tronc — inondant votre cerveau d\'oxygène et accélérant votre rythme cardiaque. En quelques secondes, votre corps passe du mode sommeil à pleinement alerte. C\'est le moyen le plus rapide d\'éliminer la somnolence matinale.';

  @override
  String get missionExplSquatsTitle => 'Pourquoi les squats vous réveillent';

  @override
  String get missionExplSquatsSubtitle => 'Active vos plus gros muscles';

  @override
  String get missionExplSquatsBody =>
      'Les squats activent vos fessiers, quadriceps et ischio-jambiers — les plus grands groupes musculaires de votre corps. Cela déclenche un afflux de sang et élève rapidement votre température corporelle. Votre cerveau reçoit le signal : c\'est parti.';

  @override
  String get missionExplShakeTitle =>
      'Pourquoi secouer votre téléphone vous réveille';

  @override
  String get missionExplShakeSubtitle => 'Vous force à bouger';

  @override
  String get missionExplShakeBody =>
      'Secouer votre téléphone force le mouvement des bras et la coordination, sortant votre cerveau du pilote automatique. Le mouvement répétitif active votre cortex moteur et fait circuler votre sang — transformant un moment de somnolence en engagement physique.';

  @override
  String get missionExplMathTitle =>
      'Pourquoi résoudre des maths vous réveille';

  @override
  String get missionExplMathSubtitle => 'Réveille votre cerveau';

  @override
  String get missionExplMathBody =>
      'Les problèmes de maths forcent votre cortex préfrontal à s\'activer — la partie de votre cerveau responsable de la logique et de la prise de décision. Même l\'arithmétique simple vous sort de l\'inertie du sommeil en exigeant une pensée concentrée et consciente.';

  @override
  String get missionExplSkyPhotoTitle =>
      'Pourquoi prendre une photo du ciel vous réveille';

  @override
  String get missionExplSkyPhotoSubtitle => 'Vous amène à la fenêtre';

  @override
  String get missionExplSkyPhotoBody =>
      'Marcher jusqu\'à une fenêtre et regarder le ciel vous expose à la lumière naturelle — le signal le plus puissant pour arrêter la production de mélatonine. Même les jours nuageux, l\'intensité lumineuse extérieure est bien supérieure à l\'éclairage intérieur, recalibrant rapidement votre horloge circadienne.';

  @override
  String get missionExplMakeBedTitle =>
      'Pourquoi faire votre lit vous réveille';

  @override
  String get missionExplMakeBedSubtitle =>
      'Commence votre journée par une victoire';

  @override
  String get missionExplMakeBedBody =>
      'Faire votre lit est un micro-accomplissement qui déclenche une petite dose de dopamine. Cela signale à votre cerveau que la journée a commencé et supprime la tentation de vous recoucher. Une tâche accomplie crée l\'élan pour la suivante.';

  @override
  String get missionExplObjectHuntTitle =>
      'Pourquoi la chasse aux objets vous réveille';

  @override
  String get missionExplObjectHuntSubtitle => 'Vous fait sortir du lit';

  @override
  String get missionExplObjectHuntBody =>
      'Chercher un objet spécifique vous force à sortir du lit et à bouger. Votre cerveau passe du repos passif à la résolution active de problèmes — balayant, reconnaissant et se déplaçant. Le temps de le trouver, l\'inertie du sommeil a disparu.';

  @override
  String get missionExplPetHuntTitle =>
      'Pourquoi trouver votre animal vous réveille';

  @override
  String get missionExplPetHuntSubtitle => 'Moment de complicité matinale';

  @override
  String get missionExplPetHuntBody =>
      'Interagir avec votre animal libère de l\'ocytocine — l\'hormone de l\'attachement qui élève naturellement votre humeur et votre vigilance. Se déplacer dans votre maison pour le trouver ajoute de l\'activité physique, tandis que la connexion émotionnelle donne un ancrage positif à votre matin.';

  @override
  String get missionExplNatureHuntTitle =>
      'Pourquoi la chasse nature vous réveille';

  @override
  String get missionExplNatureHuntSubtitle => 'Vous connecte à l\'extérieur';

  @override
  String get missionExplNatureHuntBody =>
      'Sortir pour trouver quelque chose dans la nature combine mouvement, air frais et lumière naturelle — les trois signaux de réveil les plus efficaces. Le changement sensoriel de la chambre à l\'extérieur propulse votre système nerveux en pleine alerte.';

  @override
  String get missionExplTouchGrassTitle =>
      'Pourquoi toucher l\'herbe vous réveille';

  @override
  String get missionExplTouchGrassSubtitle => 'Ancrez-vous dans le matin';

  @override
  String get missionExplTouchGrassBody =>
      'Sortir pour photographier l\'herbe vous expose simultanément au soleil et à l\'air frais. L\'acte de se pencher et de se concentrer sur la nature engage votre corps et vos sens, créant un réveil complet corps-esprit qu\'aucun son d\'alarme ne peut égaler.';

  @override
  String get missionExplAffirmationTitle =>
      'Pourquoi les affirmations vous réveillent';

  @override
  String get missionExplAffirmationSubtitle =>
      'Définit votre état d\'esprit pour la journée';

  @override
  String get missionExplAffirmationBody =>
      'Prononcer une affirmation à voix haute active votre voix, votre souffle et votre concentration simultanément. L\'acte de lire et de répéter engage plusieurs régions du cerveau — vous faisant passer de la somnolence passive à la pensée intentionnelle et consciente.';

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
      'À quelle heure sortez-vous habituellement du lit ?';

  @override
  String get onboardingUsualWakeTimeSubtitle =>
      'Cela nous aide à fixer un premier objectif réaliste.';

  @override
  String get onboardingIdealWakeTimeTitle =>
      'À quelle heure\nvoulez-vous vous lever ?';

  @override
  String get onboardingIdealWakeTimeSubtitle =>
      'Votre heure de réveil idéale quotidienne.';

  @override
  String onboardingTargetWakeTime(String time) {
    return 'Se réveiller à $time est votre objectif.';
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
  String get onboardingSignInCreateTitle => 'Créez votre compte';

  @override
  String get onboardingSignInCreateSubtitle =>
      'Sauvegardez votre progression et synchronisez votre plan.';

  @override
  String get onboardingSignInTitle => 'Ravis de vous revoir';

  @override
  String get onboardingSignInSubtitle =>
      'Connectez-vous pour restaurer votre plan.';

  @override
  String get soundPickerFileTooLarge => 'Fichier trop volumineux (max 10 Mo)';

  @override
  String get soundPickerDeleteTitle => 'Supprimer le son';

  @override
  String soundPickerDeleteContent(String name) {
    return 'Retirer « $name » ?';
  }
}
