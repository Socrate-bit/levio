import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../../alarms/data/sounds.dart';
import '../../subscription/services/analytics_service.dart';

class SoundPickerStep extends StatefulWidget {
  final String selectedId;
  final void Function(String id, String name) onSelected;

  const SoundPickerStep({
    super.key,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  State<SoundPickerStep> createState() => _SoundPickerStepState();
}

class _SoundPickerStepState extends State<SoundPickerStep> {
  String? _playingId;
  final _player = AudioPlayer();

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _previewSound(String id) async {
    if (_playingId == id) {
      await _player.stop();
      setState(() => _playingId = null);
      return;
    }
    setState(() => _playingId = id);
    try {
      final path = soundAssetPath(id);
      if (path == null) return;
      await _player.play(AssetSource(path));
      _player.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _playingId = null);
      });
    } catch (e, st) {
      AnalyticsService.trackError('SoundPickerStep._previewSound', e, st);
      if (mounted) setState(() => _playingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 0),
          child: Text(
            l10n.onboardingSoundPickerTitle,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
              height: 1.2,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            children: soundCategories.map((cat) {
              final catSounds =
                  alarmSounds.where((s) => s.category == cat).toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(soundCategoryIcons[cat] ?? '',
                          style: TextStyle(fontSize: 16.sp)),
                      SizedBox(width: 6.w),
                      Text(
                        localizedSoundCategory(l10n, cat).toUpperCase(),
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                          color: c.textSecondary,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  ...catSounds.map((sound) {
                    final isSelected = widget.selectedId == sound.id;
                    final isPlaying = _playingId == sound.id;
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8.h),
                      child: GestureDetector(
                        onTap: withHaptic(() =>
                            widget.onSelected(sound.id, sound.name)),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 14.h),
                          decoration: BoxDecoration(
                            color: c.card,
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(
                              color: isSelected
                                  ? c.textPrimary
                                  : c.separator,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36.w,
                                height: 36.h,
                                decoration: BoxDecoration(
                                  color: sound.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 14.w),
                              Expanded(
                                child: Text(
                                  localizedSoundName(l10n, sound.id),
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    color: c.textPrimary,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: withHaptic(() => _previewSound(sound.id)),
                                child: Padding(
                                  padding: EdgeInsets.all(4.w),
                                  child: Icon(
                                    isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: isPlaying
                                        ? c.textPrimary
                                        : c.textSecondary,
                                    size: 22.sp,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Container(
                                width: 24.w,
                                height: 24.h,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? c.textPrimary
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected
                                        ? c.textPrimary
                                        : c.textSecondary,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? Icon(Icons.check,
                                        size: 16.sp, color: c.card)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  SizedBox(height: 12.h),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
