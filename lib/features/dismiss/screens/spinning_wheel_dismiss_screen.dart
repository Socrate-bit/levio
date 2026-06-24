import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';

import '../../../shared/theme/app_theme.dart';
import '../../alarms/services/alarm_cascade_controller.dart';
import '../../settings/cubit/settings_cubit.dart';
import '../../settings/cubit/settings_state.dart';
import '../../wakeup/services/history_service.dart';
import '../widgets/levio_brand_header.dart';

/// Haptic tick divisions per revolution — controls how many clicks are felt while spinning.
const int _kSlots = 100;


/// "Spin to Win" mission: flick the wheel and it lands on the ✈️ Travel slot,
/// celebrates, and dismisses the alarm. A single flick is all it takes — the
/// landing is rigged to the travel slot so the alarm is always dismissible.
class SpinningWheelDismissScreen extends StatefulWidget {
  final String alarmId;
  final String nativeAlarmId;
  final String alarmLabel;
  final VoidCallback? onComplete;
  final VoidCallback? onProgress;
  final bool manageAlarm;
  final bool isPreview;
  final bool showCloseButton;

  const SpinningWheelDismissScreen({
    super.key,
    required this.alarmId,
    required this.nativeAlarmId,
    this.alarmLabel = 'Alarm #1',
    this.onComplete,
    this.onProgress,
    this.manageAlarm = true,
    this.isPreview = false,
    this.showCloseButton = false,
  });

  @override
  State<SpinningWheelDismissScreen> createState() =>
      _SpinningWheelDismissScreenState();
}

