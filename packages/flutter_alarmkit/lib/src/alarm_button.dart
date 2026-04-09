/// Represents a button displayed in an alarm alert or notification banner.
///
/// Used to configure the appearance of the stop button and secondary button
/// in AlarmKit alarm presentations.
class AlarmButton {
  /// The label text displayed on the button.
  final String text;

  /// The color of the button text as a hex string (e.g., `"#FFFFFF"`).
  final String textColor;

  /// The SF Symbols name for the icon displayed on the button
  /// (e.g., `"stop.circle"`, `"repeat.circle"`, `"pause.circle"`).
  final String systemImageName;

  const AlarmButton({
    required this.text,
    required this.textColor,
    required this.systemImageName,
  });

  Map<String, dynamic> toMap() => {
    'text': text,
    'textColor': textColor,
    'systemImageName': systemImageName,
  };
}
