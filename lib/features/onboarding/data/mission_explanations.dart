import '../../missions/models/mission.dart';

const missionExplanations = <MissionType, Map<String, String>>{
  MissionType.pushUps: {
    'title': 'Why doing push ups wakes you up',
    'subtitle': 'Gets your blood pumping right away',
    'body':
        'Short bursts of effort spike cortisol and adrenaline, raising heart rate and body temperature so you feel awake fast.',
  },
  MissionType.squats: {
    'title': 'Why doing squats wakes you up',
    'subtitle': 'Activates your largest muscles',
    'body':
        'Squats engage your glutes and quads, driving blood flow to your brain and clearing morning fog in seconds.',
  },
  MissionType.shakePhone: {
    'title': 'Why shaking your phone wakes you up',
    'subtitle': 'Forces you to move',
    'body':
        'The physical act of shaking gets your arms moving and your brain engaged, making it impossible to drift back to sleep.',
  },
  MissionType.math: {
    'title': 'Why solving math wakes you up',
    'subtitle': 'Wakes up your brain',
    'body':
        'Solving problems forces your prefrontal cortex online, cutting through sleep inertia with pure cognitive effort.',
  },
  MissionType.skyPhoto: {
    'title': 'Why taking a sky photo wakes you up',
    'subtitle': 'Gets you to the window',
    'body':
        'Walking to see the sky exposes you to natural light, the most powerful signal to your circadian clock that it\'s time to wake.',
  },
  MissionType.makeBed: {
    'title': 'Why making your bed wakes you up',
    'subtitle': 'Starts your day with a win',
    'body':
        'Completing one small task creates momentum. A made bed means you\'ve already accomplished something before your day begins.',
  },
  MissionType.objectHunt: {
    'title': 'Why an object hunt wakes you up',
    'subtitle': 'Gets you out of bed',
    'body':
        'Searching for an object forces you to stand, walk, and engage your surroundings — the ultimate anti-snooze strategy.',
  },
  MissionType.petHunt: {
    'title': 'Why finding your pet wakes you up',
    'subtitle': 'Morning bonding time',
    'body':
        'Finding your pet gets you moving and starts your day with a moment of connection and joy.',
  },
  MissionType.natureHunt: {
    'title': 'Why a nature hunt wakes you up',
    'subtitle': 'Connects you to the outdoors',
    'body':
        'Stepping outside to photograph nature floods your senses with fresh air and light, resetting your internal clock.',
  },
  MissionType.touchGrass: {
    'title': 'Why touching grass wakes you up',
    'subtitle': 'Ground yourself in the morning',
    'body':
        'Going outside to touch grass exposes you to sunlight and fresh air, two of the strongest wake-up signals for your body.',
  },
  MissionType.bibleVerse: {
    'title': 'Why reading a verse wakes you up',
    'subtitle': 'Starts your day with purpose',
    'body':
        'Speaking a verse aloud engages your voice, mind, and spirit, anchoring your morning in meaning.',
  },
  MissionType.affirmation: {
    'title': 'Why affirmations wake you up',
    'subtitle': 'Sets your mindset for the day',
    'body':
        'Reading affirmations aloud activates your voice and focus, replacing grogginess with intention and clarity.',
  },
};
