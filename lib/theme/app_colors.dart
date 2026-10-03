import 'package:flutter/material.dart';

/// Tokens de couleur — Design System Phase 2 (docs/ui_ux/ETAT_CONSOLIDE_UI_UX.md, §3).
/// Valeurs figées ; ne pas en inventer de nouvelles ici.
class AppColorsLight {
  const AppColorsLight._();

  static const Color bg = Color(0xFFFFFBF1);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFFFF6E7);
  static const Color surfaceMuted = Color(0xFFF4F7F4);
  static const Color primary = Color(0xFF006A4E);
  static const Color primaryPressed = Color(0xFF00563F);
  static const Color primaryContainer = Color(0xFFE4F0EA);
  static const Color onPrimary = Color(0xFFFFFBF1);
  static const Color secondary = Color(0xFF009F6B);
  static const Color goldText = Color(0xFF8A6508);
  static const Color goldLine = Color(0xFFD4AF37);
  static const Color textPrimary = Color(0xFF1E2A24);
  static const Color textSecondary = Color(0xFF5C6B63);
  static const Color textDisabled = Color(0xFFA79F8E);
  static const Color border = Color(0xFFEADFC8);
  static const Color borderStrong = Color(0xFFC9C2B2);
  static const Color disabledBg = Color(0xFFEFEADF);
  static const Color success = Color(0xFF2E7D5B);
  static const Color error = Color(0xFFA63A2E);
  static const Color scrim = Color(0x731E2A24); // rgba(30,42,36,.45)
}

class AppColorsDark {
  const AppColorsDark._();

  static const Color bg = Color(0xFF101A16);
  static const Color surface = Color(0xFF18241F);
  static const Color surfaceAlt = Color(0xFF20302A);
  static const Color appBar = Color(0xFF0C1512);
  static const Color bandVisite = Color(0xFF132019);
  static const Color primary = Color(0xFF009F6B);
  static const Color onPrimary = Color(0xFF062018);
  static const Color accent = Color(0xFF25C4A5);
  static const Color gold = Color(0xFFE3C570);
  static const Color textPrimary = Color(0xFFF3EEE1);
  static const Color textSecondary = Color(0xFFA6B2AA);
  static const Color textDisabled = Color(0xFF6B7872);
  static const Color border = Color(0xFF2C3C35);
  static const Color success = Color(0xFF4EBF92);
  static const Color error = Color(0xFFE08472);
  static const Color scrim = Color(0x9E060E0B); // rgba(6,14,11,.62)
}

/// Ombres teintées vert `rgba(0,58,42,α)` — communes Light/Dark (§3).
class AppShadowTint {
  const AppShadowTint._();
  static const Color base = Color(0xFF003A2A);
}
