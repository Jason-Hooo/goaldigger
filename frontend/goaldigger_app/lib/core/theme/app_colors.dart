import 'package:flutter/material.dart';

/// Brand palette shared across the app.
abstract final class AppColors {
  static const pinkPrimary = Color(0xFFF05A91);
  static const pinkSecondary = Color(0xFFFF9EBB);
  static const pinkSoft = Color(0xFFFFD3E3);
  static const surfaceSoft = Color(0xFFFFF6FA);
  static const ink = Color(0xFF3B2E32);
  static const inkLight = Color(0xFF8B6E79);
  static const green = Color(0xFF2FA678);

  /// Muted accent used for settled split states.
  static const settled = Color.fromARGB(255, 19, 16, 202);

  static const backgroundGradientStart = Color(0xFFFFE7F0);
  static const blobLight = Color(0xFFFFC7DA);
  static const blobSoft = Color(0xFFFFD9E8);
  static const blobDeep = Color(0xFFFFC0D6);
}
