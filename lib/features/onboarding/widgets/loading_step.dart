import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

class LoadingStep extends StatefulWidget {
  final VoidCallback onComplete;

  const LoadingStep({super.key, required this.onComplete});

  @override
  State<LoadingStep> createState() => _LoadingStepState();
}

class _LoadingStepState extends State<LoadingStep> {
  int _completedIndex = -1;
  int _percent = 0;

  static const _steps = [
    'Configuring your goals',
    'Setting your mission',
    'Setting alarm tone',
    'Scheduling your alarm',
    'Setting up wake receipt',
  ];

  @override
  void initState() {
    super.initState();
    _runAnimation();
  }

  Future<void> _runAnimation() async {
    for (var i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() {
        _completedIndex = i;
        _percent = ((i + 1) / _steps.length * 100).round();
      });
    }
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return PopScope(
      canPop: false,
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Text(
            '$_percent%',
            style: TextStyle(
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Setting everything up\nfor you',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _percent / 100,
              backgroundColor: c.separator,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.orange),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 32),
          // Checklist
          ..._steps.asMap().entries.map((entry) {
            final i = entry.key;
            final label = entry.value;
            final isDone = i <= _completedIndex;
            final isCurrent = i == _completedIndex + 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone ? AppColors.green : Colors.transparent,
                      border: isDone
                          ? null
                          : Border.all(color: c.separator, width: 2),
                    ),
                    child: isDone
                        ? const Icon(Icons.check,
                            size: 16, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 14),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDone || isCurrent
                          ? c.textPrimary
                          : c.textSecondary,
                      fontWeight:
                          isCurrent ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }),
          const Spacer(flex: 3),
        ],
      ),
    ),
    );
  }
}
