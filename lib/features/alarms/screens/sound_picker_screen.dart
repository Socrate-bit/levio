import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../shared/utils/haptic_utils.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import 'package:levio/l10n/l10n_helpers.dart';
import '../../../shared/theme/app_theme.dart';
import '../data/sounds.dart';

class SoundPickerScreen extends StatefulWidget {
  const SoundPickerScreen({super.key});

  @override
  State<SoundPickerScreen> createState() => _SoundPickerScreenState();
}

class _SoundPickerScreenState extends State<SoundPickerScreen> {
  String _selectedId = 'default';
  String? _playingId;
  final _player = AudioPlayer();
  List<CustomSoundItem> _customSounds = [];
  bool _isPickingFile = false;

  @override
  void initState() {
    super.initState();
    _loadCustomSounds();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _loadCustomSounds() async {
    final sounds = await loadCustomSounds();
    if (mounted) setState(() => _customSounds = sounds);
  }

  /// Pick an audio file, copy it to app storage, and refresh the list.
  Future<void> _uploadSound() async {
    // Guard against rapid double taps triggering a second pickFiles call while
    // the first picker dialog is still open (native throws multiple_request).
    if (_isPickingFile) return;
    _isPickingFile = true;
    final FilePickerResult? result;
    try {
      result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'aiff'],
      );
    } catch (e) {
      debugPrint('[SoundPickerScreen] file pick failed: $e');
      return;
    } finally {
      _isPickingFile = false;
    }
    if (result == null || result.files.single.path == null) return;

