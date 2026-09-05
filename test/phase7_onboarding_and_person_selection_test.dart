// Tests Phase 7 (V1.2) puis LOT 1C (refonte UI/UX) : mode Édition sans CTA
// fixe, synchronisation de la sélection (BUG-003, y compris au
// rechargement avec des personnes déjà enregistrées), et snackbar تراجع.
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
import 'package:test_1/widgets/app_bar.dart';
import 'package:test_1/widgets/app_chip.dart';

void main() {
  group('Person Selection — Mode Édition sans CTA (§4 ETAT_CONSOLIDE_UI_UX)', () {
    testWidgets('AppBar h56, aucun bouton fixe en bas', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const MaterialApp(home: PersonSelectionScreen()),
      );
      await tester.pumpAndSettle();

      final appBar = tester.widget<AppTopBar>(find.byType(AppTopBar));
      expect(appBar.height, 56);

      // Le bas de l'écran ne porte plus de CTA (§4 : "aucun CTA en bas").
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.widgetWithText(ElevatedButton, 'حفظ'), findsNothing);
    });
  });

  group('Person Selection — synchronisation de la sélection (BUG-003)', () {
    testWidgets('rouvrir avec une personne déjà enregistrée affiche sa chip sélectionnée',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'flutter.persons_data': '{"father":"Youssef"}',
      });

      await tester.pumpWidget(
        const MaterialApp(home: PersonSelectionScreen()),
      );
      await tester.pumpAndSettle();

      final fatherChip = tester.widget<AppChip>(find.widgetWithText(AppChip, 'أبي'));
      expect(fatherChip.selected, isTrue);
      expect(find.textContaining('Youssef'), findsWidgets);
    });

    testWidgets('décocher une personne retire immédiatement sa sélection et son champ',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'flutter.persons_data': '{"father":"Youssef"}',
      });

      await tester.pumpWidget(
        const MaterialApp(home: PersonSelectionScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Youssef'), findsWidgets);

      await tester.tap(find.widgetWithText(AppChip, 'أبي'));
      await tester.pump(); // état local

      final fatherChip = tester.widget<AppChip>(find.widgetWithText(AppChip, 'أبي'));
      expect(fatherChip.selected, isFalse);
      expect(find.textContaining('Youssef'), findsNothing);
    });

    testWidgets('décocher affiche la snackbar تراجع', (tester) async {
      SharedPreferences.setMockInitialValues({
        'flutter.persons_data': '{"father":"Youssef"}',
      });

      await tester.pumpWidget(
        const MaterialApp(home: PersonSelectionScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(AppChip, 'أبي'));
      await tester.pump();

      expect(find.text('تراجع'), findsOneWidget);
    });
  });

  group('Person Selection — sélection multiple persistante (LOT 1C.1)', () {
    testWidgets(
        'plusieurs personnes cochées restent toutes cochées après sauvegarde puis rechargement',
        (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const MaterialApp(home: PersonSelectionScreen()),
      );
      await tester.pumpAndSettle();

      // Sélection successive : الأب puis الأم.
      await tester.tap(find.widgetWithText(AppChip, 'أبي'));
      await tester.pump();
      await tester.tap(find.widgetWithText(AppChip, 'أمي'));
      await tester.pump();

      // Simule une fermeture/redémarrage : nouvelle instance d'écran, même
      // stockage `SharedPreferences` mocké (persistance déjà écrite par les
      // taps ci-dessus, sans reset du mock entre les deux pumpWidget).
      await tester.pumpWidget(
        const MaterialApp(home: PersonSelectionScreen()),
      );
      await tester.pumpAndSettle();

      final fatherChip = tester.widget<AppChip>(find.widgetWithText(AppChip, 'أبي'));
      final motherChip = tester.widget<AppChip>(find.widgetWithText(AppChip, 'أمي'));
      expect(fatherChip.selected, isTrue);
      expect(motherChip.selected, isTrue);

      // Badge `الحالي` retiré (audit UX — aucune conséquence fonctionnelle
      // ailleurs dans l'app) : plus aucune occurrence à l'écran.
      expect(find.text('الحالي'), findsNothing);
    });
  });
}
