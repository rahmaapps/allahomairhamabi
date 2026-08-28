// lib/widgets/premium_export_card.dart

import 'package:flutter/material.dart';
import '../premium_templates.dart';
import 'premium_dua_paginator.dart';

class PremiumExportCard extends StatelessWidget {
  final PremiumTemplate template;
  final String duaText;

  const PremiumExportCard({
    super.key,
    required this.template,
    required this.duaText,
  });

  /// Construit LA page unique (toujours exactement une image — décision
  /// produit V1.2 Phase 9/11, quelle que soit la longueur du dou'a) pour
  /// [template]. Le texte est ajusté à la zone dédiée du template via
  /// [PremiumDuaPaginator.fitSinglePage] : recherche exhaustive de la plus
  /// grande taille de police (jusqu'à 1px si nécessaire) permettant au
  /// texte COMPLET de tenir dans la zone — aucune perte de contenu
  /// possible, aucun découpage en plusieurs pages. Fond, ornements, logo,
  /// titre, sous-titre et footer sont déjà intégrés graphiquement dans le
  /// template (assets/premium/templates/*.png) : rien d'autre à dessiner.
  static List<Widget> buildPages({
    required PremiumTemplate template,
    required String duaText,
  }) {
    final asset = template.fixedTemplateAsset;
    final size = template.fixedTemplateSize;
    final zone = template.duaTextZone;
    final zoneWidth = zone.width * size.width;
    final zoneHeight = zone.height * size.height;

    final page = PremiumDuaPaginator.fitSinglePage(
      duaText: duaText,
      maxWidth: zoneWidth,
      maxHeight: zoneHeight,
    );

    return [
      _FixedTemplateCard(
        asset: asset,
        size: size,
        zone: zone,
        pageText: page.text,
        fontSize: page.fontSize,
        textColor: template.duaTextColor,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return buildPages(template: template, duaText: duaText).first;
  }
}

/// Rendu pour les 3 templates Premium, dont le fond, les ornements, le
/// logo, le titre, le sous-titre et le footer sont déjà définitivement
/// intégrés dans une image validée graphiquement (voir
/// [PremiumTemplateX.fixedTemplateAsset]). Flutter ne dessine ici QUE le
/// texte du dou'a, positionné et dimensionné proportionnellement à la zone
/// vide de l'image — aucun élément graphique n'est régénéré ni dupliqué.
class _FixedTemplateCard extends StatelessWidget {
  final String asset;
  final Size size;
  final Rect zone; // fractions 0.0-1.0 de [size]
  final String pageText; // texte complet du dou'a (jamais tronqué)
  final double fontSize; // déjà déterminée par PremiumDuaPaginator
  final Color textColor; // dépend du contraste de la zone de CE template

  const _FixedTemplateCard({
    required this.asset,
    required this.size,
    required this.zone,
    required this.pageText,
    required this.fontSize,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final zoneWidth = zone.width * size.width;
    final zoneHeight = zone.height * size.height;

    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        children: [
          Image.asset(
            asset,
            width: size.width,
            height: size.height,
            fit: BoxFit.fill, // dimensions natives déjà correctes, aucune déformation
          ),
          Positioned(
            left: zone.left * size.width,
            top: zone.top * size.height,
            width: zoneWidth,
            height: zoneHeight,
            // Filet de sécurité : garantit qu'aucun débordement visuel ne
            // peut jamais sortir de la zone dédiée. Ne devrait jamais se
            // déclencher en pratique : fitSinglePage() garantit déjà que
            // le texte tient dans zoneWidth x zoneHeight.
            child: ClipRect(
              child: Center(
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    pageText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Lateef',
                      fontSize: fontSize,
                      color: textColor,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
