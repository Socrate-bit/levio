import 'package:flutter/material.dart';
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
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: c.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Welcome to Levio, developed by ECOM-PARIS LLC. By accessing or using our app, services, or related applications, you agree to comply with and be bound by the following terms and conditions.',
              style: TextStyle(fontSize: 15, color: c.textSecondary),
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 24),
            Center(
              child: Text(
                '© 2025 ECOM-PARIS LLC. All rights reserved.',
                style: TextStyle(fontSize: 13, color: c.textSecondary),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(AppColors c, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(fontSize: 15, color: c.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(AppColors c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '8. Contact Information',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'If you have questions about these Terms, please contact us:',
            style: TextStyle(fontSize: 15, color: c.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Email: ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: c.textPrimary,
                ),
              ),
              Expanded(
                child: Text(
                  'contact@ecomparis.org',
                  style: TextStyle(fontSize: 15, color: c.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Address: ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: c.textPrimary,
                ),
              ),
              Expanded(
                child: Text(
                  '8206 LOUISIANA BLVD NE, STE A #2226, Albuquerque, NM 87113, USA',
                  style: TextStyle(fontSize: 15, color: c.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
