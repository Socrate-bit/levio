import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../alarms/services/alarm_channel.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../data/affirmations.dart';
import '../data/bible_verses.dart';
import '../../wakeup/screens/daily_quote_screen.dart';
import '../../missions/models/mission.dart';
import '../../wakeup/screens/wakeup_complete_screen.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/widgets/levio_brand_header.dart';

class SpeechDismissScreen extends StatefulWidget {
  final String alarmId;
  final String nativeAlarmId;
  final MissionType missionType;
  final String alarmLabel;

  const SpeechDismissScreen({
    super.key,
    required this.alarmId,
    required this.nativeAlarmId,
    this.missionType = MissionType.affirmation,
    this.alarmLabel = 'Alarm #1',
  });

  @override
  State<SpeechDismissScreen> createState() => _SpeechDismissScreenState();
}

class _SpeechDismissScreenState extends State<SpeechDismissScreen> {
  static const double _threshold = 0.50;

  final SpeechToText _stt = SpeechToText();
  bool _isListening = false;
  String _transcription = '';
  double? _lastScore;
  bool _initialized = false;
  final _startTime = DateTime.now();
  late final String _targetText;
  String? _missionSnoozeId;
  bool _keepRinging = false;

  static String _randomPhrase(MissionType type) {
    final rng = Random();
    switch (type) {
      case MissionType.bibleVerse:
        return bibleVerses[rng.nextInt(bibleVerses.length)];
      case MissionType.affirmation:
        return affirmations[rng.nextInt(affirmations.length)];
      default:
        final (quote, author) = dailyQuotes[rng.nextInt(dailyQuotes.length)];
        return '"$quote" – $author';
    }
  }

  @override
  void initState() {
    super.initState();
    _targetText = _randomPhrase(widget.missionType);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _initSpeech();
    _initAlarm();
  }

  Future<void> _initAlarm() async {
    final prefs = await SharedPreferences.getInstance();
    _keepRinging = prefs.getBool('keep_alarm_during_mission') ?? false;
    if (!_keepRinging) {
      await AlarmChannel.dismissAlarm(widget.nativeAlarmId);
      _missionSnoozeId = await AlarmChannel.scheduleMissionSnooze(
        nativeAlarmId: widget.nativeAlarmId,
        originalAlarmId: widget.alarmId,
      );
    }
  }

  Future<void> _initSpeech() async {
    final available = await _stt.initialize();
    if (mounted) setState(() => _initialized = available);
  }

  static String _normalize(String text) {
    // Remove attribution: everything from " –" / " —" / " -" followed by a
    // capitalised word (e.g. "– Psalm 23:1" or "— Luke 1:37").
    final withoutAttribution =
        text.replaceAll(RegExp(r'\s[–—-]\s+\S.*$'), '');
    // Strip punctuation (quotes, commas, periods, colons, semi-colons…)
    return withoutAttribution.replaceAll(RegExp(r'[^\w\s]'), '').toLowerCase();
  }

  double _similarity(String spoken, String target) {
    final targetWords =
        _normalize(target).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final spokenWords =
        _normalize(spoken).split(RegExp(r'\s+')).toSet();
    if (targetWords.isEmpty) return 1.0;
    final matches = targetWords.where((w) => spokenWords.contains(w)).length;
    return matches / targetWords.length;
  }

  Future<void> _startListening() async {
    if (!_initialized || _isListening) return;
    setState(() {
      _isListening = true;
      _transcription = '';
      _lastScore = null;
    });
    await _stt.listen(
      onResult: _onResult,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      listenOptions: SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }

  void _onResult(SpeechRecognitionResult result) {
    setState(() => _transcription = result.recognizedWords);
    if (!result.finalResult) return;
    final score = _similarity(result.recognizedWords, _targetText);
    _stt.stop();
    if (score >= _threshold) {
      _dismiss();
    } else {
      setState(() {
        _isListening = false;
        _lastScore = score;
      });
    }
  }

  Future<void> _dismiss() async {
    await AlarmChannel.cancelMissionSnooze(_missionSnoozeId);
    await AlarmChannel.cancelSnoozesForAlarm(widget.alarmId);
    await AlarmChannel.stopRinging();

    final elapsed = DateTime.now().difference(_startTime).inSeconds;
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => WakeupCompleteScreen(
            alarmId: widget.alarmId,
            nativeAlarmId: widget.nativeAlarmId,
            timeTakenSeconds: elapsed,
            missionType: widget.missionType,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _stt.stop();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final score = _lastScore;
    final scoreText =
        score != null ? '${(score * 100).round()}% — try again' : null;
    final info = missionInfoFor(widget.missionType);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            const LevioBrandHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Mission icon
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: info.iconBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(info.icon,
                          color: info.iconColor, size: 30),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Say:',
                      style: TextStyle(
                          fontSize: 16, color: c.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '"$_targetText"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: c.textPrimary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 44),
                    // Mic button
                    GestureDetector(
                      onTap: _isListening ? null : _startListening,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isListening
                              ? AppColors.orange
                              : c.separator,
                        ),
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening
                              ? Colors.white
                              : c.textSecondary,
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isListening ? 'Listening…' : 'Tap to speak',
                      style: TextStyle(
                        fontSize: 14,
                        color: c.textSecondary,
                      ),
                    ),
                    if (_transcription.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        _transcription,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: c.textPrimary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    if (scoreText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          scoreText,
                          style: const TextStyle(
                            color: AppColors.orange,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    if (!_initialized)
                      const Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Text(
                          'Microphone unavailable',
                          style: TextStyle(
                              color: Colors.red, fontSize: 14),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