    final file = result.files.single;
    final item = await addCustomSound(file.path!, file.name);
    if (item == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File too large (max 10 MB)')),
        );
      }
      return;
    }
    await _loadCustomSounds();
    if (mounted) setState(() => _selectedId = item.id);
  }

  /// Delete a custom sound after user confirmation.
  Future<void> _confirmDelete(CustomSoundItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Sound'),
        content: Text('Remove "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: withHaptic(() => Navigator.pop(ctx, false)),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: withHaptic(() => Navigator.pop(ctx, true)),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await deleteCustomSound(item.id);
    if (_selectedId == item.id) _selectedId = 'default';
    if (_playingId == item.id) {
      await _player.stop();
      _playingId = null;
    }
    await _loadCustomSounds();
  }

  /// Preview a sound — toggle play/stop. Handles both preset and custom sources.
  Future<void> _previewSound(String id) async {
    if (_playingId == id) {
      await _player.stop();
      setState(() => _playingId = null);
      return;
    }
    setState(() => _playingId = id);
    try {
      if (isCustomSound(id)) {
        final item = _customSounds.firstWhere((s) => s.id == id);
        final path = await customSoundFilePath(item.fileName);
        await _player.play(DeviceFileSource(path));
      } else {
        final path = soundAssetPath(id);
        if (path == null) return;
        await _player.play(AssetSource(path));
      }
      _player.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _playingId = null);
      });
    } catch (_) {
      if (mounted) setState(() => _playingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: withHaptic(() => Navigator.pop(context)),
                    child: Container(
                      width: 36.w,
                      height: 36.h,
                      decoration: BoxDecoration(
                        color: c.card,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close,
                          size: 18.sp, color: c.textPrimary),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        l10n.soundPickerTitle,
                        style: TextStyle(
                          fontSize: 17.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 36.w),
                ],
              ),
            ),
            SizedBox(height: 12.h),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                children: [
                  SizedBox(height: 20.h),
                  // Your Sounds section
                  _SectionHeader(title: l10n.soundPickerYourSounds),
                  GestureDetector(
                    onTap: withHaptic(_uploadSound),
                    child: Container(
                      margin: EdgeInsets.only(top: 8.h, bottom: 4.h),
                      padding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 14.h),
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.add,
                              size: 18.sp, color: c.textSecondary),
                          SizedBox(width: 12.w),
                          Text(
                            l10n.soundPickerUpload,
                            style: TextStyle(
                              fontSize: 15.sp,
                              color: c.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Custom sound rows
                  if (_customSounds.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Container(
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Column(
                        children: _customSounds.asMap().entries.map((entry) {
                          final i = entry.key;
                          final sound = entry.value;
                          final isFirst = i == 0;
                          final isLast = i == _customSounds.length - 1;
                          final isSelected = _selectedId == sound.id;
                          final isPlaying = _playingId == sound.id;
                          return GestureDetector(
                            onTap: withHaptic(() =>
                                setState(() => _selectedId = sound.id)),
                            onLongPress: () => _confirmDelete(sound),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.w, vertical: 14.h),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  topLeft: isFirst
                                      ? Radius.circular(14.r)
                                      : Radius.zero,
                                  topRight: isFirst
                                      ? Radius.circular(14.r)
                                      : Radius.zero,
                                  bottomLeft: isLast
                                      ? Radius.circular(14.r)
                                      : Radius.zero,
                                  bottomRight: isLast
                                      ? Radius.circular(14.r)
                                      : Radius.zero,
                                ),
                                border: isSelected
                                    ? Border.all(
                                        color: c.purpleDeep,
                                        width: 2,
                                      )
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36.w,
                                    height: 36.h,
                                    decoration: BoxDecoration(
                                      color: c.purpleDeep.withValues(alpha: 0.3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(Icons.music_note,
                                        size: 18.sp, color: c.purpleDeep),
                                  ),
                                  SizedBox(width: 14.w),
                                  Expanded(
                                    child: Text(
                                      sound.name,
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        color: c.textPrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: withHaptic(() => _previewSound(sound.id)),
                                    child: Icon(
                                      isPlaying
                                          ? Icons.equalizer
                                          : Icons.play_circle_outline,
                                      color: isPlaying
                                          ? AppColors.orange
                                          : c.textSecondary,
                                      size: 22.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  SizedBox(height: 16.h),
                  ...soundCategories.map((cat) {
                    final catSounds =
                        alarmSounds.where((s) => s.category == cat).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionHeader(
                          title: localizedSoundCategory(l10n, cat),
                          icon: soundCategoryIcons[cat],
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          decoration: BoxDecoration(
                            color: c.card,
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          child: Column(
                            children:
                                catSounds.asMap().entries.map((entry) {
                              final i = entry.key;
                              final sound = entry.value;
                              final isFirst = i == 0;
                              final isLast = i == catSounds.length - 1;
                              final isSelected =
                                  _selectedId == sound.id;
                              final isPlaying = _playingId == sound.id;
                              return GestureDetector(
                                onTap: withHaptic(() => setState(
                                    () => _selectedId = sound.id)),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16.w, vertical: 14.h),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                      topLeft: isFirst
                                          ? Radius.circular(14.r)
                                          : Radius.zero,
                                      topRight: isFirst
                                          ? Radius.circular(14.r)
                                          : Radius.zero,
                                      bottomLeft: isLast
                                          ? Radius.circular(14.r)
                                          : Radius.zero,
                                      bottomRight: isLast
                                          ? Radius.circular(14.r)
                                          : Radius.zero,
                                    ),
                                    border: isSelected
                                        ? Border.all(
                                            color: c.purpleDeep,
                                            width: 2,
                                          )
                                        : null,
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
                                      Text(
                                        localizedSoundName(l10n, sound.id),
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          color: c.textPrimary,
                                        ),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: withHaptic(() => _previewSound(sound.id)),
                                        child: Icon(
                                          isPlaying
                                              ? Icons.equalizer
                                              : Icons.play_circle_outline,
                                          color: isPlaying
                                              ? AppColors.orange
                                              : c.textSecondary,
                                          size: 22.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        SizedBox(height: 16.h),
                      ],
                    );
                  }),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
              child: ElevatedButton(
                onPressed: withHaptic(() {
                  // Handle both preset and custom sounds
                  if (isCustomSound(_selectedId)) {
                    final sound =
                        _customSounds.firstWhere((s) => s.id == _selectedId);
                    Navigator.pop(
                        context, {'id': sound.id, 'name': sound.name});
                  } else {
                    final sound =
                        alarmSounds.firstWhere((s) => s.id == _selectedId);
                    Navigator.pop(
                        context, {'id': sound.id, 'name': sound.name});
                  }
                }),
                child: Text(l10n.soundPickerSelect),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? icon;

  const _SectionHeader({required this.title, this.icon});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        if (icon != null) ...[
          Text(icon!, style: TextStyle(fontSize: 16.sp)),
          SizedBox(width: 6.w),
        ],
        Text(
          title,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.bold,
            color: c.textPrimary,
          ),
        ),
      ],
    );
  }
}
