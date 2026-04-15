import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../alarms/services/alarm_channel.dart';

import '../../../shared/theme/app_theme.dart';
import '../../alarms/cubit/alarm_state.dart';
import '../../wakeup/screens/wakeup_complete_screen.dart';

class MathDismissScreen extends StatefulWidget {
  final String alarmId;
  final String nativeAlarmId;
  final String alarmLabel;
  final MathDifficulty difficulty;

  const MathDismissScreen({
    super.key,
    required this.alarmId,
    required this.nativeAlarmId,
    this.alarmLabel = 'Alarm #1',
    this.difficulty = MathDifficulty.easy,
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
  late String _problemText;
  final _ctrl = TextEditingController();
  int _solved = 0;
  String? _errorMsg;
  final _startTime = DateTime.now();
  String? _missionSnoozeId;
  bool _keepRinging = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _nextProblem();
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

  void _nextProblem() {
    final rng = Random();
    final diff = widget.difficulty;

    final maxVal = switch (diff) {
      MathDifficulty.easy => 10,
      MathDifficulty.medium => 25,
      MathDifficulty.hard => 50,
    };
    final ops = switch (diff) {
      MathDifficulty.easy => ['+', '-'],
      MathDifficulty.medium => ['+', '-', '×'],
      MathDifficulty.hard => ['+', '-', '×'],
    };

    // Hard mode: 50% chance of chained 3-operand problem
    if (diff == MathDifficulty.hard && rng.nextBool()) {
      final opA = ops[rng.nextInt(ops.length)];
      final opB = ops[rng.nextInt(ops.length)];
      final x = rng.nextInt(maxVal) + 1;
      final y = rng.nextInt(maxVal) + 1;
      final z = rng.nextInt(maxVal) + 1;
      int mid;
      switch (opA) {
        case '+': mid = x + y;
        case '-': mid = x - y;
        default: mid = x * y;
      }
      switch (opB) {
        case '+': _answer = mid + z;
        case '-': _answer = mid - z;
        default: _answer = mid * z;
      }
      _a = x;
      _b = y;
      _op = opA;
      _problemText = '($x $opA $y) $opB $z = ?';
      _ctrl.clear();
      _errorMsg = null;
      return;
    }

    _op = ops[rng.nextInt(ops.length)];
    switch (_op) {
      case '+':
        _a = rng.nextInt(maxVal) + 1;
        _b = rng.nextInt(maxVal) + 1;
        _answer = _a + _b;
      case '-':
        _a = rng.nextInt(maxVal) + 1;
        _b = rng.nextInt(_a) + 1;
        _answer = _a - _b;
      default: // ×
        _a = rng.nextInt(maxVal ~/ 2) + 2;
        _b = rng.nextInt(maxVal ~/ 2) + 2;
        _answer = _a * _b;
    }
    _problemText = '$_a $_op $_b = ?';
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
    await AlarmChannel.cancelMissionSnooze(_missionSnoozeId);
    await AlarmChannel.cleanupConfig(widget.nativeAlarmId);
    await AlarmChannel.stopRinging();

    final elapsed =
        DateTime.now().difference(_startTime).inSeconds;
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => WakeupCompleteScreen(
            alarmId: widget.alarmId,
            nativeAlarmId: widget.nativeAlarmId,
            timeTakenSeconds: elapsed,
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
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Progress
                    Text(
                      '${_solved + 1} / $_totalProblems',
                      style: TextStyle(
                        fontSize: 14,
                        color: c.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _solved / _totalProblems,
                        minHeight: 6,
                        backgroundColor: c.separator,
                        valueColor: const AlwaysStoppedAnimation(AppColors.orange),
                      ),
                    ),
                    const SizedBox(height: 48),
                    // Problem
                    Text(
                      _problemText,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: c.textPrimary,
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
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: c.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: '?',
                        hintStyle: TextStyle(
                          fontSize: 32,
                          color: c.textSecondary,
                        ),
                        filled: true,
                        fillColor: c.card,
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
