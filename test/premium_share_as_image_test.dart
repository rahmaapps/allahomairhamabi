// Tests Phase 9 (V1.2) : "Share as image".
//
// LIMITE DOCUMENTÉE : la capture réelle du PNG (_renderPremiumPng ->
// RenderRepaintBoundary.toImage()) et le partage via Share.shareXFiles ne
// sont PAS testés ici : `_sharePremiumImage()` appelle `share_plus` (canal
// de plateforme natif non mocké en flutter_test). Voir
// test/premium_dua_paginator_test.dart et les previews visuelles générées
// en Phase 11 pour la validation du rendu réel (fit-to-box, 3 templates).
// On teste donc uniquement ce qui est fiable sans dépendance de
// plateforme : présence du bouton "مشاركة كصورة", absence de "تقييم
// التطبيق", ouverture du sélecteur de template, et l'invariant structurel
// "une seule image" (un seul RepaintBoundary englobant un PremiumExportCard
// dans l'arbre — plus de Column/boucle multi-pages).
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
  }

  group('Home — bouton Share as image (remplace تقييم التطبيق)', () {
    testWidgets('"مشاركة كصورة" est présent, "تقييم التطبيق" a disparu',
        (tester) async {
      await pumpHome(tester);

      expect(find.text('مشاركة كصورة'), findsOneWidget);
      expect(find.text('تقييم التطبيق'), findsNothing);
    });

    testWidgets('tap sur "مشاركة كصورة" ouvre le sélecteur avec les 3 templates',
        (tester) async {
      await pumpHome(tester);

      await tester.tap(find.text('مشاركة كصورة'));
      await tester.pumpAndSettle();

      expect(find.text('Dark Luxe'), findsOneWidget);
      expect(find.text('Emerald'), findsOneWidget);
      expect(find.text('White'), findsOneWidget);
    });
  });

  group('Home — invariant structurel "une seule image" (V1.2)', () {
    testWidgets('exactement une seule PremiumExportCard préparée hors-écran',
        (tester) async {
      await pumpHome(tester);

      expect(
        find.byType(PremiumExportCard),
        findsOneWidget,
        reason: 'une seule image doit toujours être préparée pour la capture, '
            'jamais une liste/Column multi-pages (ancien mécanisme _exportKeys)',
      );
    });
  });
}
