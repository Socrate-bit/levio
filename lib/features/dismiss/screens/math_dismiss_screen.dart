import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import '../../alarms/services/alarm_cascade_controller.dart';

import '../../../shared/theme/app_theme.dart';
import '../widgets/levio_brand_header.dart';
import '../../alarms/cubit/alarm_state.dart';
import '../../wakeup/screens/wakeup_complete_screen.dart';

class MathDismissScreen extends StatefulWidget {
  final String alarmId;
  final String nativeAlarmId;
  final String alarmLabel;
  final MathDifficulty difficulty;
  final int problemCount;
  final VoidCallback? onComplete;
  final VoidCallback? onProgress;
  final bool manageAlarm;
  final bool isPreview;

  const MathDismissScreen({
    super.key,
    required this.alarmId,
    required this.nativeAlarmId,
    this.alarmLabel = 'Alarm #1',
    this.difficulty = MathDifficulty.easy,
    this.problemCount = 3,
    this.onComplete,
    this.onProgress,
    this.manageAlarm = true,
    this.isPreview = false,
  });

  @override
  State<MathDismissScreen> createState() => _MathDismissScreenState();
}

class _MathDismissScreenState extends State<MathDismissScreen> {
  late int _a;
  late int _b;
  late String _op;
  late int _answer;
  late String _problemText;
  final _ctrl = TextEditingController();
  int _solved = 0;
  bool _showError = false;
  final _startTime = DateTime.now();
  AlarmCascadeController? _cascade;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _nextProblem();
    if (widget.manageAlarm && !widget.isPreview) {
      _cascade = AlarmCascadeController(alarmId: widget.alarmId)..start();
    }
  }

  void _nextProblem() {
    final rng = Random();
    final diff = widget.difficulty;

    final maxVal = switch (diff) {
      MathDifficulty.easy => 25,
      MathDifficulty.medium => 50,
      MathDifficulty.hard => 50,
    };
    final ops = switch (diff) {
      MathDifficulty.easy => ['+', '-'],
      MathDifficulty.medium => ['+', '-', '\u00d7'],
      MathDifficulty.hard => ['+', '-', '\u00d7', '\u00f7'],
    };

    // Hard mode: always use chained 3-operand problems
    if (diff == MathDifficulty.hard) {
      final opA = ops[rng.nextInt(ops.length)];
      final opB = ops[rng.nextInt(ops.length)];

      int x, y, z, mid;

      // Build x, y, mid so division is always exact
      switch (opA) {
        case '+':
          x = rng.nextInt(maxVal) + 5;
          y = rng.nextInt(maxVal) + 5;
          mid = x + y;
        case '-':
          x = rng.nextInt(maxVal) + 5;
          y = rng.nextInt(x - 1) + 4;
          mid = x - y;
        case '\u00d7':
          x = rng.nextInt(maxVal ~/ 5) + 2;
          y = rng.nextInt(maxVal ~/ 5) + 2;
          mid = x * y;
        default: // ÷
          y = rng.nextInt(maxVal ~/ 5) + 2;
          mid = rng.nextInt(maxVal ~/ 5) + 1;
          x = y * mid;
      }

      // Build z, answer so division is always exact
      switch (opB) {
        case '+':
          z = rng.nextInt(maxVal) + 5;
          _answer = mid + z;
        case '-':
          z = rng.nextInt(maxVal) + 5;
          _answer = mid - z;
        case '\u00d7':
          z = rng.nextInt(maxVal ~/ 5) + 2;
          _answer = mid * z;
        default: // ÷
          final absMid = mid.abs();
          if (absMid < 2) {
            z = 1;
          } else {
            final factors = [for (var i = 2; i <= absMid; i++) if (absMid % i == 0) i];
            z = factors[rng.nextInt(factors.length)];
          }
          _answer = mid ~/ z;
      }

      _a = x;
      _b = y;
      _op = opA;
      _problemText = '($x $opA $y) $opB $z = ?';
      _ctrl.clear();
      _showError = false;
      return;
    }

    _op = ops[rng.nextInt(ops.length)];
    switch (_op) {
      case '+':
        _a = rng.nextInt(maxVal) + 5;
        _b = rng.nextInt(maxVal) + 5;
        _answer = _a + _b;
      case '-':
        _a = rng.nextInt(maxVal) + 5;
        _b = rng.nextInt(_a) + 5;
        _answer = _a - _b;
      case '\u00f7':
        // Division: pick answer and divisor, compute dividend
        _b = rng.nextInt(maxVal ~/ 5) + 2;
        _answer = rng.nextInt(maxVal ~/ 5) + 1;
        _a = _b * _answer;
      default: // ×
        _a = rng.nextInt(maxVal ~/ 5) + 2;
        _b = rng.nextInt(maxVal ~/ 5) + 2;
        _answer = _a * _b;
    }
    _problemText = '$_a $_op $_b = ?';
    _ctrl.clear();
    _showError = false;
  }

  void _check() {
    final input = int.tryParse(_ctrl.text.trim());
    if (input == null) return;
    widget.onProgress?.call();
    _cascade?.reportProgress();
    if (input == _answer) {
      HapticFeedback.lightImpact();
      if (_solved + 1 >= widget.problemCount) {
        _dismiss();
      } else {
        setState(() {
          _solved++;
          _nextProblem();
        });
      }
    } else {
      HapticFeedback.mediumImpact();
      setState(() => _showError = true);
      _ctrl.clear();
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
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _cascade?.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
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
                    padding: EdgeInsets.symmetric(horizontal: 40.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Progress
                        Text(
                          l10n.dismissMathProgress(_solved + 1, widget.problemCount),
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: c.textSecondary,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4.r),
                          child: LinearProgressIndicator(
                            value: _solved / widget.problemCount,
                            minHeight: 6.h,
                            backgroundColor: c.separator,
                            valueColor: const AlwaysStoppedAnimation(AppColors.orange),
                          ),
                        ),
                        SizedBox(height: 48.h),
                        // Problem
                        Text(
                          _problemText,
                          style: TextStyle(
                            fontSize: 48.sp,
                            fontWeight: FontWeight.bold,
                            color: c.textPrimary,
                            letterSpacing: -1,
                          ),
                        ),
                        SizedBox(height: 36.h),
                        // Input
                        TextField(
                          controller: _ctrl,
                          keyboardType: const TextInputType.numberWithOptions(signed: true),
                          textAlign: TextAlign.center,
                          autofocus: true,
                          style: TextStyle(
                            fontSize: 32.sp,
                            fontWeight: FontWeight.bold,
                            color: c.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: '?',
                            hintStyle: TextStyle(
                              fontSize: 32.sp,
                              color: c.textSecondary,
                            ),
                            filled: true,
                            fillColor: c.card,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14.r),
                              borderSide: BorderSide.none,
                            ),
                            errorText: _showError ? l10n.dismissMathWrong : null,
                          ),
                          onSubmitted: (_) => _check(),
                        ),
                        SizedBox(height: 24.h),
                        ElevatedButton(
                          onPressed: _check,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: c.textPrimary,
                            foregroundColor: Colors.white,
                            minimumSize: Size(double.infinity, 54.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            l10n.dismissMathConfirm,
                            style: TextStyle(
                              fontSize: 16.sp,
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
            if (widget.isPreview)
              Positioned(
                top: 16.h,
                right: 16.w,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
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
