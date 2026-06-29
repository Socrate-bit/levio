import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:levio/l10n/generated/app_localizations.dart';

import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/haptic_utils.dart';
import '../../settings/cubit/settings_cubit.dart';

/// Supported app languages (code, flag emoji, endonym shown in its own tongue).
const _languages = <({String code, String flag, String name})>[
  (code: 'en', flag: '🇬🇧', name: 'English'),
  (code: 'fr', flag: '🇫🇷', name: 'Français'),
];

String _flagFor(String code) =>
    _languages.firstWhere((l) => l.code == code, orElse: () => _languages.first)
        .flag;

/// Small rounded flag button (shows the active language) that opens the
/// language picker. Place it in the top-right of the onboarding header.
class LanguageFlagButton extends StatelessWidget {
  const LanguageFlagButton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final code = Localizations.localeOf(context).languageCode;
    return GestureDetector(
      onTap: withHaptic(() => showLanguageSheet(context)),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: c.separator),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_flagFor(code), style: TextStyle(fontSize: 18.sp)),
            SizedBox(width: 4.w),
            Icon(Icons.keyboard_arrow_down, size: 16.sp, color: c.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// Bottom-sheet language picker. Selecting a language updates the persisted
/// override on [SettingsCubit], which re-localizes the whole app reactively.
Future<void> showLanguageSheet(BuildContext context) {
  final c = AppColors.of(context);
  final l10n = AppLocalizations.of(context);
  final settings = context.read<SettingsCubit>();
  final current = Localizations.localeOf(context).languageCode;

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: c.background,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
    ),
    builder: (_) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: c.separator,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              l10n.languageSelectTitle,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: c.textPrimary,
              ),
            ),
            SizedBox(height: 16.h),
            for (final lang in _languages)
              Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: GestureDetector(
                  onTap: withHaptic(() {
                    settings.setLocale(Locale(lang.code));
                    Navigator.pop(context);
                  }),
                  child: Container(
                    width: double.infinity,
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: lang.code == current
                            ? c.textPrimary
                            : c.separator,
                        width: lang.code == current ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(lang.flag, style: TextStyle(fontSize: 24.sp)),
                        SizedBox(width: 14.w),
                        Expanded(
                          child: Text(
                            lang.name,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                              color: c.textPrimary,
                            ),
                          ),
                        ),
                        if (lang.code == current)
                          Icon(Icons.check_circle,
                              size: 22.sp, color: AppColors.orange),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
