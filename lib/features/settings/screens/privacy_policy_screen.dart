import 'package:flutter/material.dart';
import '../../../shared/theme/app_theme.dart';

/// Privacy Policy screen for ECOM-PARIS LLC / Levio app
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          'Privacy Policy',
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
              'Privacy Policy',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This Privacy Policy explains how ECOM-PARIS LLC ("we", "our", "us") collects, uses, stores, and protects your personal information when you use Levio or related services.',
              style: TextStyle(fontSize: 15, color: c.textSecondary),
            ),
            const SizedBox(height: 24),
            _buildBulletSection(c, '1. Information We Collect', '', [
              'Usage data (app interactions, alarm usage patterns)',
              'Anonymous account information (Firebase anonymous auth)',
              'Alarm and session data stored in your Firestore profile',
            ]),
            _buildBulletSection(c, '2. How We Use Your Information', '', [
              'To provide and improve alarm, mission, and analytics features',
              'To respond to user inquiries and customer support requests',
              'To send essential updates and comply with legal obligations',
            ]),
            _buildParagraphSection(c, '3. Camera, Biometric and Sensor Data',
                'Levio uses your device camera and motion sensors to detect mission completion (e.g., counting exercise repetitions via pose detection, detecting phone shakes). This data is processed transiently on-device and is never stored, uploaded, or retained.\n\nWe do not collect, store, or retain any biometric or face data. While the camera may capture images during exercise missions, these frames are processed solely for real-time rep counting and are immediately discarded. No images or biometric identifiers are saved or transmitted.'),
            _buildBulletSection(
                c, '4. AI-Processed Data', '', [
              'Certain features may use Google Gemini for processing (e.g., photo verification missions)',
              'Images sent to Gemini are processed only for the requested task and are not retained by Google or any third party',
              'No biometric data is extracted or stored during AI processing',
            ]),
            _buildBulletSection(c, '5. Sharing of Information', '', [
              'We do not sell, rent, or share personal data with third parties',
              'Google Gemini only processes data transiently and does not store or reuse it',
            ]),
            _buildParagraphSection(c, '6. Data Security',
                'We use appropriate technical and organizational measures to protect all personal data against unauthorized access, alteration, loss, or misuse.'),
            _buildParagraphSection(c, '7. Your Rights',
                'You may request access, correction, or deletion of your personal data by contacting us directly. We respond to all verified requests in compliance with applicable privacy laws.'),
            _buildParagraphSection(c, '8. Policy Updates',
                'We may update this Privacy Policy periodically. Any revisions will be posted on this page with an updated effective date.'),
            _buildContactSection(c),
            _buildDeletionSection(c),
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

  Widget _buildBulletSection(
      AppColors c, String title, String description, List<String> items) {
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
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(fontSize: 15, color: c.textSecondary),
            ),
          ],
          const SizedBox(height: 8),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ',
                        style:
                            TextStyle(fontSize: 15, color: c.textSecondary)),
                    Expanded(
                      child: Text(item,
                          style: TextStyle(
                              fontSize: 15, color: c.textSecondary)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildParagraphSection(
      AppColors c, String title, String description) {
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
            description,
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
            '9. Contact Us',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'For any questions regarding this Privacy Policy, please contact:',
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

  Widget _buildDeletionSection(AppColors c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '10. Data Deletion Requests',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Users can request deletion of all personal data associated with their account at any time. To do so:',
            style: TextStyle(fontSize: 15, color: c.textSecondary),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ',
                    style: TextStyle(fontSize: 15, color: c.textSecondary)),
                Expanded(
                  child: Text(
                    'Use the "Delete Account" option available in the app settings, which permanently removes your data from our servers',
                    style: TextStyle(fontSize: 15, color: c.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ',
                    style: TextStyle(fontSize: 15, color: c.textSecondary)),
                Expanded(
                  child: Text(
                    'Or send an email to contact@ecomparis.org with the subject "Data Deletion Request"',
                    style: TextStyle(fontSize: 15, color: c.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All verified deletion requests are processed within 30 days and cannot be undone once completed.',
            style: TextStyle(fontSize: 15, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}
