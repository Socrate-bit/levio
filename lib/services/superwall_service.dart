import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:superwallkit_flutter/superwallkit_flutter.dart';

class SuperwallService {
  static const _iosApiKey = 'pk_H0nPpphGj3awY7K1T2ngX';
  static const _androidApiKey = 'pk_H0nPpphGj3awY7K1T2ngX';

  static void configure() {
    try {
      final apiKey = Platform.isIOS ? _iosApiKey : _androidApiKey;
      Superwall.configure(apiKey);
    } catch (e) {
      debugPrint('[SuperwallService] configure failed: $e');
    }
  }

  static Future<void> registerAppStart({bool skipPaywall = false}) async {
    if (skipPaywall) return;
    try {
      // await Superwall.shared.registerPlacement('app_start');star
    } catch (e) {
      debugPrint('[SuperwallService] registerPlacement failed: $e');
    }
  }
}
