import 'package:flutter/services.dart';

class LedgerHaptics {
  LedgerHaptics._();

  /// Light tick when an entry is saved or selected
  static void tick() {
    HapticFeedback.lightImpact();
  }

  /// Double tick when an entry is deleted
  static Future<void> doubleTick() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.mediumImpact();
  }
}

