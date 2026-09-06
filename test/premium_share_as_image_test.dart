// Tests Phase 9 (V1.2) puis LOT 2 (refonte HOME) : "Share as image".
//
// LOT 2 : le déclencheur n'est plus un bouton dans le corps de l'écran mais
// une icône unique de l'AppBar (§4 Partage Premium — « une seule icône ⤴ »,
// suppression du doublon icône+bouton bas). Localisé par son tooltip
// "مشاركة كصورة" plutôt que par un texte de bouton, qui n'existe plus.
//
// LIMITE DOCUMENTÉE : la capture réelle du PNG (_renderPremiumPng ->
// RenderRepaintBoundary.toImage()) et le partage via Share.shareXFiles ne
// sont PAS testés ici : `_sharePremiumImage()` appelle `share_plus` (canal
// de plateforme natif non mocké en flutter_test). Voir
// test/premium_dua_paginator_test.dart et les previews visuelles générées
// en Phase 11 pour la validation du rendu réel (fit-to-box, 3 templates).
// On teste donc uniquement ce qui est fiable sans dépendance de
// plateforme : présence de l'icône Export Premium, ouverture du sélecteur
// de template, et l'invariant structurel "une seule image" (un seul
// RepaintBoundary englobant un PremiumExportCard dans l'arbre — plus de
// Column/boucle multi-pages).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:test_1/home_screen.dart';
import 'package:test_1/widgets/premium_export_card.dart';

void main() {
  Future<void> pumpHome(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();
    // L'icône ⤴ n'est rendue que si un douʿā est réellement chargé
    // (`_currentId != null` — correctif HOME §4 Partage Premium). Le
    // chargement initial passe par une E/S réelle (`rootBundle.loadString`
    // via `DuaRepository`), qui ne se résout pas dans la zone async fictive
    // de `flutter_test` via `pumpAndSettle()` seul (même limitation que
    // documentée dans grave_visit_read_screen_navigate_test.dart) : on
    // sonde par petits pas jusqu'à apparition de l'icône, budget généreux
    // (plusieurs tests réels dans ce même fichier peuvent retarder la
    // résolution de la zone async fictive d'un test à l'autre).
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byTooltip('مشاركة كصورة').evaluate().isNotEmpty) break;
    }
  }

  // Les 3 vérifications ci-dessous partagent strictement le même `pumpHome`
  // (E/S réelle de chargement initial) : regroupées en un seul `testWidgets`
  // plutôt que 3, pour éviter la contamination de la zone async fictive de
  // `flutter_test` entre plusieurs tests réels d'un même fichier (déjà
  // rencontrée et documentée sur LOT 3.F — un second test dépendant de la
  // même E/S réelle dans le même fichier ne se résolvait pas de façon
  // fiable, même avec un budget de sondage généreux).
  testWidgets(
      'icône Export Premium (AppBar) : présence, ouverture du sélecteur, invariant une seule image',
      (tester) async {
    await pumpHome(tester);

    // icône "مشاركة كصورة" présente dans l'AppBar, "تقييم التطبيق" absent
    expect(find.byTooltip('مشاركة كصورة'), findsOneWidget);
    expect(find.text('تقييم التطبيق'), findsNothing);

    // exactement une seule PremiumExportCard préparée hors-écran — une
    // seule image doit toujours être préparée pour la capture, jamais une
    // liste/Column multi-pages (ancien mécanisme _exportKeys).
    expect(find.byType(PremiumExportCard), findsOneWidget);

    // tap sur l'icône "مشاركة كصورة" ouvre le sélecteur avec les 3 templates
    await tester.tap(find.byTooltip('مشاركة كصورة'));
    await tester.pumpAndSettle();

    expect(find.text('Dark Luxe'), findsOneWidget);
    expect(find.text('Emerald'), findsOneWidget);
    expect(find.text('White'), findsOneWidget);
  });
}
