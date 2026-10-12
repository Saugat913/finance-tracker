import 'package:flutter/material.dart';

/// Raw design-system colors. Semantic theme roles belong in AppColors.
abstract final class AppPalette {
  // Brand: calm teal for a trustworthy, modern financial product.
  static const Color brand = Color(0xFF087F8C);
  static const Color brandHover = Color(0xFF066B75);
  static const Color brandPressed = Color(0xFF055861);
  static const Color brandSubtle = Color(0xFFE5F5F5);
  static const Color brandOn = Color(0xFFFFFFFF);

  // Neutral scale.
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF101820);
  static const Color neutral50 = Color(0xFFF8FAFB);
  static const Color neutral100 = Color(0xFFF0F3F5);
  static const Color neutral200 = Color(0xFFE1E7EA);
  static const Color neutral300 = Color(0xFFCCD5DA);
  static const Color neutral400 = Color(0xFFAAB7BE);
  static const Color neutral500 = Color(0xFF84939B);
  static const Color neutral600 = Color(0xFF62727B);
  static const Color neutral700 = Color(0xFF46565F);
  static const Color neutral800 = Color(0xFF2D3B43);
  static const Color neutral900 = Color(0xFF1B272E);
  static const Color neutral950 = Color(0xFF11191E);

  // Financial semantics.
  static const Color income = Color(0xFF16845B);
  static const Color incomeSubtle = Color(0xFFE6F5ED);
  static const Color expense = Color(0xFFC34242);
  static const Color expenseSubtle = Color(0xFFFCECEC);
  static const Color warning = Color(0xFF986300);
  static const Color warningSubtle = Color(0xFFFFF4D6);
  static const Color info = Color(0xFF2864B4);
  static const Color infoSubtle = Color(0xFFEAF2FF);
  static const Color success = Color(0xFF16845B);
  static const Color successSubtle = Color(0xFFE6F5ED);

  // Utility colors.
  static const Color transparent = Colors.transparent;
  static const Color scrim = Color(0x66000000);
  static const Color overlayLight = Color(0x0A101820);
  static const Color overlayDark = Color(0x14FFFFFF);
}
