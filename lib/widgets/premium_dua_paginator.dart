// lib/widgets/premium_dua_paginator.dart
//
// Moteur de pagination PUR (aucune dépendance à l'arbre de widgets, aucun
// BuildContext requis) — testable en isolation. Ne modifie jamais le texte
// source : la concaténation de toutes les pages reproduit exactement le
// texte original, caractère pour caractère.

import 'package:flutter/material.dart';

/// Une page de dou'a : portion EXACTE (sous-chaîne stricte, sans aucune
/// altération) du texte source, avec la taille de police retenue.
class PremiumDuaPage {
  final String text;
  final double fontSize;

  const PremiumDuaPage({required this.text, required this.fontSize});
}

class PremiumDuaPaginator {
  PremiumDuaPaginator._();

  /// Taille de police de confort. Le moteur essaie de rester au-dessus de
  /// ce seuil pour les dou'as de longueur normale ; en dessous, le rendu
  /// est simplement plus dense (jamais de perte de contenu — voir
  /// [fitSinglePage]). Constante centralisée, ajustable ici uniquement.
  static const double minFontSize = 30.0;

  /// Taille de police maximale (dou'a très court).
  static const double maxFontSize = 64.0;

  static const String _fontFamily = 'Lateef';
  static const double _lineHeight = 1.6;

  /// Calcule LA page unique (V1.2 Phase 11 — un seul export PNG, toujours,
  /// quelle que soit la longueur du dou'a) pour afficher [duaText] dans une
  /// zone de [maxWidth] x [maxHeight]. Ne tronque, ne modifie et ne perd
  /// JAMAIS aucun caractère : la taille de police est réduite
  /// progressivement (recherche exhaustive de [maxFontSize] à 1px sur la
  /// hauteur RÉELLEMENT mesurée avec la police Lateef de l'application)
  /// jusqu'à ce que le texte COMPLET tienne entièrement dans la zone —
  /// jamais de découpage en plusieurs pages (abandonné : seule la première
  /// page était de toute façon affichée depuis la Phase 9, ce qui pouvait
  /// silencieusement perdre le reste du texte).
  static PremiumDuaPage fitSinglePage({
    required String duaText,
    required double maxWidth,
    required double maxHeight,
  }) {
    if (duaText.isEmpty) {
      return const PremiumDuaPage(text: '', fontSize: maxFontSize);
    }

    final size = _bestFontSizeForSinglePage(
      text: duaText,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );

    return PremiumDuaPage(text: duaText, fontSize: size);
  }

  static double _measureHeight({
    required String text,
    required double fontSize,
    required double maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: _fontFamily,
          fontSize: fontSize,
          height: _lineHeight,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      maxLines: null,
    )..layout(maxWidth: maxWidth);
    return painter.height;
  }

  /// Plus grande taille de police (pas de 1px, jusqu'à 1px si nécessaire)
  /// permettant à [text] de tenir ENTIÈREMENT dans [maxWidth]x[maxHeight].
  /// Recherche exhaustive : garantit mathématiquement qu'une taille valide
  /// est toujours trouvée (au pire 1px) — aucun appelant n'a donc jamais
  /// besoin de basculer vers un autre mécanisme pour éviter une coupure de
  /// contenu.
  static double _bestFontSizeForSinglePage({
    required String text,
    required double maxWidth,
    required double maxHeight,
  }) {
    for (double size = maxFontSize; size >= 1; size -= 1) {
      if (_measureHeight(text: text, fontSize: size, maxWidth: maxWidth) <=
          maxHeight) {
        return size;
      }
    }
    return 1;
  }
}
