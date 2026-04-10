import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_alarmkit/flutter_alarmkit.dart';
import 'package:shake/shake.dart';

import '../../missions/models/mission.dart';
import '../../wakeup/screens/wakeup_complete_screen.dart';
import '../../../shared/theme/app_theme.dart';

class ShakeDismissScreen extends StatefulWidget {
  final String alarmId;
  final String alarmLabel;

  const ShakeDismissScreen({
    super.key,
    required this.alarmId,
    this.alarmLabel = 'Alarm #1',
  });

  @override
  State<ShakeDismissScreen> createState() => _ShakeDismissScreenState();
}

class _ShakeDismissScreenState extends State<ShakeDismissScreen> {
  static const int _target = 30;
  int _shakeCount = 0;
  late final ShakeDetector _detector;
  final _startTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _detector = ShakeDetector.autoStart(
      shakeThresholdGravity: 1.5,
      shakeSlopTimeMS: 500,
      minimumShakeCount: 1,
      onPhoneShake: (_) => _onShake(),
    );
  }

  void _onShake() {
    if (_shakeCount >= _target) return;
    HapticFeedback.mediumImpact();
    setState(() => _shakeCount++);
    if (_shakeCount >= _target) {
      _dismiss();
    }
  }

  Future<void> _dismiss() async {
    _detector.stopListening();
    await FlutterAlarmkit().stopAlarm(alarmId: widget.alarmId);
    final elapsed = DateTime.now().difference(_startTime).inSeconds;
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => WakeupCompleteScreen(
            alarmId: widget.alarmId,
            timeTakenSeconds: elapsed,
            missionType: MissionType.shakePhone,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _detector.stopListening();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final progress = _shakeCount / _target;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 220,
                      height: 220,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.expand(
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 12,
                              backgroundColor: c.separator,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.orange,
                              ),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment:
                                    CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '$_shakeCount',
                                    style: TextStyle(
                                      color: c.textPrimary,
                                      fontSize: 64,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '/ $_target',
                                    style: TextStyle(
                                      color: c.textSecondary,
                                      fontSize: 22,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Shake your phone to stop the alarm',
                      style: TextStyle(
                        fontSize: 18,
                        color: c.textSecondary,
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
