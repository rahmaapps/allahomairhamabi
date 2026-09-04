import 'package:flutter/material.dart';

/// Rôles typographiques — Design System Phase 2 (§3).
///
/// Deux polices, jamais une troisième, toutes deux embarquées localement
/// (assets `.ttf` déclarés dans `pubspec.yaml`, aucun téléchargement runtime) :
/// - `Lateef` : uniquement le texte du douʿā, le titre de l'app, la phrase
///   d'accroche des états vides, et les heures.
/// - `IBM Plex Sans Arabic` : le reste de l'interface.
///
/// Les styles n'embarquent pas de couleur : la couleur vient des tokens
/// [AppColorsLight]/[AppColorsDark] appliqués par l'appelant ou par le thème.
class AppTypography {
  const AppTypography._();

  static const String plexFamily = 'IBMPlexSansArabic';
  static const String lateefFamily = 'Lateef';

  static TextStyle _plex({
    required double fontSize,
    required FontWeight fontWeight,
    required double height,
  }) =>
      TextStyle(
        fontFamily: plexFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: 0,
      );

  static TextStyle _lateef({
    required double fontSize,
    required FontWeight fontWeight,
    required double height,
  }) =>
      TextStyle(
        fontFamily: lateefFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: 0,
      );

  static TextStyle get display =>
      _lateef(fontSize: 34, fontWeight: FontWeight.w400, height: 1.35);

  static TextStyle get screenTitle =>
      _plex(fontSize: 20, fontWeight: FontWeight.w600, height: 1.50);

  static TextStyle get sectionTitle =>
      _plex(fontSize: 16, fontWeight: FontWeight.w600, height: 1.50);

  /// Interligne ≥ 2.0 non négociable (§3).
  static TextStyle get duaBody =>
      _lateef(fontSize: 29, fontWeight: FontWeight.w400, height: 2.05);

  static TextStyle get duaLong =>
      _lateef(fontSize: 31, fontWeight: FontWeight.w400, height: 2.15);

  static TextStyle get duaCompact =>
      _lateef(fontSize: 22, fontWeight: FontWeight.w400, height: 1.85);

  static TextStyle get body =>
      _plex(fontSize: 15, fontWeight: FontWeight.w400, height: 1.75);

  static TextStyle get bodyStrong =>
      _plex(fontSize: 15, fontWeight: FontWeight.w600, height: 1.50);

  static TextStyle get button =>
      _plex(fontSize: 16, fontWeight: FontWeight.w600, height: 1.20);

  static TextStyle get chip =>
      _plex(fontSize: 14, fontWeight: FontWeight.w500, height: 1.20);

  static TextStyle get label =>
      _plex(fontSize: 12, fontWeight: FontWeight.w500, height: 1.40);
}
