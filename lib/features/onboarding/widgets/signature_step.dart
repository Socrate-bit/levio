import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

import '../../../shared/theme/app_theme.dart';

class SignatureStep extends StatefulWidget {
  final String alarmTimeText;
  final VoidCallback onCommit;

  const SignatureStep({
    super.key,
    required this.alarmTimeText,
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            'Lock in your\ncommitment',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sign below to get out of bed at ${widget.alarmTimeText}. Feet on the floor.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: c.textSecondary),
          ),
          const Spacer(),
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.separator),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Signature(
                controller: _controller,
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _controller.isNotEmpty ? widget.onCommit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: c.textPrimary,
                foregroundColor: c.card,
                disabledBackgroundColor: c.separator,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check, size: 20, color: c.card),
                  const SizedBox(width: 8),
                  Text(
                    'I Commit',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: c.card,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
