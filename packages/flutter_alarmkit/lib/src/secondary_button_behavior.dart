/// Controls what happens when the secondary button of an alarm alert is tapped.
///
/// Use [AlarmSecondaryButtonBehavior.countdown] to start or resume the
/// countdown, [AlarmSecondaryButtonBehavior.stop] to stop the alarm, or
/// [AlarmSecondaryButtonBehavior.snooze] to snooze for a given duration.
class AlarmSecondaryButtonBehavior {
  final String _type;
  final int? _snoozeDurationInSeconds;

  const AlarmSecondaryButtonBehavior._({
    required String type,
    int? snoozeDurationInSeconds,
  }) : _type = type,
       _snoozeDurationInSeconds = snoozeDurationInSeconds;

  /// Starts or resumes the alarm countdown when the secondary button is tapped.
  static const countdown = AlarmSecondaryButtonBehavior._(type: 'countdown');

  /// Stops the alarm when the secondary button is tapped.
  static const stop = AlarmSecondaryButtonBehavior._(type: 'stop');

  /// Snoozes the alarm for [durationInSeconds] when the secondary button is
  /// tapped.
  static AlarmSecondaryButtonBehavior snooze(int durationInSeconds) =>
      AlarmSecondaryButtonBehavior._(
        type: 'snooze',
        snoozeDurationInSeconds: durationInSeconds,
      );

  Map<String, dynamic> toMap() => {
    'type': _type,
    if (_snoozeDurationInSeconds != null)
      'durationInSeconds': _snoozeDurationInSeconds,
  };
}
