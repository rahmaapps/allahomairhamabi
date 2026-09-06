// Tests LOT 3.I — `DuaReadScreen` : carte de lecture agrandie, pompée
// directement avec un id réel de assets/data/duas.json (père, catégorie
// normale — voir home_person_selection_integration_test.dart : ids=139 pour
// persons=[father]).
//
// Un seul test réel par fichier (E/S réelle via `DuaRepository`) — voir
// grave_visit_read_screen_navigate_test.dart pour l'explication de cette
// contrainte (contamination de la zone async fictive entre tests réels d'un
// même fichier/process).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:test_1/screens/dua_read_screen.dart';
import 'package:test_1/widgets/app_bar.dart';
import 'package:test_1/widgets/app_card.dart';

Future<void> _waitForRealAsyncLoad(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 50));
    if (find.byType(AppCard).evaluate().isNotEmpty) return;
  }
}

void main() {
  testWidgets(
      'AppBar sans titre, ♥ absent de l\'AppBar et présent dans la carte, aucun loading',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MaterialApp(home: DuaReadScreen(duaId: 139)));

    // Avant même la résolution du Future : aucun indicateur de chargement
    // (§B.8 — le `CircularProgressIndicator` est explicitement retiré).
    expect(find.byType(CircularProgressIndicator), findsNothing);

    await _waitForRealAsyncLoad(tester);

    // AppBar : uniquement le retour, aucun titre, aucune action (§A.1).
    final appBar = tester.widget<AppTopBar>(find.byType(AppTopBar));
    expect(appBar.title, isNull);
    expect(appBar.actions, isNull);
    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);

    // Carte de lecture : un seul ♥, dans la carte — jamais dans l'AppBar.
    expect(find.byType(AppCard), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsNothing);

    // Actions basses.
    expect(find.text('نسخ'), findsOneWidget);
    expect(find.text('مشاركة'), findsOneWidget);
  });
}
