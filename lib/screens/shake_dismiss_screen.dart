import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_alarmkit/flutter_alarmkit.dart';
import 'package:shake/shake.dart';

class ShakeDismissScreen extends StatefulWidget {
  final String alarmId;

  const ShakeDismissScreen({super.key, required this.alarmId});

  @override
  State<ShakeDismissScreen> createState() => _ShakeDismissScreenState();
}

class _ShakeDismissScreenState extends State<ShakeDismissScreen> {
  static const int _target = 10;
  int _shakeCount = 0;
  late final ShakeDetector _detector;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    _detector = ShakeDetector.autoStart(
      shakeThresholdGravity: 2.7,
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
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
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
    final progress = _shakeCount / _target;

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
                'ALARM — Shake your phone 10 times to dismiss',
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

          // Progress ring + count
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      backgroundColor: Colors.white12,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.redAccent,
                      ),
                    ),
                  ),
                  Text(
                    '$_shakeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 80,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Label below ring
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Text(
              'of $_target shakes',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
