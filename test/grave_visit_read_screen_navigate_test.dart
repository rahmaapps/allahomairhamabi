// Tests LOT 3.F — دعاء زيارة القبر : chargement réel du douʿā affiché par
// `GraveVisitReadScreen` après le parcours complet HOME → bandeau → bottom
// sheet → sélection de personne (docs/ui_ux/ETAT_CONSOLIDE_UI_UX.md, §1/§4/
// §6.5).
//
// Isolé dans son propre fichier (un seul test) : ce test attend une E/S
// réelle (`rootBundle.loadString`, via `DuaRepository`) après un parcours de
// navigation complet. En pratique, `flutter test` ne garantit une isolation
// fiable de la zone async fictive qu'entre fichiers exécutés séparément —
// regroupé avec un second test dans le même fichier/process, l'indicateur de
// chargement du second test ne disparaissait jamais, même après un budget de
// polling réel généreux. Un seul test réel par fichier évite ce problème.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:test_1/home_screen.dart';
import 'package:test_1/screens/grave_visit_read_screen.dart';
import 'package:test_1/widgets/app_bar.dart';
import 'package:test_1/widgets/app_chip.dart';

Future<void> _waitForRealAsyncLoad(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 50));
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) return;
  }
}

void main() {
  testWidgets(
      'sélectionner une personne ferme la feuille, ouvre l\'écran de lecture et charge le bon douʿā',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'flutter.persons_data': '{"father":""}',
    });

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AppVisitBandeau));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(AppChip, 'أبي'));
    await tester.pump();
    await _waitForRealAsyncLoad(tester);
    // Laisse également l'animation de fermeture de la feuille (horloge
    // fictive, pas de l'E/S réelle) se terminer.
    await tester.pump(const Duration(milliseconds: 300));

    // La feuille est fermée, l'écran de lecture dédié est ouvert. (HOME
    // reste monté sous la route poussée — comportement normal de
    // `Navigator` — donc ses propres chips de catégorie subsistent dans
    // l'arbre ; seule la chip de personne de la feuille doit disparaître.)
    expect(find.byType(GraveVisitReadScreen), findsOneWidget);
    expect(find.widgetWithText(AppChip, 'أبي'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Le douʿā affiché est bien celui de « father » — présence vérifiée
    // d'un passage spécifique au père dans le texte réel de
    // `assets/data/duas.json` → father → grave_visit.
    expect(find.textContaining('بِوَالِدِي'), findsOneWidget);
  });
}
