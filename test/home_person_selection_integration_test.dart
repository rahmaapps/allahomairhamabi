// LOT 2 — vérification explicite du retour HOME <- PersonSelectionScreen :
// la ligne « pour qui » doit refléter personsData après réouverture, et le
// callback existant (reload + reset/rebuild du deck) ne doit pas régresser.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:test_1/home_screen.dart';
import 'package:test_1/screens/person_selection_screen.dart';
import 'package:test_1/widgets/app_chip.dart';

void main() {
  testWidgets(
      'retour depuis PersonSelectionScreen recharge personsData et met à jour la ligne « pour qui »',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    // Aucune personne sélectionnée au départ.
    expect(find.textContaining('ادعُ لمن تحب'), findsOneWidget);
    expect(find.text('اختيار'), findsOneWidget);

    // Ouvrir Person Selection via la ligne « pour qui ».
    await tester.tap(find.text('اختيار'));
    await tester.pumpAndSettle();
    expect(find.byType(PersonSelectionScreen), findsOneWidget);

    // Sélectionner « الأب ».
    await tester.tap(find.widgetWithText(AppChip, 'أبي'));
    await tester.pump();

    // Revenir au HOME via la flèche de retour.
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pumpAndSettle();

    expect(find.byType(PersonSelectionScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.textContaining('تدعو لـ أبي'), findsOneWidget);
    expect(find.text('تغيير'), findsOneWidget);
  });

  testWidgets(
      'le snackbar تراجع d\'un décochage ne survit pas au retour au HOME',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('اختيار'));
    await tester.pumpAndSettle();
    expect(find.byType(PersonSelectionScreen), findsOneWidget);

    // Coche puis décoche « الأب » — le décochage déclenche le snackbar
    // تراجع (durée 6 s).
    await tester.tap(find.widgetWithText(AppChip, 'أبي'));
    await tester.pump();
    await tester.tap(find.widgetWithText(AppChip, 'أبي'));
    await tester.pump();
    expect(find.text('تراجع'), findsOneWidget);

    // Retour immédiat au HOME, bien avant l'expiration du snackbar.
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pumpAndSettle();

    expect(find.byType(PersonSelectionScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    // Le snackbar ne doit pas avoir "fuité" sur le ScaffoldMessenger racine
    // partagé par toute l'app.
    expect(find.text('تراجع'), findsNothing);
  });
}
