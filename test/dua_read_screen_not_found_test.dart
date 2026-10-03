// Tests LOT 3.I — `DuaReadScreen` : état « douʿā introuvable ». Doit
// afficher `AppEmptyState`, jamais un écran blanc (§B.8).
//
// Un seul test réel par fichier (E/S réelle via `DuaRepository`) — voir
// grave_visit_read_screen_navigate_test.dart pour l'explication de cette
// contrainte.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:test_1/screens/dua_read_screen.dart';
import 'package:test_1/widgets/app_empty_state.dart';

Future<void> _waitForRealAsyncLoad(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 50));
    if (find.byType(AppEmptyState).evaluate().isNotEmpty) return;
  }
}

void main() {
  testWidgets('douʿā introuvable affiche AppEmptyState, jamais un écran blanc',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    // Aucun douʿā ne porte un id négatif dans assets/data/duas.json.
    await tester.pumpWidget(const MaterialApp(home: DuaReadScreen(duaId: -1)));
    await _waitForRealAsyncLoad(tester);

    expect(find.byType(AppEmptyState), findsOneWidget);
    // Le retour reste disponible même dans cet état.
    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
  });
}
