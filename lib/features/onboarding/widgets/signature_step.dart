import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:signature/signature.dart';

import 'package:levio/l10n/generated/app_localizations.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';

class SignatureStep extends StatefulWidget {
  final String alarmTimeText;
  final bool hasSleep;
  final VoidCallback onCommit;

  const SignatureStep({
    super.key,
    required this.alarmTimeText,
    this.hasSleep = false,
    required this.onCommit,
  });

  @override
  State<SignatureStep> createState() => _SignatureStepState();
}

class _SignatureStepState extends State<SignatureStep> {
  late final SignatureController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black87,
    );
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        children: [
          SizedBox(height: 16.h),
          Text(
            l10n.onboardingSignatureTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
              height: 1.2,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            widget.hasSleep
                ? l10n.onboardingSignatureSleepSubtitle(widget.alarmTimeText)
                : l10n.onboardingSignatureSubtitle(widget.alarmTimeText),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16.sp, color: c.textSecondary),
          ),
          const Spacer(),
          Container(
            height: 250.h,
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: c.separator),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: Signature(
                controller: _controller,
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56.h,
            child: ElevatedButton(
              onPressed: _controller.isNotEmpty ? withHaptic(widget.onCommit) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: c.textPrimary,
                foregroundColor: c.card,
                disabledBackgroundColor: c.separator,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check, size: 20.sp, color: c.card),
                  SizedBox(width: 8.w),
                  Text(
                    l10n.onboardingSignatureCommit,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: c.card,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }
}
