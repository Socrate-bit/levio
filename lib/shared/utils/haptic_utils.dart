import 'package:flutter/services.dart';

/// Wraps a [VoidCallback] to fire light haptic feedback before executing.
VoidCallback? withHaptic(VoidCallback? callback) {
  if (callback == null) return null;
  return () {
    HapticFeedback.lightImpact();
    callback();
  };
}

/// Wraps a [ValueChanged<T>] to fire light haptic feedback before executing.
ValueChanged<T>? withHapticValue<T>(ValueChanged<T>? callback) {
  if (callback == null) return null;
  return (T value) {
    HapticFeedback.lightImpact();
    callback(value);
  };
}
