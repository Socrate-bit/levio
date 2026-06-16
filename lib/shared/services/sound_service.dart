import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../../features/subscription/services/analytics_service.dart';

/// Central sound service for the app.
///
/// Usage: `SoundService.instance.playRepBell()`
class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _repPlayer = AudioPlayer();

  Future<void> init() async {
    await _repPlayer.setReleaseMode(ReleaseMode.stop);
    await _repPlayer.setSource(AssetSource('sounds/bell.mp3'));
  }

  /// Plays the bell sound on each validated rep.
  Future<void> playRepBell() async {
    try {
      await _repPlayer.stop();
      await _repPlayer.play(AssetSource('sounds/bell.mp3'));
    } catch (e, st) {
      debugPrint('[SoundService] playRepBell error: $e');
      AnalyticsService.trackError('SoundService.playRepBell', e, st);
    }
  }

  Future<void> dispose() async {
    await _repPlayer.dispose();
  }
}
