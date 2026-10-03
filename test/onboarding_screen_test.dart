// Tests LOT 3.E.1 — Onboarding (docs/ui_ux/ETAT_CONSOLIDE_UI_UX.md, §4).
// LOT 3.H — ordre corrigé : STEP 0 = `لمن تدعو؟`, STEP 1 = `تذكير يومي؟`
// (décision verrouillée, remplace l'ordre inverse retenu par LOT 3.E.1).
//
// `OnboardingScreen` est pompée directement (`MaterialApp(home: ...)`),
// comme `PersonSelectionScreen` dans test/phase7_onboarding_and_person_
// selection_test.dart — même limitation documentée là-bas pour
// `settings_screen.dart` : `NotificationService` touche des canaux de
// plateforme natifs non mockables en `flutter_test` simple. La vérification
// de permission de `OnboardingScreen` est conçue pour ne jamais bloquer le
// rendu (fire-and-forget, aucun indicateur de chargement qui en dépend) —
// c'est justement ce que ces tests vérifient indirectement en réussissant.
// Cette demande de permission se déclenche désormais en quittant l'étape
// `تذكير يومي؟` via `التالي`, puisque cette étape est désormais la dernière
// (voir `_finishFromReminderStep` dans onboarding_screen.dart).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:test_1/home_screen.dart';
import 'package:test_1/screens/onboarding_screen.dart';
import 'package:test_1/widgets/app_button.dart';
import 'package:test_1/widgets/app_chip.dart';

void main() {
  group('Onboarding — étapes et navigation (§4 Onboarding)', () {
    testWidgets('étape 1 affiche لمن تدعو؟, aucun bouton bloqué',
        (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
      await tester.pump();
      await tester.pump();

      expect(find.text('لمن تدعو؟'), findsOneWidget);
      expect(find.byType(AppChip), findsWidgets);
      // Le rappel (Switch) n'apparaît qu'à l'étape suivante.
      expect(find.byType(Switch), findsNothing);
      // Bouton retour visible uniquement à l'étape رappel (désormais STEP 1).
      expect(find.byIcon(Icons.arrow_forward), findsNothing);

      // التالي n'est jamais désactivé.
      final next = tester.widget<AppButton>(
        find.widgetWithText(AppButton, 'التالي'),
      );
      expect(next.onPressed, isNotNull);
      // تخطّي toujours visible.
      expect(find.widgetWithText(AppButton, 'تخطّي'), findsOneWidget);
    });

    testWidgets(
        'التالي depuis STEP 0 mène vers تذكير يومي؟ avec رappel activé par défaut',
        (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.widgetWithText(AppButton, 'التالي'));
      await tester.pumpAndSettle();

      expect(find.text('تذكير يومي؟'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      final sw = tester.widget<Switch>(find.byType(Switch));
      expect(sw.value, isTrue);
      // Rappel activé par défaut → la ligne « الوقت » est visible.
      expect(find.text('الوقت'), findsOneWidget);
      // Heure en chiffres occidentaux (décision UX), pas arabes-indiens.
      expect(find.text('09:00'), findsOneWidget);
      expect(find.text('٠٩:٠٠'), findsNothing);
      // Bouton retour visible désormais que l'on est à la 2e étape.
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets(
        'désactiver le rappel (STEP 1) retire complètement la ligne « الوقت »',
        (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
      await tester.pump();
      await tester.pump();

      // STEP 0 (لمن تدعو؟) → STEP 1 (تذكير يومي؟), où vit le Switch.
      await tester.tap(find.widgetWithText(AppButton, 'التالي'));
      await tester.pumpAndSettle();

      expect(find.text('الوقت'), findsOneWidget);

      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(find.text('الوقت'), findsNothing);

      final sw = tester.widget<Switch>(find.byType(Switch));
      expect(sw.value, isFalse);
    });

    testWidgets(
        'retour arrière depuis l\'étape رappel (STEP 1) conserve la sélection de personne',
        (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
      await tester.pump();
      await tester.pump();

      // Sélection sur STEP 0 (لمن تدعو؟), directement visible dès l'ouverture.
      await tester.tap(find.widgetWithText(AppChip, 'أبي'));
      await tester.pump();
      final fatherChip = tester.widget<AppChip>(find.widgetWithText(AppChip, 'أبي'));
      expect(fatherChip.selected, isTrue);

      // Avance vers STEP 1 (تذكير يومي؟).
      await tester.tap(find.widgetWithText(AppButton, 'التالي'));
      await tester.pumpAndSettle();
      expect(find.text('تذكير يومي؟'), findsOneWidget);

      // Retour arrière vers STEP 0 : la sélection doit être intacte.
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();
      expect(find.text('لمن تدعو؟'), findsOneWidget);

      final fatherChipAgain =
          tester.widget<AppChip>(find.widgetWithText(AppChip, 'أبي'));
      expect(fatherChipAgain.selected, isTrue);
    });

    testWidgets(
        'décocher une personne ne vide jamais son prénom — il réapparaît si elle est recochée',
        (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
      await tester.pump();
      await tester.pump();

      // STEP 0 (لمن تدعو؟) est la première étape — aucune navigation requise
      // pour atteindre la sélection des personnes.
      await tester.tap(find.widgetWithText(AppChip, 'أبي'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'يوسف');
      await tester.pump();
      expect(find.text('يوسف'), findsOneWidget);

      // Décoche : le champ disparaît de l'écran (personne non sélectionnée)
      // mais son contenu n'est jamais vidé (§4 Onboarding).
      await tester.tap(find.widgetWithText(AppChip, 'أبي'));
      await tester.pump();
      expect(find.byType(TextField), findsNothing);

      // Recoche : le prénom réapparaît tel quel.
      await tester.tap(find.widgetWithText(AppChip, 'أبي'));
      await tester.pump();
      expect(find.text('يوسف'), findsOneWidget);
    });

    testWidgets(
        'التالي sur STEP 1 (تذكير يومي؟) persiste les personnes, marque settings_completed et affiche HOME',
        (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
      await tester.pump();
      await tester.pump();

      // Sélection sur STEP 0 (لمن تدعو؟), avant d'avancer.
      await tester.tap(find.widgetWithText(AppChip, 'أبي'));
      await tester.pump();

      // Avance vers STEP 1 (تذكير يومي؟).
      await tester.tap(find.widgetWithText(AppButton, 'التالي'));
      await tester.pumpAndSettle();
      expect(find.text('تذكير يومي؟'), findsOneWidget);

      // التالي sur STEP 1 termine l'onboarding (déclenche au passage la
      // demande de permission fire-and-forget, non bloquante — voir
      // `_finishFromReminderStep`).
      await tester.tap(find.widgetWithText(AppButton, 'التالي'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('settings_completed'), isTrue);
      expect(prefs.getString('persons_data'), contains('father'));
    });

    testWidgets(
        'تخطّي depuis STEP 0 (لمن تدعو؟) marque settings_completed et affiche HOME',
        (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
      await tester.pump();
      await tester.pump();

      await tester.tap(find.widgetWithText(AppButton, 'تخطّي'));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('settings_completed'), isTrue);
    });
  });
}
