import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';

import '../../../shared/theme/app_theme.dart';
import '../../alarms/services/alarm_cascade_controller.dart';
import '../../missions/models/mission.dart';
import '../../wakeup/screens/wakeup_complete_screen.dart';
import '../widgets/levio_brand_header.dart';

/// Number of slots on the prize wheel.
const int _kSlots = 8;

/// The single winning slot. Slot 0 is centred at the top pointer when the
/// wheel rotation is a multiple of 2π, so aligning the travel slot means
/// landing on a rotation ≡ 0 (mod 2π).
const int _kWinningSlot = 0;

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

  const SpinningWheelDismissScreen({
    super.key,
    required this.alarmId,
    required this.nativeAlarmId,
    this.alarmLabel = 'Alarm #1',
    this.onComplete,
    this.onProgress,
    this.manageAlarm = true,
    this.isPreview = false,
  });

  @override
  State<SpinningWheelDismissScreen> createState() =>
      _SpinningWheelDismissScreenState();
}

class _SpinningWheelDismissScreenState extends State<SpinningWheelDismissScreen>
    with SingleTickerProviderStateMixin {
  static const double _sweep = 2 * pi / _kSlots;

  final _wheelKey = GlobalKey();
  final _startTime = DateTime.now();
  final _confetti =
      ConfettiController(duration: const Duration(milliseconds: 600));
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
    if (_hasSpun) return;
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
    if (_hasSpun) return;
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

  // Animate the wheel to rest on the travel slot, with turns scaled by flick speed.
  void _launchSpin(double speed) {
    _hasSpun = true;
    setState(() => _flickHarder = false);

    final turns = (3 + speed / 900).clamp(3.0, 7.0).round();
    // Small intra-slot jitter so it doesn't always stop dead-centre, but stays
    // within the travel slot (|jitter| < _sweep / 2).
    final jitter = (_rng.nextDouble() - 0.5) * _sweep * 0.7;
    final start = _rotation;
    final fullTurns = (start / (2 * pi)).ceil() + turns;
    final target = fullTurns * 2 * pi + (_kWinningSlot * _sweep) + jitter;

    _spinAnim = Tween<double>(begin: start, end: target).animate(
      CurvedAnimation(parent: _spinController, curve: Curves.easeOutCubic),
    );
    _spinController.duration =
        Duration(milliseconds: (2600 + turns * 200).round());
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
    _confetti.play();
    setState(() => _won = true);
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (mounted) _dismiss();
    });
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
            missionType: MissionType.spinningWheel,
          ),
        ),
      );
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
    final wheelSize = 300.w;

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
                      children: [
                        // Wheel + fixed pointer + spin gesture
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
                                Transform.rotate(
                                  angle: _rotation,
                                  child: CustomPaint(
                                    size: Size(wheelSize, wheelSize),
                                    painter: _WheelPainter(
                                      travelLabel: l10n.slotTravel,
                                      hubColor: c.card,
                                    ),
                                  ),
                                ),
                                // Centre hub
                                Container(
                                  width: 44.w,
                                  height: 44.w,
                                  decoration: BoxDecoration(
                                    color: c.card,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppColors.orange, width: 3),
                                  ),
                                ),
                                // Fixed pointer at the top, biting into the wheel
                                Positioned(
                                  top: -10.h,
                                  child: Icon(
                                    Icons.arrow_drop_down,
                                    size: 48.sp,
                                    color: AppColors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 32.h),
                        Text(
                          _won
                              ? l10n.dismissSpinningWheelWin
                              : _flickHarder
                                  ? l10n.dismissSpinningWheelFlickHarder
                                  : l10n.dismissSpinningWheelPrompt,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: _won ? FontWeight.bold : FontWeight.w400,
                            color: _won
                                ? AppColors.orange
                                : c.textSecondary,
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
            // Preview close button
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

/// Paints the prize wheel: [_kSlots] wedges with the travel slot highlighted,
/// laid out so slot 0 is centred at the top (12 o'clock) at rotation 0.
class _WheelPainter extends CustomPainter {
  final String travelLabel;
  final Color hubColor;

  // Dud-slot colors, cycled across the non-winning wedges.
  static const _dudColors = <Color>[
    Color(0xFF5B8DEF),
    Color(0xFF7B61FF),
    Color(0xFFCC4DAA),
    Color(0xFFE07B3A),
    Color(0xFF3DAD6F),
    Color(0xFF8E8E93),
    Color(0xFFE05C5C),
  ];
  static const _travelColor = Color(0xFFFFC107);

  _WheelPainter({required this.travelLabel, required this.hubColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const sweep = 2 * pi / _kSlots;

    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white;

    var dudCursor = 0;
    for (var i = 0; i < _kSlots; i++) {
      // Slot i centred at canvas angle -π/2 + i*sweep (top = -π/2).
      final centerAngle = -pi / 2 + i * sweep;
      final startAngle = centerAngle - sweep / 2;
      final isTravel = i == _kWinningSlot;
      final fill = Paint()
        ..style = PaintingStyle.fill
        ..color = isTravel
            ? _travelColor
            : _dudColors[dudCursor++ % _dudColors.length];

      canvas.drawArc(rect, startAngle, sweep, true, fill);
      canvas.drawArc(rect, startAngle, sweep, true, border);

      if (isTravel) {
        _drawTravelLabel(canvas, center, radius, centerAngle);
      }
    }

    // Outer rim
    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = Colors.white,
    );
  }

  // Draws "✈️ + label" along the travel wedge bisector, rotated to read radially.
  void _drawTravelLabel(
      Canvas canvas, Offset center, double radius, double centerAngle) {
    final tp = TextPainter(
      text: TextSpan(
        text: '✈️\n$travelLabel',
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          height: 1.1,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(centerAngle + pi / 2);
    // Position toward the rim along the (now vertical) bisector.
    final dy = -(radius * 0.62);
    canvas.translate(0, dy);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WheelPainter oldDelegate) =>
      oldDelegate.travelLabel != travelLabel || oldDelegate.hubColor != hubColor;
}
