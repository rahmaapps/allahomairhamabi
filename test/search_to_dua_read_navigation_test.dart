// Tests LOT 3.I — navigation Recherche → `DuaReadScreen` : le tap sur le
// contenu d'un résultat ouvre l'écran de lecture (transition RTL existante,
// non modifiée par ce lot — seul `DuaReadOrigin` a été retiré de l'appel).
// Au retour, la recherche est restaurée (comportement natif de `Navigator`,
// déjà garanti par construction).
//
// Un seul test réel par fichier (E/S réelle via
// `DuaRepository.getAllDuas()`) — voir
// grave_visit_read_screen_navigate_test.dart pour l'explication de cette
// contrainte.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:test_1/screens/dua_read_screen.dart';
import 'package:test_1/search_screen.dart';
import 'package:test_1/widgets/app_dua_result_card.dart';

Future<void> _waitForResults(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    // 300 ms couvre aussi le debounce de 250 ms de la recherche.
    await tester.pump(const Duration(milliseconds: 300));
    if (find.byType(AppDuaResultCard).evaluate().isNotEmpty) return;
  }
}

void main() {
  testWidgets(
      'tap sur le contenu d\'un résultat ouvre DuaReadScreen ; retour restaure la recherche',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MaterialApp(home: SearchScreen()));
    // Terme extrêmement fréquent (vérifié : ~1973 occurrences dans
    // assets/data/duas.json) — garantit au moins un résultat.
    await tester.enterText(find.byType(TextField), 'اللهم');
    await _waitForResults(tester);

    expect(find.byType(AppDuaResultCard), findsWidgets);

    await tester.tap(find.byType(AppDuaResultCard).first);
    await tester.pumpAndSettle();

    expect(find.byType(DuaReadScreen), findsOneWidget);

    final backButtonInReading = find.descendant(
      of: find.byType(DuaReadScreen),
      matching: find.byIcon(Icons.arrow_forward),
    );
    await tester.tap(backButtonInReading);
    await tester.pumpAndSettle();

    expect(find.byType(DuaReadScreen), findsNothing);
    expect(find.byType(SearchScreen), findsOneWidget);
    // Terme conservé — recherche intégralement restaurée (§B.1).
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, 'اللهم');
    expect(find.byType(AppDuaResultCard), findsWidgets);
  });
}
