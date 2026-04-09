class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String quote;
  final BadgeKind kind;

  // For streak badges: required days
  final int? requiredDays;

  // For achievement badges: display number on hex
  final String displayValue;

  bool earned;
  DateTime? earnedDate;

  BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.quote,
    required this.kind,
    this.requiredDays,
    this.displayValue = '?',
    this.earned = false,
    this.earnedDate,
  });

  BadgeModel copyWith({bool? earned, DateTime? earnedDate}) => BadgeModel(
        id: id,
        name: name,
        description: description,
        quote: quote,
        kind: kind,
        requiredDays: requiredDays,
        displayValue: displayValue,
        earned: earned ?? this.earned,
        earnedDate: earnedDate ?? this.earnedDate,
      );
}

enum BadgeKind { streak, achievement }

List<BadgeModel> buildStreakBadges() => [
      BadgeModel(
        id: 'risen',
        name: 'Risen',
        description: '1 day',
        quote: 'The journey of a thousand mornings begins with one alarm.',
        kind: BadgeKind.streak,
        requiredDays: 1,
        displayValue: '1',
      ),
      BadgeModel(
        id: 'ignite',
        name: 'Ignite',
        description: '3 days',
        quote: 'Three days in. The flame is growing.',
        kind: BadgeKind.streak,
        requiredDays: 3,
        displayValue: '3',
      ),
      BadgeModel(
        id: 'horizon',
        name: 'Horizon',
        description: '7 days',
        quote: 'A week of mornings — you\'re rewriting your story.',
        kind: BadgeKind.streak,
        requiredDays: 7,
        displayValue: '7',
      ),
      BadgeModel(
        id: 'aurora',
        name: 'Aurora',
        description: '14 days',
        quote: 'Two weeks of sunrise. Keep chasing the light.',
        kind: BadgeKind.streak,
        requiredDays: 14,
        displayValue: '14',
      ),
      BadgeModel(
        id: 'celestial',
        name: 'Celestial',
        description: '30 days',
        quote: 'A full month of rising. You are unstoppable.',
        kind: BadgeKind.streak,
        requiredDays: 30,
        displayValue: '30',
      ),
      BadgeModel(
        id: 'nebula',
        name: 'Nebula',
        description: '100 days',
        quote: 'One hundred mornings. A new you has been born.',
        kind: BadgeKind.streak,
        requiredDays: 100,
        displayValue: '100',
      ),
      BadgeModel(
        id: 'eternal',
        name: 'Eternal',
        description: '365 days',
        quote: 'A full year of mornings. You are legendary.',
        kind: BadgeKind.streak,
        requiredDays: 365,
        displayValue: '365',
      ),
    ];

List<BadgeModel> buildAchievementBadges() => [
      BadgeModel(
        id: 'versatile',
        name: 'Versatile',
        description: 'Complete every mission type',
        quote: 'Mastery comes from variety.',
        kind: BadgeKind.achievement,
        displayValue: '?',
      ),
      BadgeModel(
        id: 'first_light',
        name: 'First Light',
        description: 'Wake up before 5:30 AM',
        quote: 'The early bird catches the sunrise.',
        kind: BadgeKind.achievement,
        displayValue: '?',
      ),
      BadgeModel(
        id: 'blitz',
        name: 'Blitz',
        description: 'Turn off alarm in under 15s',
        quote: 'Speed of light. Speed of life.',
        kind: BadgeKind.achievement,
        displayValue: '?',
      ),
      BadgeModel(
        id: 'no_days_off',
        name: 'No Days Off',
        description: 'Complete missions on Sat & Sun',
        quote: 'Weekends are just weekdays in disguise.',
        kind: BadgeKind.achievement,
        displayValue: '?',
      ),
      BadgeModel(
        id: 'converted',
        name: 'Converted',
        description: '7-day streak as a former night owl',
        quote: 'Even night owls can learn to love the dawn.',
        kind: BadgeKind.achievement,
        displayValue: '?',
      ),
      BadgeModel(
        id: 'audiophile',
        name: 'Audiophile',
        description: 'Use 4+ different alarm sounds',
        quote: 'Every morning deserves its own soundtrack.',
        kind: BadgeKind.achievement,
        displayValue: '?',
      ),
    ];
