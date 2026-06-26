import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import 'alarm_channel.dart';

/// Post-subscription readiness checks. Levio's alarms only work on recent iOS
/// with AlarmKit authorization granted, so once a user has access we surface a
/// friendly, guided dialog when the OS is too old, or when alarm permission is
/// missing. No-op on supported, authorized devices.
class AlarmReadinessGuard {
  AlarmReadinessGuard._();

  /// Minimum iOS major version required for AlarmKit.
  static const _minIosVersion = 26;

  /// iOS major version parsed from [Platform.operatingSystemVersion]
  /// (e.g. "Version 26.0 (Build 23A340)" → 26). 0 on non-iOS.
  static int get _iosMajorVersion {
    if (!Platform.isIOS) return 0;
    final match = RegExp(r'(\d+)').firstMatch(Platform.operatingSystemVersion);
    return match != null ? int.parse(match.group(1)!) : 0;
  }

  /// Whether the device can actually run Levio alarms: supported iOS version
  /// with AlarmKit authorization granted. Always true on non-iOS platforms.
  static Future<bool> isReady() async {
    if (!Platform.isIOS) return true;
    if (_iosMajorVersion < _minIosVersion) return false;
    final status = await AlarmChannel.getAuthorizationStatus();
    return status == AlarmAuthorizationStatus.authorized;
  }

  /// Gate for create/activate actions: returns true when the device is ready,
  /// otherwise surfaces the readiness dialog and returns false so the caller can
  /// abort the action.
  static Future<bool> check(BuildContext context) async {
    if (await isReady()) return true;
    if (!context.mounted) return false;
    await ensure(context);
    return false;
  }

  /// Shows the relevant dialog when the device can't run Levio alarms. No-op on
  /// non-iOS platforms, or on a supported iOS with authorization already granted.
  static Future<void> ensure(BuildContext context) async {
    if (!Platform.isIOS) return;

    final l10n = AppLocalizations.of(context);

    // iOS too old: AlarmKit (and the native channel) is unavailable.
    if (_iosMajorVersion < _minIosVersion) {
      if (!context.mounted) return;
      await _showOsUpdateDialog(context, l10n);
      return;
    }

    // Authorization missing: nudge the user to turn it on.
    final status = await AlarmChannel.getAuthorizationStatus();
    if (status == AlarmAuthorizationStatus.authorized) return;
    if (!context.mounted) return;
    await _showAuthorizationDialog(context, l10n, status);
  }

  static Future<void> _showOsUpdateDialog(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ReadinessDialog(
        title: l10n.osUpdateRequiredTitle,
        body: l10n.osUpdateRequiredBody,
        steps: [
          l10n.osUpdateStep1,
          l10n.osUpdateStep2,
          l10n.osUpdateStep3,
        ],
        primaryLabel: l10n.osUpdateButton,
        onPrimary: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  static Future<void> _showAuthorizationDialog(
    BuildContext context,
    AppLocalizations l10n,
    AlarmAuthorizationStatus status,
  ) {
    final denied = status == AlarmAuthorizationStatus.denied;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _ReadinessDialog(
        title: l10n.alarmPermissionTitle,
        body: denied ? l10n.alarmPermissionDeniedBody : l10n.alarmPermissionBody,
        // When denied, the system prompt won't reappear — guide them to Settings.
        steps: denied
            ? [
                l10n.alarmPermissionStep1,
                l10n.alarmPermissionStep2,
                l10n.alarmPermissionStep3,
              ]
            : const [],
        primaryLabel:
            denied ? l10n.alarmPermissionOpenSettings : l10n.alarmPermissionEnable,
        secondaryLabel: l10n.alarmPermissionNotNow,
        onPrimary: () async {
          Navigator.of(ctx).pop();
          if (denied) {
            await AlarmChannel.openAppSettings();
          } else {
            await AlarmChannel.requestAuthorization();
          }
        },
        onSecondary: () => Navigator.of(ctx).pop(),
      ),
    );
  }
}

/// Branded readiness dialog: siren icon, friendly copy, optional numbered
/// how-to steps, and a primary (plus optional secondary) action.
class _ReadinessDialog extends StatelessWidget {
  final String title;
  final String body;
  final List<String> steps;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  const _ReadinessDialog({
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    this.steps = const [],
    this.secondaryLabel,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Dialog(
      backgroundColor: c.card,
      insetPadding: EdgeInsets.symmetric(horizontal: 32.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28.r)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88.w,
              height: 88.w,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Image.asset('assets/siren.png', width: 52.w, height: 52.w),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: c.textPrimary,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15.sp,
                height: 1.4,
                color: c.textSecondary,
              ),
            ),
            if (steps.isNotEmpty) ...[
              SizedBox(height: 20.h),
              for (var i = 0; i < steps.length; i++) ...[
                if (i > 0) SizedBox(height: 12.h),
                _StepRow(index: i + 1, text: steps[i], color: c),
              ],
            ],
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              height: 54.h,
              child: ElevatedButton(
                onPressed: withHaptic(onPrimary),
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.textPrimary,
                  foregroundColor: c.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27.r),
                  ),
                ),
                child: Text(
                  primaryLabel,
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w600,
                    color: c.card,
                  ),
                ),
              ),
            ),
            if (secondaryLabel != null) ...[
              SizedBox(height: 6.h),
              TextButton(
                onPressed: withHaptic(onSecondary ?? () {}),
                child: Text(
                  secondaryLabel!,
                  style: TextStyle(fontSize: 15.sp, color: c.textSecondary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A single numbered how-to step.
class _StepRow extends StatelessWidget {
  final int index;
  final String text;
  final AppColors color;

  const _StepRow({required this.index, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26.w,
          height: 26.w,
          decoration: const BoxDecoration(
            color: AppColors.orange,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$index',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 3.h),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14.sp,
                height: 1.3,
                color: color.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
