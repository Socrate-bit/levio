import 'package:flutter/material.dart';

import '../../../shared/theme/app_theme.dart';

class LoadingStep extends StatefulWidget {
  final VoidCallback onComplete;

  const LoadingStep({super.key, required this.onComplete});

  @override
  State<LoadingStep> createState() => _LoadingStepState();
}

class _LoadingStepState extends State<LoadingStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progressAnimation;

  static const _steps = [
    'Analyzing your sleep habits',
    'Configuring your goals',
    'Setting your mission',
    'Calibrating alarm tone',
    'Scheduling your alarm',
    'Finalizing your plan',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7500),
    );
    _progressAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _completedCount(double progress) {
    return (progress * _steps.length).floor().clamp(0, _steps.length);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return PopScope(
      canPop: false,
      child: AnimatedBuilder(
        animation: _progressAnimation,
        builder: (context, _) {
          final progress = _progressAnimation.value;
          final percent = (progress * 100).round();
          final completed = _completedCount(progress);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 2),
                Text(
                  '$percent%',
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: c.separator,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.orange),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 32),
                ...List.generate(_steps.length, (i) {
                  final done = i < completed;
                  final active = i == completed && completed < _steps.length;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: done
                              ? Icon(Icons.check_circle,
                                  size: 22, color: AppColors.orange)
                              : active
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                                AppColors.orange),
                                      ),
                                    )
                                  : Icon(Icons.circle_outlined,
                                      size: 22, color: c.separator),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _steps[i],
                          style: TextStyle(
                            fontSize: 16,
                            color: done || active
                                ? c.textPrimary
                                : c.textSecondary,
                            fontWeight:
                                active ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const Spacer(flex: 3),
              ],
            ),
          );
        },
      ),
    );
  }
}
