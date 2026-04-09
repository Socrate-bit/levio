import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_alarmkit/flutter_alarmkit.dart';

import '../../../shared/theme/app_theme.dart';
import '../../wakeup/models/wakeup_session.dart';
import '../../wakeup/screens/wakeup_complete_screen.dart';
import '_alarm_banner.dart';

class MathDismissScreen extends StatefulWidget {
  final String alarmId;
  final String alarmLabel;

  const MathDismissScreen({
    super.key,
    required this.alarmId,
    this.alarmLabel = 'Alarm #1',
  });

  @override
  State<MathDismissScreen> createState() => _MathDismissScreenState();
}

class _MathDismissScreenState extends State<MathDismissScreen> {
  static const _totalProblems = 3;

  late int _a;
  late int _b;
  late String _op;
  late int _answer;
  final _ctrl = TextEditingController();
  int _solved = 0;
  String? _errorMsg;
  final _startTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _nextProblem();
  }

  void _nextProblem() {
    final rng = Random();
    final ops = ['+', '-', '×'];
    _op = ops[rng.nextInt(ops.length)];
    switch (_op) {
      case '+':
        _a = rng.nextInt(50) + 10;
        _b = rng.nextInt(50) + 10;
        _answer = _a + _b;
      case '-':
        _a = rng.nextInt(50) + 20;
        _b = rng.nextInt(_a ~/ 2) + 1;
        _answer = _a - _b;
      default: // ×
        _a = rng.nextInt(9) + 2;
        _b = rng.nextInt(9) + 2;
        _answer = _a * _b;
    }
    _ctrl.clear();
    _errorMsg = null;
  }

  void _check() {
    final input = int.tryParse(_ctrl.text.trim());
    if (input == null) return;
    if (input == _answer) {
      HapticFeedback.lightImpact();
      if (_solved + 1 >= _totalProblems) {
        _dismiss();
      } else {
        setState(() {
          _solved++;
          _nextProblem();
        });
      }
    } else {
      HapticFeedback.mediumImpact();
      setState(() => _errorMsg = 'Wrong — try again!');
      _ctrl.clear();
    }
  }

  Future<void> _dismiss() async {
    await FlutterAlarmkit().stopAlarm(alarmId: widget.alarmId);
    final elapsed =
        DateTime.now().difference(_startTime).inSeconds;
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => WakeupCompleteScreen(
            timeTakenSeconds: elapsed,
            session: WakeupSession(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              timestamp: DateTime.now(),
              timeTakenSeconds: elapsed,
            ),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            AlarmBanner(label: widget.alarmLabel),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Progress
                    Text(
                      '${_solved + 1} / $_totalProblems',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _solved / _totalProblems,
                        minHeight: 6,
                        backgroundColor: AppColors.separator,
                        valueColor: const AlwaysStoppedAnimation(AppColors.orange),
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Problem
                    Text(
                      '$_a $_op $_b = ?',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 36),
                    // Input
                    TextField(
                      controller: _ctrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: '?',
                        hintStyle: const TextStyle(
                          fontSize: 32,
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: AppColors.card,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        errorText: _errorMsg,
                      ),
                      onSubmitted: (_) => _check(),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _check,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Confirm',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
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
