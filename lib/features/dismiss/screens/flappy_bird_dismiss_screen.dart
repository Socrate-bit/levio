import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../alarms/services/alarm_cascade_controller.dart';
import '../../missions/models/mission.dart';
import '../../wakeup/screens/wakeup_complete_screen.dart';
import '../../../shared/theme/app_theme.dart';
import '../games/flappybird_game.dart';
import '../widgets/levio_brand_header.dart';

/// Alarm-dismiss mission that runs the Flappy Bird mini-game. The alarm is
/// dismissed once the player reaches [targetScore].
class FlappyBirdDismissScreen extends StatefulWidget {
  final String alarmId;
  final String nativeAlarmId;
  final String alarmLabel;
  final int targetScore;
  final VoidCallback? onComplete;
  final VoidCallback? onProgress;
  final bool manageAlarm;
  final bool isPreview;

  const FlappyBirdDismissScreen({
    super.key,
    required this.alarmId,
    required this.nativeAlarmId,
    this.alarmLabel = 'Alarm #1',
    this.targetScore = 3,
    this.onComplete,
    this.onProgress,
    this.manageAlarm = true,
    this.isPreview = false,
  });

  @override
  State<FlappyBirdDismissScreen> createState() =>
      _FlappyBirdDismissScreenState();
}

class _FlappyBirdDismissScreenState extends State<FlappyBirdDismissScreen> {
  final _scoreNotifier = ValueNotifier<int>(0);
  final _startTime = DateTime.now();
  late final FlappyBirdGame _game;
  AlarmCascadeController? _cascade;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    if (widget.manageAlarm && !widget.isPreview) {
      _cascade = AlarmCascadeController(alarmId: widget.alarmId)..start();
    }
    _game = FlappyBirdGame(
      targetScore: widget.targetScore,
      scoreNotifier: _scoreNotifier,
      onPoint: () {
        widget.onProgress?.call();
        _cascade?.reportProgress();
      },
      onWin: _dismiss,
    );
  }

  Future<void> _dismiss() async {
    if (_completed) return;
    _completed = true;

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
            missionType: MissionType.flappyBird,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _scoreNotifier.dispose();
    _cascade?.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Stack(
          children: [
            // The game fills the screen; tapping anywhere flaps the bird.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _game.flap,
                child: GameWidget(game: _game),
              ),
            ),
            Column(
              children: [
                const LevioBrandHeader(),
                SizedBox(height: 8.h),
                // Live score / target overlay.
                ValueListenableBuilder<int>(
                  valueListenable: _scoreNotifier,
                  builder: (context, score, _) => Text(
                    '$score / ${widget.targetScore}',
                    style: TextStyle(
                      fontSize: 40.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 6),
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
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, size: 18.sp, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
