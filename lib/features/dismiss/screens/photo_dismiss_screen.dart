import 'dart:async';

import 'package:camera/camera.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';
import '../../alarms/services/alarm_cascade_controller.dart';

import '../../missions/models/mission.dart';
import '../../missions/services/custom_items_service.dart';
import '../../missions/widgets/item_picker_screen.dart';
import '../../subscription/services/analytics_service.dart';
import '../../settings/cubit/settings_cubit.dart';
import '../../wakeup/screens/wakeup_complete_screen.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../widgets/levio_brand_header.dart';

/// Returns the default item labels for a hunt mission type.
List<String> _defaultItemsFor(MissionType type) {
  final ItemPickerData data;
  switch (type) {
    case MissionType.objectHunt:
      data = objectHuntPickerData;
    case MissionType.petHunt:
      data = petHuntPickerData;
    case MissionType.natureHunt:
      data = natureHuntPickerData;
    default:
      return [];
  }
  return data.sections.expand((s) => s.items).map((i) => i.label).toList();
}

/// Emoji shown in the viewfinder for non-hunt photo missions (sky/bed/grass),
/// replacing the old flat white material icons.
String _photoMissionEmoji(MissionType type) {
  switch (type) {
    case MissionType.skyPhoto:
      return '\u{2600}\u{FE0F}'; // ☀️
    case MissionType.makeBed:
    case MissionType.bedPhoto:
      return '\u{1F6CF}\u{FE0F}'; // 🛏️
    case MissionType.touchGrass:
      return '\u{1F331}'; // 🌱
    default:
      return '\u{1F4F7}'; // 📷
  }
}

class PhotoDismissScreen extends StatefulWidget {
  final String alarmId;
  final String nativeAlarmId;
  final MissionType missionType;
  final String alarmLabel;
  final List<String>? selectedItems;
  final VoidCallback? onComplete;
  final VoidCallback? onProgress;
  final bool manageAlarm;
  final bool isPreview;
  final ValueChanged<String>? onTargetChosen;

  const PhotoDismissScreen({
    super.key,
    required this.alarmId,
    required this.nativeAlarmId,
    this.missionType = MissionType.skyPhoto,
    this.alarmLabel = 'Alarm #1',
    this.selectedItems,
    this.onComplete,
    this.onProgress,
    this.manageAlarm = true,
    this.isPreview = false,
    this.onTargetChosen,
  });

  @override
  State<PhotoDismissScreen> createState() => _PhotoDismissScreenState();
}

enum _PhotoError { none, notDetected, other }

// Resting spot for the "FIND THIS" card once it reveals: docked near the top,
// overlapping the camera's top edge.
const Alignment _kCardTop = Alignment(0, -0.77);

class _PhotoDismissScreenState extends State<PhotoDismissScreen> {
  CameraController? _controller;
  bool _isValidating = false;
  _PhotoError _errorType = _PhotoError.none;
  String? _rawError;
  final _startTime = DateTime.now();
  late final String _targetObject;
  // True when [_targetObject] comes from the admin/UGC forced-target override.
  // A forced target stays visible among the spinning candidates instead of
  // being hidden until the final tick.
  late final bool _forcedTarget;
  late final List<String> _candidates;
  String _displayLabel = '';
  bool _rouletteRunning = false;
  // True once the target reveal is done — the roulette has landed, or the 4s
  // hold elapsed on a mission with no spin. Gates the center glyph, the capture
  // button, and the fly-up of the "FIND THIS" card.
  bool _targetLocked = false;
  Timer? _rouletteTimer;
  // Holds the revealed target emoji in the viewfinder for a beat before it
  // flies up to the card — after the roulette lands, or (for single-object /
  // non-hunt missions with no spin) once the preview is live.
  Timer? _revealTimer;
  AlarmCascadeController? _cascade;
  // Emojis for user-created custom objects (name -> emoji), loaded async.
  Map<String, String> _customEmojis = {};