class _SpinningWheelDismissScreenState extends State<SpinningWheelDismissScreen>
    with SingleTickerProviderStateMixin {
  static const double _sweep = 2 * pi / _kSlots;

  final _wheelKey = GlobalKey();
  final _confetti = ConfettiController(
    duration: const Duration(milliseconds: 600),
  );
  final _rng = Random();

  late final AnimationController _spinController;
  Animation<double>? _spinAnim;
  AlarmCascadeController? _cascade;

  double _rotation = 0;
  double? _lastDragAngle;
  int? _lastTickIndex;
  bool _hasSpun = false;
  bool _won = false;
  bool _flickHarder = false;
  bool _spunAndMissed = false;
  bool _alreadyUsed = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _spinController = AnimationController(vsync: this)
      ..addListener(_onSpinTick)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) _onSpinComplete();
      });
    if (widget.manageAlarm && !widget.isPreview) {
      _cascade = AlarmCascadeController(alarmId: widget.alarmId)..start();
    }
    if (!widget.isPreview) _checkAlreadyUsed();
  }

  Future<void> _checkAlreadyUsed() async {
    final used = await HistoryService.hasSpinToWinUsedToday();
    if (mounted) setState(() => _alreadyUsed = used);
  }

  // Returns the touch angle around the wheel centre, or null if not laid out.
  double? _angleTo(Offset globalPosition) {
    final box = _wheelKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final center = box.localToGlobal(box.size.center(Offset.zero));
    final v = globalPosition - center;
    return atan2(v.dy, v.dx);
  }

  void _onPanStart(DragStartDetails d) {
    if (_hasSpun || _alreadyUsed) return;
    _lastDragAngle = _angleTo(d.globalPosition);
  }

  // Let the wheel follow the finger while dragging so the flick feels physical.
  void _onPanUpdate(DragUpdateDetails d) {
    if (_hasSpun || _lastDragAngle == null) return;
    final angle = _angleTo(d.globalPosition);
    if (angle == null) return;
    var delta = angle - _lastDragAngle!;
    if (delta > pi) delta -= 2 * pi;
    if (delta < -pi) delta += 2 * pi;
    _lastDragAngle = angle;
    setState(() => _rotation += delta);
    _emitTickIfCrossedSlot();
  }

  void _onPanEnd(DragEndDetails d) {
    if (_hasSpun || _alreadyUsed) return;
    _lastDragAngle = null;
    final speed = d.velocity.pixelsPerSecond.distance;
    // Too weak to spin — nudge the user to flick harder, keep the spin available.
    if (speed < 600) {
      HapticFeedback.lightImpact();
      setState(() => _flickHarder = true);
      return;
    }
    _launchSpin(speed);
  }

  // Animate the wheel with physics-based spin; landing angle depends on spin mode.
  void _launchSpin(double speed) {
    _hasSpun = true;
    setState(() => _flickHarder = false);
    // Mark this trial as used immediately — one spin per day regardless of result.
    HistoryService.markSpinToWinUsed(widget.alarmId);

    final turns = (3 + speed / 900).clamp(3.0, 7.0).round();
    final start = _rotation;
    final fullTurns = (start / (2 * pi)).ceil() + turns;
    final spinMode = context.read<SettingsCubit>().state.spinMode;
    final target = switch (spinMode) {
      SpinMode.alwaysWin =>
        // Land within the winning slot (jitter stays inside half-sweep).
        fullTurns * 2 * pi + (_rng.nextDouble() - 0.5) * _sweep * 0.7,
      SpinMode.neverWin =>
        // Land anywhere outside the winning slot.
        fullTurns * 2 * pi + _sweep / 2 + _rng.nextDouble() * (2 * pi - _sweep),
      SpinMode.normal =>
        fullTurns * 2 * pi + _rng.nextDouble() * 2 * pi,
    };

    _spinAnim = Tween<double>(begin: start, end: target).animate(
      CurvedAnimation(parent: _spinController, curve: Curves.easeOutCubic),
    );
    _spinController.duration = Duration(
      milliseconds: (2600 + turns * 200).round(),
    );
    _spinController.forward(from: 0);
  }

  void _onSpinTick() {
    final value = _spinAnim?.value;
    if (value == null) return;
    setState(() => _rotation = value);
    _emitTickIfCrossedSlot();
  }

  // Ratchet haptic + progress report each time a slot boundary passes the pointer.
  void _emitTickIfCrossedSlot() {
    final index = (_rotation / _sweep).floor();
    if (_lastTickIndex == null) {
      _lastTickIndex = index;
      return;
    }
    if (index != _lastTickIndex) {
      _lastTickIndex = index;
      HapticFeedback.selectionClick();
      widget.onProgress?.call();
      _cascade?.reportProgress();
    }
  }

  void _onSpinComplete() {
    HapticFeedback.heavyImpact();

    // Win if the wheel stopped within the travel slot (slot 0, centred at 0 mod 2π).
    final normalized = _rotation % (2 * pi);
    final halfSweep = _sweep / 2;
    final landed = normalized < halfSweep || normalized > (2 * pi - halfSweep);

    if (landed) {
      _confetti.play();
      setState(() => _won = true);
      // No auto-close — user exits via the ✕ button.
    } else {
      // One trial only — wheel stays, user closes via ✕.
      setState(() => _spunAndMissed = true);
    }
  }


  @override
  void dispose() {
    _spinController.dispose();
    _confetti.dispose();
    _cascade?.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    final wheelSize = 400.w;
    final wheelSizeD = 310.w;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const LevioBrandHeader(),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(
                          '🏝️',
                          style: TextStyle(fontSize: 36.sp),
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          l10n.dismissSpinningWheelTitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            color: c.textPrimary,
                          ),
                        ),
                        SizedBox(height: 80.h),
                        // Wheel + fixed overlay + spin gesture
                        GestureDetector(
                          onPanStart: _onPanStart,
                          onPanUpdate: _onPanUpdate,
                          onPanEnd: _onPanEnd,
                          child: SizedBox(
                            key: _wheelKey,
                            width: wheelSize,
                            height: wheelSize,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Spinning disc image on top
                                Transform.translate(
                                  offset: Offset(0, -17.h),
                                  child: Transform.rotate(
                                    angle: _rotation,
                                    child: Image.asset(
                                      'assets/wheel_moving.png',
                                      width: wheelSizeD,
                                      height: wheelSizeD,
                                    ),
                                  ),
                                ),
                                // Fixed frame / background image
                                Image.asset(
                                  'assets/wheel_static.png',
                                  width: wheelSize,
                                  height: wheelSize,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 32.h),
                        Text(
                          _alreadyUsed
                              ? l10n.dismissSpinningWheelAlreadyUsed
                              : _won
                                  ? l10n.dismissSpinningWheelWin
                                  : _spunAndMissed
                                      ? l10n.dismissSpinningWheelMissed
                                      : _flickHarder
                                          ? l10n.dismissSpinningWheelFlickHarder
                                          : l10n.dismissSpinningWheelPrompt,
                          maxLines: 3,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: _won ? FontWeight.bold : FontWeight.w400,
                            color: _won ? AppColors.orange : c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Win confetti from the top
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirection: pi / 2,
                blastDirectionality: BlastDirectionality.explosive,
                emissionFrequency: 0.9,
                numberOfParticles: 18,
                maxBlastForce: 50,
                minBlastForce: 30,
                gravity: 0.45,
                shouldLoop: false,
                colors: const [
                  AppColors.orange,
                  Colors.amber,
                  Colors.greenAccent,
                  Colors.lightBlueAccent,
                  Colors.pinkAccent,
                ],
              ),
            ),
            // Close button (preview or post-success bonus)
            if (widget.isPreview || widget.showCloseButton)
              Positioned(
                top: 16.h,
                right: 16.w,
                child: GestureDetector(
                  onTap: () => widget.isPreview
                      ? Navigator.of(context).pop()
                      : Navigator.of(context).popUntil((r) => r.isFirst),
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
