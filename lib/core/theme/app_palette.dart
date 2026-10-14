import 'dart:ui';

/// Raw colour tokens sampled from the "Finance Planner" design. Nothing in the
/// UI reads these directly: they feed `AppColorScheme`, and widgets read the
/// resulting `ColorScheme` / `AppColors`. Swapping a token re-themes the app.
abstract final class AppPalette {
  // Light
  static const lightPage = Color(0xFFF6F6F6);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightInk = Color(0xFF121816);
  static const lightMuted = Color(0xFF7A827E);
  static const lightHairline = Color(0xFFE6E8E7);
  static const lightFill = Color(0xFFEDEEED); // tab tracks, input fills

  // Dark
  static const darkPage = Color(0xFF0D110F);
  static const darkCard = Color(0xFF171C19);
  static const darkInk = Color(0xFFF1F4F2);
  static const darkMuted = Color(0xFF8B9690);
  static const darkHairline = Color(0xFF262D29);
  static const darkFill = Color(0xFF212823);

  // Hero card (the near-black "Net position" card)
  static const lightHero = Color(0xFF121816);
  static const darkHero = Color(0xFF1F2823);

  // Semantic
  static const lightGreen = Color(0xFF1F7A45);
  static const darkGreen = Color(0xFF4CC38A);
  static const lightRed = Color(0xFFB42318);
  static const darkRed = Color(0xFFF2766B);
  static const lightAmber = Color(0xFF9A5B00);
  static const darkAmber = Color(0xFFF0B24A);
  static const lightAmberBg = Color(0xFFFFF1D6);
  static const darkAmberBg = Color(0xFF3A2C10);
  static const lightGreenBg = Color(0xFFE3F3EA);
  static const darkGreenBg = Color(0xFF16301F);
  static const sparkline = Color(0xFF5EE6A0);
}