  // Roulette tick delays (ms) — start fast, decelerate, dramatic last beat.
  // Total ≈ 6.5s — long enough to feel like a draw, short enough not to bore.
  static const _rouletteDelays = <int>[
    70,
    70,
    70,
    70,
    70,
    70,
    70,
    70,
    80,
    80,
    80,
    80,
    90,
    90,
    100,
    110,
    120,
    140,
    160,
    180,
    210,
    240,
    280,
    320,
    380,
    460,
    560,
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Determine target object for hunt missions
    final items =
        (widget.selectedItems != null && widget.selectedItems!.isNotEmpty)
        ? widget.selectedItems!
        : _defaultItemsFor(widget.missionType);
    _candidates = List<String>.from(items);

    // Admin/UGC override: force the roulette to always land on this label,
    // even if it wasn't in the user's selected items. Roulette still spins
    // through the normal candidates so the reveal still feels random.
    final forced = context.read<SettingsCubit>().state.forcedHuntTarget;
    if (_candidates.isNotEmpty && forced != null && forced.isNotEmpty) {
      _targetObject = forced;
      _forcedTarget = true;
      if (!_candidates.contains(forced)) {
        _candidates.add(forced);
      }
    } else {
      _forcedTarget = false;
      _targetObject = _candidates.isNotEmpty
          ? (List<String>.from(_candidates)..shuffle()).first
          : '';
    }

    // Notify the orchestrator so it can cache the pick and re-use it if the
    // mission gets remounted (e.g. inactivity timeout sends user back).
    if (_targetObject.isNotEmpty) {
      widget.onTargetChosen?.call(_targetObject);
    }

    // Prime the initial badge label. The roulette itself is not kicked off
    // until the camera preview is live (see _initCamera) so the spin doesn't
    // play against a black placeholder while the hardware spins up.
    if (_candidates.length > 1) {
      // Start on any candidate that is not the target so the reveal isn't
      // spoiled on the very first frame.
      _displayLabel = _candidates.firstWhere(
        (c) => c != _targetObject,
        orElse: () => _candidates.first,
      );
    } else {
      _displayLabel = _targetObject;
    }

    _initCamera();
    _loadCustomEmojis();
    if (widget.manageAlarm && !widget.isPreview) {
      _cascade = AlarmCascadeController(alarmId: widget.alarmId)..start();
    }
  }

  // Load custom-object emojis so the target badge can show the user's chosen
  // glyph instead of the generic star fallback.
  Future<void> _loadCustomEmojis() async {
    final emojis = await CustomItemsService.getCustomObjectEmojis();
    if (!mounted || emojis.isEmpty) return;
    setState(() => _customEmojis = emojis);
  }

  /// Recursively schedules each roulette tick using a growing delay table.
  /// The final tick lands on [_targetObject] and unlocks the take-photo button.
  void _scheduleRouletteTick(int step) {
    _rouletteTimer = Timer(Duration(milliseconds: _rouletteDelays[step]), () {
      if (!mounted) return;
      final isLast = step == _rouletteDelays.length - 1;
      setState(() {
        if (isLast) {
          // Roulette landed. Reveal the target but keep it in the viewfinder —
          // the fly-up to the card is held back below.
          _displayLabel = _targetObject;
          _rouletteRunning = false;
        } else {
          // Advance to next candidate. For a random target, skip it until the
          // final tick so the reveal is not spoiled mid-spin; a forced target
          // stays in the rotation so it shows as a real possibility.
          final currentIndex = _candidates.indexOf(_displayLabel);
          var nextIndex = (currentIndex + 1) % _candidates.length;
          if (!_forcedTarget &&
              _candidates[nextIndex] == _targetObject &&
              _candidates.length > 2) {
            nextIndex = (nextIndex + 1) % _candidates.length;
          }
          _displayLabel = _candidates[nextIndex];
        }
      });
      // Spinning counts as activity so the inactivity watchdog doesn't bounce
      // the user back mid-draw.
      widget.onProgress?.call();
      _cascade?.reportProgress();
      HapticFeedback.selectionClick();
      if (isLast) {
        HapticFeedback.mediumImpact();
        // Hold the revealed target for 3s before it flies up to the card.
        _revealTimer = Timer(const Duration(seconds: 3), () {
          if (!mounted) return;
          setState(() => _targetLocked = true);
        });
      } else {
        _scheduleRouletteTick(step + 1);
      }
    });
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      setState(() {
        _errorType = _PhotoError.other;
        _rawError = 'No camera available';
      });
      return;
    }
    final controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await controller.initialize();
    // Lock the camera preview so it doesn't rotate when the device tilts.
    await controller.lockCaptureOrientation(DeviceOrientation.portraitUp);
    if (!mounted) return;
    setState(() => _controller = controller);

