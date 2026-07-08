import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import '../../alarms/services/alarm_cascade_controller.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../data/affirmations.dart';
import '../../missions/models/mission.dart';
import '../../missions/widgets/mission_icon.dart';
import '../../subscription/services/analytics_service.dart';
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
  final VoidCallback? onProgress;
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
    this.onProgress,
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
  String? _sttLocaleId;
  final _startTime = DateTime.now();
  late String _targetText;
  bool _targetTextInitialized = false;
  int _completedCount = 0;
  AlarmCascadeController? _cascade;

  int get _totalCount => widget.affirmationCount;

  String _randomPhrase() {
    final rng = Random();
    final pool = (widget.selectedAffirmations != null &&
            widget.selectedAffirmations!.isNotEmpty)
        ? widget.selectedAffirmations!
        : affirmationsFor(context);
    return pool[rng.nextInt(pool.length)];
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _initSpeech();
    if (widget.manageAlarm && !widget.isPreview) {
      _cascade = AlarmCascadeController(alarmId: widget.alarmId)..start();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pick the initial phrase here (not initState) because _randomPhrase reads
    // Localizations.localeOf(context), which requires dependencies to be set.
    if (!_targetTextInitialized) {
      _targetText = _randomPhrase();
      _targetTextInitialized = true;
    }
  }

  Future<void> _initSpeech() async {
    final available = await _stt.initialize();
    if (!available) {
      if (mounted) setState(() => _initialized = false);
      return;
    }
    // Pick an STT locale that matches the app's current locale. Prefer a
    // language+country match (e.g. fr_FR), fall back to any locale whose
    // language matches (fr_*), else let the engine use its default.
    String? localeId;
    try {
      if (mounted) {
        final appCode =
            Localizations.localeOf(context).languageCode.toLowerCase();
        final locales = await _stt.locales();
        LocaleName? match;
        for (final l in locales) {
          final id = l.localeId.replaceAll('-', '_').toLowerCase();
          if (id == appCode || id.startsWith('${appCode}_')) {
            match = l;
            break;
          }
        }
        localeId = match?.localeId;
      }
    } catch (e, st) {
      debugPrint('[SpeechDismissScreen] locale lookup failed: $e');
      AnalyticsService.trackError('SpeechDismissScreen.localeLookup', e, st);
    }
    if (mounted) {
      setState(() {
        _initialized = true;
        _sttLocaleId = localeId;
      });
    }
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
      localeId: _sttLocaleId,
      listenOptions: SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }

  void _onResult(SpeechRecognitionResult result) {
    setState(() => _transcription = result.recognizedWords);
    if (result.recognizedWords.isNotEmpty) {
      widget.onProgress?.call();
      _cascade?.reportProgress();
    }
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

    await _cascade?.finish();

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
    _cascade?.dispose();
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
                    padding: EdgeInsets.symmetric(horizontal: 32.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64.w,
                          height: 64.h,
                          decoration: BoxDecoration(
                            color: info.iconBg,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: MissionIcon(info: info, size: 38.sp),
                          ),
                        ),
                        SizedBox(height: 20.h),
                        if (_totalCount > 1) ...[
                          Text(
                            l10n.dismissSpeechProgress(
                                _completedCount + 1, _totalCount),
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.orange,
                            ),
                          ),
                          SizedBox(height: 8.h),
                        ],
                        Text(
                          l10n.dismissSpeechSay,
                          style: TextStyle(
                              fontSize: 16.sp, color: c.textSecondary),
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          '"$_targetText"',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: c.textPrimary,
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 44.h),
                        GestureDetector(
                          onTap: _isListening ? null : withHaptic(_startListening),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 80.w,
                            height: 80.h,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isListening
                                  ? c.textPrimary
                                  : c.separator,
                            ),
                            child: Icon(
                              _isListening ? Icons.mic : Icons.mic_none,
                              color: _isListening
                                  ? c.background
                                  : c.textSecondary,
                              size: 36.sp,
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          _isListening ? l10n.dismissSpeechListening : l10n.dismissSpeechTapToSpeak,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: c.textSecondary,
                          ),
                        ),
                        if (_transcription.isNotEmpty) ...[
                          SizedBox(height: 20.h),
                          Text(
                            _transcription,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: c.textPrimary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                        if (scoreText != null)
                          Padding(
                            padding: EdgeInsets.only(top: 12.h),
                            child: Text(
                              scoreText,
                              style: TextStyle(
                                color: AppColors.orange,
                                fontSize: 15.sp,
                              ),
                            ),
                          ),
                        if (!_initialized)
                          Padding(
                            padding: EdgeInsets.only(top: 12.h),
                            child: Text(
                              l10n.dismissSpeechMicUnavailable,
                              style: TextStyle(
                                  color: Colors.red, fontSize: 14.sp),
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
                top: 16.h,
                right: 16.w,
                child: GestureDetector(
                  onTap: withHaptic(() => Navigator.of(context).pop()),
                  child: Container(
                    width: 36.w,
                    height: 36.h,
                    decoration: BoxDecoration(
                      color: c.card,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, size: 18.sp, color: c.textPrimary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
