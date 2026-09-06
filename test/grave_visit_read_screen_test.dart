// Tests LOT 3.F — دعاء زيارة القبر (docs/ui_ux/ETAT_CONSOLIDE_UI_UX.md, §1/§4/
// §6.5 + arbitrages du LOT). Parcours : HOME → bandeau → bottom sheet (choix
// explicite de la personne, limité à `personsData`) → écran de lecture
// dédié, sans sélecteur ni chip de personne dans l'écran lui-même.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:test_1/home_screen.dart';
import 'package:test_1/screens/grave_visit_read_screen.dart';
import 'package:test_1/screens/person_selection_screen.dart';
import 'package:test_1/widgets/app_bar.dart';
import 'package:test_1/widgets/app_button.dart';
import 'package:test_1/widgets/app_chip.dart';

// Les tests qui attendent le contenu réellement chargé par le
// `FutureBuilder` de `GraveVisitReadScreen` (E/S réelle via
// `rootBundle.loadString`) sont dans le fichier séparé
// `grave_visit_read_screen_content_test.dart` — voir son en-tête pour
// l'explication (isolation de process/zone async fictive).

void main() {
  group('دعاء زيارة القبر — parcours HOME → choix personne → lecture (LOT 3.F)', () {
    testWidgets(
        'tap sur le bandeau ouvre le bottom sheet avec les personnes configurées',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'flutter.persons_data': '{"father":"","mother":""}',
      });

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(AppVisitBandeau));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppChip, 'أبي'), findsOneWidget);
      expect(find.widgetWithText(AppChip, 'أمي'), findsOneWidget);
    });

    testWidgets('personsData vide affiche AppEmptyState dans la feuille, bandeau toujours visible',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(AppVisitBandeau), findsOneWidget);

      await tester.tap(find.byType(AppVisitBandeau));
      await tester.pumpAndSettle();

      expect(find.text('اختر الشخص الذي تريد قراءة الدعاء عند زيارة قبره'), findsOneWidget);
      expect(find.text('لم تختر شخصًا بعد'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'اختيار شخص'), findsOneWidget);
    });

    testWidgets('bouton اختيار شخص ferme la feuille et ouvre PersonSelectionScreen (jamais l\'écran de lecture)',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(AppVisitBandeau));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(AppButton, 'اختيار شخص'));
      await tester.pumpAndSettle();

      expect(find.byType(PersonSelectionScreen), findsOneWidget);
      expect(find.byType(GraveVisitReadScreen), findsNothing);
    });
  });
}