    // Reveal the target once the preview has rendered. Multi-object missions
    // spin the roulette; single-object and non-hunt missions have nothing to
    // spin, so they hold the emoji in the viewfinder for 3s before it flies up
    // to the card — matching the rhythm of the roulette draw.
    if (_candidates.length > 1 && !_rouletteRunning) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _rouletteRunning) return;
        _rouletteRunning = true;
        _scheduleRouletteTick(0);
      });
    } else if (_candidates.length <= 1 && !_targetLocked) {
      _revealTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() => _targetLocked = true);
      });
    }
  }

  Future<void> _captureAndValidate() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (_isValidating) return;

    widget.onProgress?.call();
    _cascade?.reportProgress();

    setState(() {
      _isValidating = true;
      _errorType = _PhotoError.none;
      _rawError = null;
    });

    try {
      final image = await controller.takePicture();
      final imageBytes = await image.readAsBytes();

      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash-lite',
      );

      final String prompt;
      if (_targetObject.isNotEmpty) {
        prompt =
            'Does this image clearly show a $_targetObject? Reply with only YES or NO.';
      } else {
        prompt = geminiPromptFor(widget.missionType);
      }

      final response = await model.generateContent([
        Content.multi([
          TextPart(prompt),
          InlineDataPart('image/jpeg', imageBytes),
        ]),
      ]);

      final answer = response.text?.trim().toUpperCase() ?? '';
      if (answer.contains('YES')) {
        await _dismiss();
      } else {
        setState(() => _errorType = _PhotoError.notDetected);
      }
    } catch (e, st) {
      AnalyticsService.trackError(
        'PhotoDismissScreen._captureAndValidate',
        e,
        st,
      );
      setState(() {
        _errorType = _PhotoError.other;
        _rawError = e.toString();
      });
    } finally {
      if (mounted) setState(() => _isValidating = false);
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
    _rouletteTimer?.cancel();
    _revealTimer?.cancel();
    _controller?.dispose();
    _cascade?.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  // Localized label for the currently displayed target — follows the roulette
  // mid-spin then settles on the actual picked target.
  String _targetLabel(AppLocalizations l10n) => _displayLabel.isNotEmpty
      ? localizedItemName(l10n, _displayLabel)
      : localizedPhotoTarget(l10n, widget.missionType);

  String? _resolveError(AppLocalizations l10n) {
    switch (_errorType) {
      case _PhotoError.none:
        return null;
      case _PhotoError.notDetected:
        return l10n.dismissPhotoNotDetected(_targetLabel(l10n).toLowerCase());
      case _PhotoError.other:
        return _rawError != null ? l10n.dismissPhotoError(_rawError!) : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final controller = _controller;
    final l10n = AppLocalizations.of(context);
    final targetLabel = _targetLabel(l10n);
    final errorMessage = _resolveError(l10n);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              spacing: 12.h,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const LevioBrandHeader(),
                SizedBox(height: 12.h,),

                Flexible(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child:
                          controller != null &&
                              controller.value.isInitialized &&
                              controller.value.previewSize != null
                          ? AspectRatio(
                              aspectRatio:
                                  controller.value.previewSize!.height /
                                  controller.value.previewSize!.width,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28.r),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    CameraPreview(controller),

                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: RadialGradient(
                                          center: Alignment.center,
                                          radius: 1.0,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withAlpha(80),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // Viewfinder frame — always centered so it
                                    // frames the real object after the target
                                    // emoji has flown up to the top card. The
                                    // big glyph shows until the target locks in
                                    // (roulette landed, or the 4s hold elapsed).
                                    Center(
                                      child: _ViewfinderFrame(
                                        child: _targetLocked
                                            ? const SizedBox.shrink()
                                            : _TargetBadge(
                                                label: _displayLabel,
                                                missionType: widget.missionType,
                                                isHunt:
                                                    _targetObject.isNotEmpty,
                                                spinning: _rouletteRunning,
                                                customEmojis: _customEmojis,
                                              ),
                                      ),
                                    ),

                                    if (errorMessage != null)
                                      Positioned(
                                        top: 14.h,
                                        left: 16.w,
                                        right: 16.w,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(
                                            vertical: 7.h,
                                            horizontal: 14.w,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.error.withAlpha(
                                              200,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12.r,
                                            ),
                                          ),
                                          child: Text(
                                            errorMessage,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),

                                    if (_isValidating)
                                      Container(
                                        color: Colors.black54,
                                        child: Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const CircularProgressIndicator(
                                                color: AppColors.orange,
                                                strokeWidth: 2.5,
                                              ),
                                              SizedBox(height: 16.h),
                                              Text(
                                                l10n.dismissPhotoChecking(
                                                  targetLabel.toLowerCase(),
                                                ),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14.sp,
                                                  letterSpacing: 0.3,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(
                                  color: AppColors.orange,
                                  strokeWidth: 2.5,
                                ),
                                SizedBox(height: 16.h),
                                Text(
                                  l10n.dismissPhotoStarting,
                                  style: TextStyle(
                                    color: c.textSecondary,
                                    fontSize: 14.sp,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: (_isValidating || !_targetLocked)
                          ? null
                          : withHaptic(_captureAndValidate),
                      child: Container(
                        width: 72.w,
                        height: 72.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (_isValidating || !_targetLocked)
                              ? c.textPrimary.withAlpha(80)
                              : c.textPrimary,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(40),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: c.background,
                          size: 32.sp,
                        ),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    SizedBox(
                      height: 16.h,
                      child: _rouletteRunning
                          ? Text(
                              l10n.dismissPhotoPickingTarget,
                              style: TextStyle(
                                color: c.textSecondary,
                                fontSize: 12.sp,
                                letterSpacing: 0.3,
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
              ],
            ),

            // "FIND THIS" pill card. Hidden while the target is being revealed
            // (roulette spin, or the 4s hold for single-object / non-hunt
            // missions); on lock-in it flies up from the camera's center —
            // where the emoji was sitting — to dock at the top with it.
            if (controller != null &&
                controller.value.isInitialized &&
                _targetLocked)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 450),
                curve: Curves.easeOutCubic,
                builder: (context, t, child) => Align(
                  alignment: Alignment.lerp(Alignment.center, _kCardTop, t)!,
                  child: Opacity(
                    opacity: Curves.easeOut.transform(t),
                    child: Transform.scale(
                      scale: 0.92 + 0.08 * t,
                      child: child,
                    ),
                  ),
                ),
                child: _FindThisCard(
                  eyebrow: _targetObject.isNotEmpty
                      ? l10n.dismissPhotoFindThis
                      : l10n.dismissPhotoTakePhoto,
                  emoji: _targetObject.isNotEmpty
                      ? (emojiForItemLabel(_displayLabel) ??
                            _customEmojis[_displayLabel] ??
                            '\u{2b50}')
                      : _photoMissionEmoji(widget.missionType),
                  label: targetLabel,
                ),
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

/// Single rounded rectangle viewfinder centered around the target badge.
/// Sized to hug the badge with breathing room — tighter than a full-bleed
/// viewfinder so the eye lands on the target.
class _ViewfinderFrame extends StatelessWidget {
  final Widget child;
  const _ViewfinderFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220.w,
      height: 220.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40.r),
        border: Border.all(color: Colors.white70, width: 3),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 18),
        ],
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}

/// Rounded "FIND THIS" pill that names the target. Flies up from the camera's
/// center to dock at the top once the pick is locked in.
class _FindThisCard extends StatelessWidget {
  final String eyebrow;
  final String emoji;
  final String label;

  const _FindThisCard({
    required this.eyebrow,
    required this.emoji,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 16),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                eyebrow,
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
            ],
          ),
          SizedBox(width: 12.w),
          Text(emoji, style: TextStyle(fontSize: 50.sp)),
        ],
      ),
    );
  }
}

/// Centered target glyph — emoji for hunt items, the mission emoji for
/// sky/bed/grass. Large and slightly transparent so the camera feed shows
/// through. When the roulette finishes ([spinning] goes false), plays a reveal
/// animation: a scale bounce and a radial glow that pulses out behind the glyph.
class _TargetBadge extends StatefulWidget {
  final String label;
  final MissionType missionType;
  final bool isHunt;
  final bool spinning;
  final Map<String, String> customEmojis;

  const _TargetBadge({
    required this.label,
    required this.missionType,
    required this.isHunt,
    required this.spinning,
    required this.customEmojis,
  });

  @override
  State<_TargetBadge> createState() => _TargetBadgeState();
}

class _TargetBadgeState extends State<_TargetBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal;
  // Bounce: 0 → 1.25 → 1.10 (settles slightly larger than original).
  late final Animation<double> _scale;
  // Glow halo: pulses in, then fades out.
  late final Animation<double> _glow;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.94,
          end: 1.25,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.25,
          end: 1.05,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.05,
          end: 1.10,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_reveal);
    _glow = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.35,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 65,
      ),
    ]).animate(_reveal);
    _opacity = Tween(
      begin: 0.78,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _reveal, curve: Curves.easeOut));
    // If we're already on the final target (no spin), settle in final state.
    if (!widget.spinning) _reveal.value = 1.0;
  }

  @override
  void didUpdateWidget(_TargetBadge old) {
    super.didUpdateWidget(old);
    if (old.spinning && !widget.spinning) {
      _reveal.forward(from: 0.0);
    } else if (!old.spinning && widget.spinning) {
      _reveal.value = 0.0;
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emoji = widget.isHunt
        ? (emojiForItemLabel(widget.label) ??
              widget.customEmojis[widget.label] ??
              '\u{2b50}')
        : _photoMissionEmoji(widget.missionType);
    return AnimatedBuilder(
      animation: _reveal,
      builder: (context, _) {
        final scale = widget.spinning ? 0.94 : _scale.value;
        final opacity = widget.spinning ? 0.78 : _opacity.value;
        final glow = widget.spinning ? 0.0 : _glow.value;
        return Transform.scale(
          scale: scale,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glowing halo — radial gradient that pulses during the reveal.
              if (glow > 0.0)
                IgnorePointer(
                  child: Container(
                    width: 180.sp,
                    height: 180.sp,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.orange.withAlpha((180 * glow).round()),
                          AppColors.orange.withAlpha((60 * glow).round()),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
              Opacity(
                opacity: opacity,
                child: Text(emoji, style: TextStyle(fontSize: 130.sp)),
              ),
            ],
          ),
        );
      },
    );
  }
}
