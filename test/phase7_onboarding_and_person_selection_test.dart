// Tests Phase 7 (V1.2) : SafeArea du bouton "حفظ" (BUG-002) et
// synchronisation du chip résumé (BUG-003, y compris au rechargement avec
// des personnes déjà enregistrées).
//
// NOTE — suppression du champ nom de l'onboarding (settings_screen.dart) :
// non couverte par un test widget ici. SettingsScreen._bootstrap() appelle
// NotificationService.ensureInitialized() (canal de plateforme natif) avant
// même de charger les préférences ; en environnement flutter_test sans mock
// de plateforme, cet appel ne se résout jamais et _loadPrefs() ne démarre
// donc jamais — limitation déjà documentée pour cet écran dans
// test/widget_test.dart ("contrairement à '/settings' ... pas mockable dans
// un simple flutter_test sans mocking de plateforme"). La suppression du
// champ est validée par revue de code + `flutter analyze`/`flutter test`
// (aucune référence résiduelle à _personName/_personNameController/
// savePersonName/getPersonName — vérifié par grep exhaustif avant
// suppression), pas par un test automatisé.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:test_1/screens/person_selection_screen.dart';

void main() {
  group('Person Selection — SafeArea du bouton "حفظ" (BUG-002)', () {
    testWidgets('le bouton ne chevauche pas une barre de navigation système simulée',
        (tester) async {
      SharedPreferences.setMockInitialValues({});

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      tester.view.padding = const FakeViewPadding(bottom: 135); // barre nav Android
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(home: PersonSelectionScreen()),
      );
      await tester.pumpAndSettle();

      final saveButton = find.widgetWithText(ElevatedButton, 'حفظ');
      expect(saveButton, findsOneWidget);

      final buttonBottom = tester.getBottomLeft(saveButton).dy;
      final screenHeightLogical =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      final systemInsetLogical =
          tester.view.padding.bottom / tester.view.devicePixelRatio;
      final safeBoundary = screenHeightLogical - systemInsetLogical;

      expect(
        buttonBottom,
        lessThanOrEqualTo(safeBoundary + 0.5), // tolérance d'arrondi pixel
        reason: 'le bouton "حفظ" déborde dans la zone système (SafeArea manquante)',
      );
    });
  });

  group('Person Selection — synchronisation du chip résumé (BUG-003)', () {
    testWidgets('rouvrir avec une personne déjà enregistrée affiche son chip (pas "لم يتم اختيار أي شخص")',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'flutter.persons_data': '{"father":"Youssef"}',
      });

      await tester.pumpWidget(
        const MaterialApp(home: PersonSelectionScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('لم يتم اختيار أي شخص'), findsNothing);
      expect(find.textContaining('أبي'), findsWidgets);
      expect(find.textContaining('Youssef'), findsWidgets);
    });

    testWidgets('décocher une personne fait disparaître son chip immédiatement',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'flutter.persons_data': '{"father":"Youssef"}',
      });

      await tester.pumpWidget(
        const MaterialApp(home: PersonSelectionScreen()),
      );
      await tester.pumpAndSettle();

      // Le chip du père est présent au chargement.
      expect(find.textContaining('Youssef'), findsWidgets);

      final fatherCheckbox = find.byType(Checkbox).first;
      await tester.tap(fatherCheckbox);
      await tester.pumpAndSettle();

      // Après décochage : plus de chip fantôme, résumé vide.
      expect(find.textContaining('Youssef'), findsNothing);
      expect(find.text('لم يتم اختيار أي شخص'), findsOneWidget);
    });
  });
}
