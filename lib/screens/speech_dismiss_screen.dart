import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_alarmkit/flutter_alarmkit.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechDismissScreen extends StatefulWidget {
  final String alarmId;

  const SpeechDismissScreen({super.key, required this.alarmId});

  @override
  State<SpeechDismissScreen> createState() => _SpeechDismissScreenState();
}

class _SpeechDismissScreenState extends State<SpeechDismissScreen> {
  static const String _targetText = 'My name is Lucas';
  static const double _threshold = 0.70;

  final SpeechToText _stt = SpeechToText();
  bool _isListening = false;
  String _transcription = '';
  double? _lastScore;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final available = await _stt.initialize();
    if (mounted) setState(() => _initialized = available);
  }

  double _similarity(String spoken, String target) {
    final targetWords = target.toLowerCase().split(RegExp(r'\s+'));
    final spokenWords = spoken.toLowerCase().split(RegExp(r'\s+'));
    final matches =
        targetWords.where((w) => spokenWords.contains(w)).length;
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
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
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
    await FlutterAlarmkit().stopAlarm(alarmId: widget.alarmId);
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
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
    final score = _lastScore;
    final scorePercent =
        score != null ? '${(score * 100).round()}% — try again' : null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Red alarm banner
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.redAccent.withAlpha(220),
              padding: const EdgeInsets.fromLTRB(16, 52, 16, 12),
              child: const Text(
                'ALARM — Read the phrase aloud to dismiss',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),

          // Main content
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Say:',
                    style: TextStyle(color: Colors.white54, fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '"$_targetText"',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Mic button
                  GestureDetector(
                    onTap: _isListening ? null : _startListening,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isListening
                            ? Colors.redAccent
                            : Colors.white24,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Live transcription
                  if (_transcription.isNotEmpty)
                    Text(
                      _transcription,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                  // Score feedback
                  if (scorePercent != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        scorePercent,
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 16,
                        ),
                      ),
                    ),

                  if (!_initialized)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        'Microphone unavailable',
                        style: TextStyle(color: Colors.redAccent, fontSize: 15),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
