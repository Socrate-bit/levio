import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import '../../alarms/services/alarm_channel.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../data/affirmations.dart';
import '../../wakeup/screens/daily_quote_screen.dart';
import '../../missions/models/mission.dart';
import '../../wakeup/screens/wakeup_complete_screen.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../widgets/levio_brand_header.dart';

class SpeechDismissScreen extends StatefulWidget {
  final String alarmId;
  final String nativeAlarmId;
  final MissionType missionType;
  final String alarmLabel;
  final List<String>? selectedAffirmations;
  final int affirmationCount;
  final VoidCallback? onComplete;
  final bool manageAlarm;
  final bool isPreview;

  const SpeechDismissScreen({
    super.key,
    required this.alarmId,
    required this.nativeAlarmId,
    this.missionType = MissionType.affirmation,
    this.alarmLabel = 'Alarm #1',
    this.selectedAffirmations,
    this.affirmationCount = 1,
    this.onComplete,
    this.manageAlarm = true,
    this.isPreview = false,
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
  late String _targetText;
  int _completedCount = 0;
  String? _missionSnoozeId;
  bool _keepRinging = false;

  int get _totalCount => widget.affirmationCount;

  String _randomPhrase() {
    final rng = Random();
    final pool = (widget.selectedAffirmations != null &&
            widget.selectedAffirmations!.isNotEmpty)
        ? widget.selectedAffirmations!
        : affirmations;
    return pool[rng.nextInt(pool.length)];
  }

  @override
  void initState() {
    super.initState();
    _targetText = _randomPhrase();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _initSpeech();
    if (widget.manageAlarm && !widget.isPreview) _initAlarm();
  }

  Future<void> _initAlarm() async {
    final prefs = await SharedPreferences.getInstance();
    _keepRinging = prefs.getBool('keep_alarm_during_mission') ?? false;
    if (!_keepRinging) {
      await Future.delayed(const Duration(seconds: 2));
      await AlarmChannel.dismissAlarm(widget.nativeAlarmId);
      await AlarmChannel.cancelSnoozesForAlarm(widget.alarmId);
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
    final withoutAttribution =
        text.replaceAll(RegExp(r'\s[–—-]\s+\S.*$'), '');
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
      _completedCount++;
      if (_completedCount >= _totalCount) {
        _dismiss();
      } else {
        // Advance to next affirmation
        setState(() {
          _targetText = _randomPhrase();
          _isListening = false;
          _transcription = '';
          _lastScore = null;
        });
      }
    } else {
      setState(() {
        _isListening = false;
        _lastScore = score;
      });
    }
  }

  Future<void> _dismiss() async {
    if (widget.isPreview) {
      if (mounted) Navigator.of(context).pop();
      return;
    }

    if (widget.onComplete != null) {
      widget.onComplete!();
      return;
    }

    if (widget.manageAlarm) {
      await AlarmChannel.cancelMissionSnooze(_missionSnoozeId);
      await AlarmChannel.cancelSnoozesForAlarm(widget.alarmId);
      await AlarmChannel.stopRinging();
    }

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
    final l10n = AppLocalizations.of(context);
    final score = _lastScore;
    final scoreText =
        score != null ? l10n.dismissSpeechTryAgain((score * 100).round()) : null;
    final info = missionInfoFor(widget.missionType);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const LevioBrandHeader(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
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
                        if (_totalCount > 1) ...[
                          Text(
                            l10n.dismissSpeechProgress(
                                _completedCount + 1, _totalCount),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.orange,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          l10n.dismissSpeechSay,
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
                        GestureDetector(
                          onTap: _isListening ? null : withHaptic(_startListening),
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
                          _isListening ? l10n.dismissSpeechListening : l10n.dismissSpeechTapToSpeak,
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
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              l10n.dismissSpeechMicUnavailable,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 14),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (widget.isPreview)
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: withHaptic(() => Navigator.of(context).pop()),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: c.card,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, size: 18, color: c.textPrimary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
