// Tests LOT 3.I — navigation Favoris → `DuaReadScreen` : le tap sur le
// contenu de la carte ouvre l'écran de lecture, le ♥ de Favoris reste une
// cible indépendante, et retirer le favori depuis l'écran de lecture
// resynchronise la liste au retour (§B.2).
//
// Un seul test réel par fichier (E/S réelle via
// `DuaRepository.getAllDuas()`) — voir
// grave_visit_read_screen_navigate_test.dart pour l'explication de cette
// contrainte.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:test_1/favorites_screen.dart';
import 'package:test_1/screens/dua_read_screen.dart';
import 'package:test_1/widgets/app_dua_result_card.dart';
import 'package:test_1/widgets/app_empty_state.dart';

Future<void> _waitForLoad(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 50));
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) return;
  }
}

void main() {
  testWidgets(
      'tap sur le contenu ouvre DuaReadScreen ; retirer le ♥ en lecture resynchronise la liste au retour',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'flutter.favorite_dua_ids': <String>['139'],
    });

    await tester.pumpWidget(const MaterialApp(home: FavoritesScreen()));
    await _waitForLoad(tester);

    expect(find.byType(AppDuaResultCard), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsOneWidget);

    // Tap sur le contenu de la carte (pas sur le ♥) → DuaReadScreen.
    await tester.tap(find.byType(AppDuaResultCard));
    await tester.pumpAndSettle();

    expect(find.byType(DuaReadScreen), findsOneWidget);

    // Le ♥ dans l'écran de lecture est bien celui de DuaReadScreen (scope
    // explicite : la carte Favoris sous-jacente porte, elle aussi, une
    // icône `Icons.favorite`, toujours montée sous la route poussée).
    final heartInReading = find.descendant(
      of: find.byType(DuaReadScreen),
      matching: find.byIcon(Icons.favorite),
    );
    expect(heartInReading, findsOneWidget);

    await tester.tap(heartInReading);
    await tester.pump();

    expect(
      find.descendant(
        of: find.byType(DuaReadScreen),
        matching: find.byIcon(Icons.favorite_border),
      ),
      findsOneWidget,
    );

    // Retour vers Favoris.
    final backButtonInReading = find.descendant(
      of: find.byType(DuaReadScreen),
      matching: find.byIcon(Icons.arrow_forward),
    );
    await tester.tap(backButtonInReading);
    await tester.pumpAndSettle();
    await _waitForLoad(tester);

    // Liste resynchronisée : l'unique favori a été retiré depuis la
    // lecture, la liste doit maintenant être vide.
    expect(find.byType(DuaReadScreen), findsNothing);
    expect(find.byType(FavoritesScreen), findsOneWidget);
    expect(find.byType(AppDuaResultCard), findsNothing);
    expect(find.byType(AppEmptyState), findsOneWidget);
  });
}
