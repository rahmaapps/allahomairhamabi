// Tests Phase 9 (V1.2) puis LOT 2 (refonte HOME) : "Share as image".
// LOT 3.L : la persistance du template sélectionné (§4 Partage Premium —
// « Persistée (share_template) ») est testée séparément, dans
// test/premium_share_template_persistence_test.dart — isolée de ce fichier
// pour éviter toute contamination du cache `UserPrefs._sp` (singleton) par
// le `testWidgets` ci-dessous, qui exerce déjà `UserPrefs.instance` via
// `HomeScreen` avant que des tests `share_template` dédiés ne puissent
// repartir d'un `SharedPreferences.setMockInitialValues` propre (même
// précaution déjà appliquée par `user_prefs_migration_test.dart`, fichier
// séparé lui aussi).
//
// LOT 2 : le déclencheur n'est plus un bouton dans le corps de l'écran mais
// une icône unique de l'AppBar (§4 Partage Premium — « une seule icône ⤴ »,
// suppression du doublon icône+bouton bas). Localisé par son tooltip
// "مشاركة كصورة" plutôt que par un texte de bouton — jusqu'au LOT 3.L, où
// un bouton "مشاركة كصورة" réapparaît, mais DANS la feuille (déclencheur
// de partage, distinct de l'icône d'AppBar qui ouvre la feuille).
//
// LOT 3.L (alignement littéral §4) : la sélection d'une vignette ne
// déclenche plus le partage — elle persiste seulement le template
// (`share_template`) et laisse la feuille ouverte. Un bouton d'action
// unique ("مشاركة كصورة", dans la feuille) déclenche ensuite la
// génération/partage. Testé ici : la sélection ne ferme pas la feuille,
// le bouton est présent, et la persistance est effective au niveau
// widget complet (pas seulement au niveau `UserPrefs`, déjà couvert par
// test/premium_share_template_persistence_test.dart).
//
// LIMITE DOCUMENTÉE (inchangée par LOT 3.L, déplacée du tap-vignette au
// tap-bouton) : la capture réelle du PNG (_renderPremiumPng ->
// RenderRepaintBoundary.toImage()) et le partage via Share.shareXFiles ne
// sont PAS testés ici : `_sharePremiumImage()` appelle `share_plus` (canal
// de plateforme natif non mocké en flutter_test), et `boundary.toImage()`
// ne se résout pas dans la zone async fictive de `flutter_test` sans
// `tester.runAsync()` enveloppant l'intégralité de l'interaction bouton
// (vérifié empiriquement pendant ce lot : un blocage réel de plusieurs
// minutes a été rencontré et corrigé sur un cas isolé similaire, voir
// docs/V1.2_PROGRESS.md — non reproduit ici sans justification suffisante).
// Ni la préparation (400 ms), ni le succès réel, ni l'échec réel ne sont
// donc exercés par tap ici. Voir test/premium_dua_paginator_test.dart et
// les previews visuelles générées en Phase 11 pour la validation du rendu
// réel (fit-to-box, 3 templates).
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // RenderRepaintBoundary
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:test_1/home_screen.dart';
import 'package:test_1/premium_templates.dart';
import 'package:test_1/user_prefs.dart';
import 'package:test_1/widgets/app_button.dart';
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

    // LOT 3.L : le RenderRepaintBoundary qui enveloppe directement
    // PremiumExportCard doit être layouté à la taille EXACTE du template
    // (template.fixedTemplateSize), pas à la taille de l'écran de test —
    // régression de la correction OverflowBox (avant elle, le SizedBox
    // interne était clampé par les contraintes loose héritées du Stack
    // racine). Vérification par layout seul (pas de toImage()), donc sans
    // les limitations documentées plus haut sur la zone async fictive.
    //
    // `find.ancestor` remonte TOUS les RepaintBoundary ancêtres (dont ceux
    // insérés ailleurs par le framework, ex. MaterialApp/Scaffold) — on
    // remonte donc l'arbre de rendu depuis PremiumExportCard pour ne
    // prendre que le plus proche, celui qui l'enveloppe réellement
    // (`_exportKey` dans home_screen.dart).
    RenderObject? node = tester.renderObject(find.byType(PremiumExportCard));
    while (node != null && node is! RenderRepaintBoundary) {
      node = node.parent;
    }
    expect(node, isA<RenderRepaintBoundary>());
    final boundary = node as RenderRepaintBoundary;
    expect(boundary.size, PremiumTemplate.darkLuxe.fixedTemplateSize);

    // tap sur l'icône "مشاركة كصورة" ouvre le sélecteur avec les 3 templates
    await tester.tap(find.byTooltip('مشاركة كصورة'));
    await tester.pumpAndSettle();

    expect(find.text('Dark Luxe'), findsOneWidget);
    expect(find.text('Emerald'), findsOneWidget);
    expect(find.text('White'), findsOneWidget);

    // Bouton d'action unique présent dès l'ouverture (LOT 3.L) — Dark Luxe
    // étant déjà le template par défaut, rien n'empêche de partager
    // immédiatement sans sélectionner explicitement une vignette.
    expect(find.widgetWithText(AppButton, 'مشاركة كصورة'), findsOneWidget);

    // Sélectionner Emerald : persiste le template MAIS ne ferme pas la
    // feuille et ne déclenche rien (§4, alignement littéral LOT 3.L).
    await tester.tap(find.text('Emerald'));
    await tester.pump();

    // La feuille est toujours ouverte : les 3 templates et le bouton sont
    // toujours là.
    expect(find.text('Dark Luxe'), findsOneWidget);
    expect(find.text('Emerald'), findsOneWidget);
    expect(find.text('White'), findsOneWidget);
    expect(find.widgetWithText(AppButton, 'مشاركة كصورة'), findsOneWidget);

    // Persistance effective au niveau widget complet (pas seulement
    // UserPrefs isolément) : share_template = 'emerald'.
    final saved = await UserPrefs.instance.getShareTemplate();
    expect(saved, 'emerald');
  });
}
