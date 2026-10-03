// Tests LOT 3.F — دعاء زيارة القبر : `GraveVisitReadScreen` pompé
// directement, sans passer par le parcours HOME (docs/ui_ux/
// ETAT_CONSOLIDE_UI_UX.md, §1/§4/§6.5). Vérifie l'absence de toute action
// interdite et de toute attribution une fois le douʿā chargé.
//
// Isolé dans son propre fichier — voir l'en-tête de
// `grave_visit_read_screen_navigate_test.dart` pour l'explication (un seul
// test par fichier nécessitant une E/S réelle, pour éviter la contamination
// de la zone async fictive entre tests d'un même fichier/process).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:test_1/screens/grave_visit_read_screen.dart';

Future<void> _waitForRealAsyncLoad(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 50));
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) return;
  }
}

void main() {
  testWidgets(
      'aucune action interdite (copie/partage/favori/دعاء آخر), aucune attribution, retour présent',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      const MaterialApp(home: GraveVisitReadScreen(personKey: 'father')),
    );
    await _waitForRealAsyncLoad(tester);

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.copy), findsNothing);
    expect(find.byIcon(Icons.share), findsNothing);
    expect(find.byIcon(Icons.favorite), findsNothing);
    expect(find.byIcon(Icons.favorite_border), findsNothing);
    expect(find.textContaining('دعاء آخر'), findsNothing);
    expect(find.textContaining('رواه مسلم'), findsNothing);

    // Navigation retour présente, seule affordance de l'AppBar.
    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
  });
}
