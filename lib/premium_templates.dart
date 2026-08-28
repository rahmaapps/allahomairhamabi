// lib/premium_templates.dart
import 'package:flutter/material.dart';

enum PremiumTemplate { darkLuxe, emerald, whiteElegant }

extension PremiumTemplateX on PremiumTemplate {
  String get thumbAsset {
    switch (this) {
      case PremiumTemplate.darkLuxe:
        return 'assets/premium/previews/dark_luxe_thumb.png';
      case PremiumTemplate.emerald:
        return 'assets/premium/previews/emerald_thumb.png';
      case PremiumTemplate.whiteElegant:
        return 'assets/premium/previews/white_elegant_thumb.png';
    }
  }

  String get displayName {
    switch (this) {
      case PremiumTemplate.darkLuxe:
        return 'Dark Luxe';
      case PremiumTemplate.emerald:
        return 'Emerald';
      case PremiumTemplate.whiteElegant:
        return 'White';
    }
  }

  /// Image de fond FIXE et validée (fond, ornements, logo, titre, sous-titre,
  /// cadre, footer déjà intégrés). V1.2 Phase 11 : les 3 templates Premium
  /// utilisent désormais uniformément ce système — PremiumExportCard ne
  /// dessine plus jamais rien d'autre que le texte du dou'a, dans la zone
  /// dédiée ci-dessous ([duaTextZone]). L'ancien rendu dynamique (fond +
  /// logo + texte + footer recomposés par Flutter) est abandonné.
  ///
  /// ⚠️ dark_luxe.png est un asset déjà validé visuellement : ne jamais le
  /// régénérer, retoucher ni modifier ses dimensions/zone (V1.2 Phase 11).
  String get fixedTemplateAsset {
    switch (this) {
      case PremiumTemplate.darkLuxe:
        return 'assets/premium/templates/dark_luxe.png';
      case PremiumTemplate.emerald:
        return 'assets/premium/templates/emerald.png';
      case PremiumTemplate.whiteElegant:
        return 'assets/premium/templates/white_elegant.png';
    }
  }

  /// Dimensions natives réelles de [fixedTemplateAsset].
  Size get fixedTemplateSize {
    switch (this) {
      case PremiumTemplate.darkLuxe:
        return const Size(1086, 1448);
      case PremiumTemplate.emerald:
        return const Size(1183, 1330);
      case PremiumTemplate.whiteElegant:
        return const Size(1086, 1448);
    }
  }

  /// Zone (fractions 0.0-1.0 de [fixedTemplateSize]) où positionner le texte
  /// du dou'a — correspond au cadre vide déjà présent dans l'image validée.
  /// Dark Luxe : valeur historique inchangée. Emerald/White Elegant :
  /// déterminées par analyse de pixels du template réel (détection de la
  /// zone claire intérieure, avec marge de sécurité vérifiée visuellement
  /// pour ne jamais chevaucher bordure/ornements/footer — V1.2 Phase 11).
  Rect get duaTextZone {
    switch (this) {
      case PremiumTemplate.darkLuxe:
        return const Rect.fromLTRB(0.16, 0.39, 0.84, 0.74);
      case PremiumTemplate.emerald:
        return const Rect.fromLTRB(0.15, 0.33, 0.85, 0.87);
      case PremiumTemplate.whiteElegant:
        return const Rect.fromLTRB(0.16, 0.31, 0.84, 0.84);
    }
  }

  /// Couleur du texte du dou'a dessiné dans [duaTextZone] — dépend du
  /// contraste réel de la zone intérieure de CE template (découvert lors
  /// de l'implémentation V1.2 Phase 11 : Emerald et White Elegant ont une
  /// zone de texte claire/ivoire, contrairement à Dark Luxe dont la zone
  /// est sombre — un texte blanc y serait illisible). Couleurs alignées
  /// sur celle du titre déjà imprimé dans chaque template.
  Color get duaTextColor {
    switch (this) {
      case PremiumTemplate.darkLuxe:
        return Colors.white;
      case PremiumTemplate.emerald:
        return const Color(0xFF163B2C);
      case PremiumTemplate.whiteElegant:
        return const Color(0xFF2A2118);
    }
  }
}
