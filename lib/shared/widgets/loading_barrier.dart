import 'package:flutter/material.dart';

/// Full-screen translucent barrier with a centered spinner. Place as a
/// [Positioned.fill] child of a [Stack] above page content while an async
/// action runs — it blocks interaction and disappears with its host screen.
class LoadingBarrier extends StatelessWidget {
  const LoadingBarrier({super.key});

  @override
  Widget build(BuildContext context) {
    // Opaque gesture detector swallows taps on the content underneath.
    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: const Color(0x66000000),
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
