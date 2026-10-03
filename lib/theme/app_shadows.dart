import 'package:flutter/material.dart';

/// Niveaux d'ombre — Design System Phase 2 (§3).
/// `e0` est un trait 1 px, pas une ombre portée : voir [AppShadows.e0Border].
/// `e2` est le privilège exclusif du contenu sacré (carte du HOME, lecture,
/// sheet de partage) — ce lot ne l'applique à aucun écran, il le met
/// seulement à disposition.
class AppShadows {
  const AppShadows._();

  static List<BoxShadow> get e1 => const [
        BoxShadow(
          color: Color(0x12003A2A), // rgba(0,58,42,.07)
          offset: Offset(0, 1),
          blurRadius: 3,
        ),
      ];

  static List<BoxShadow> get e2 => const [
        BoxShadow(
          color: Color(0x1A003A2A), // rgba(0,58,42,.10)
          offset: Offset(0, 6),
          blurRadius: 20,
        ),
      ];

  static List<BoxShadow> get e3 => const [
        BoxShadow(
          color: Color(0x29003A2A), // rgba(0,58,42,.16)
          offset: Offset(0, 12),
          blurRadius: 34,
        ),
      ];

  /// `e0` : trait 1 px, à utiliser comme `Border.all(color: ..., width: 1)`.
  static const double e0BorderWidth = 1;
}
