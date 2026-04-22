import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../shared/theme/app_theme.dart';

/// Terms and Conditions screen for ECOM-PARIS LLC / Levio app
class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: c.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Terms and Conditions',
          style: TextStyle(
            fontSize: 17.sp,
            fontWeight: FontWeight.w600,
            color: c.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: c.textPrimary,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Welcome to Levio, developed by ECOM-PARIS LLC. By accessing or using our app, services, or related applications, you agree to comply with and be bound by the following terms and conditions.',
              style: TextStyle(fontSize: 15.sp, color: c.textSecondary),
            ),
            SizedBox(height: 24.h),
            _buildSection(c, '1. Use of Services',
                'You agree to use Levio only for lawful purposes and in accordance with these Terms. You may not use our services to infringe upon the rights of others or to engage in any harmful or illegal activity.'),
            _buildSection(c, '2. Intellectual Property',
                'All content, trademarks, logos, and materials provided in this app are the property of ECOM-PARIS LLC or its licensors. You may not reproduce, distribute, or create derivative works without prior written consent.'),
            _buildSection(c, '3. Camera and Sensor Usage',
                'Levio uses your device camera and motion sensors solely to detect mission completion (e.g., counting exercise reps, detecting shakes). Camera data and sensor readings are processed locally and transiently — they are never stored, uploaded, or retained by Levio or any third party.'),
            _buildSection(c, '4. Privacy',
                'Your use of our services is also governed by our Privacy Policy, which explains how we collect, use, and protect your personal information.'),
            _buildSection(c, '5. Limitation of Liability',
                'ECOM-PARIS LLC is not liable for any direct, indirect, incidental, or consequential damages arising from your use of our services or inability to access them.'),
            _buildSection(c, '6. Changes to Terms',
                'We reserve the right to update or modify these Terms of Service at any time. Continued use of our services after changes constitutes acceptance of the new terms.'),
            _buildSection(c, '7. Governing Law',
                'These Terms are governed by the laws of the State of New Mexico, USA, without regard to conflict of law principles.'),
            _buildContactSection(c),
            SizedBox(height: 24.h),
            Center(
              child: Text(
                '© 2025 ECOM-PARIS LLC. All rights reserved.',
                style: TextStyle(fontSize: 13.sp, color: c.textSecondary),
              ),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(AppColors c, String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            content,
            style: TextStyle(fontSize: 15.sp, color: c.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(AppColors c) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '8. Contact Information',
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'If you have questions about these Terms, please contact us:',
            style: TextStyle(fontSize: 15.sp, color: c.textSecondary),
          ),
          SizedBox(height: 8.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Email: ',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  color: c.textPrimary,
                ),
              ),
              Expanded(
                child: Text(
                  'contact@ecomparis.org',
                  style: TextStyle(fontSize: 15.sp, color: c.textSecondary),
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Address: ',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  color: c.textPrimary,
                ),
              ),
              Expanded(
                child: Text(
                  '8206 LOUISIANA BLVD NE, STE A #2226, Albuquerque, NM 87113, USA',
                  style: TextStyle(fontSize: 15.sp, color: c.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
