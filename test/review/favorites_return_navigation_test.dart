// Test LOT 5.D — non-régression de la navigation Favoris → HOME, avec le
// branchement réel (aucun fake) : `ReviewPromptController.instance`, donc
// l'implémentation réelle `InAppReviewAvailability`.
//
// En `flutter_test`, le canal de plateforme de `in_app_review` n'existe pas :
// c'est exactement le cas « mécanisme indisponible » exigé par D7. Ce test
// vérifie de bout en bout qu'il se traduit par un silence complet — aucune
// exception, aucune navigation bloquée, aucun cooldown consommé.
//
// Un seul `testWidgets` dans ce fichier : le chargement initial de HOME
// passe par une E/S réelle (`DuaRepository`), et plusieurs tests réels dans
// un même fichier contaminent la zone async fictive (limitation déjà
// documentée dans premium_share_as_image_test.dart).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:test_1/favorites_screen.dart';
import 'package:test_1/home_screen.dart';
import 'package:test_1/user_prefs.dart';

void main() {
  testWidgets(
      'aller-retour HOME → Favoris → HOME : navigation intacte, aucune '
      'exception, et aucun cooldown consommé quand le mécanisme natif est '
      'indisponible', (tester) async {
    // Installation ancienne + jamais sollicitée : toutes les conditions
    // produit sont réunies, seul le mécanisme natif manque. C'est le seul
    // réglage qui exerce réellement le chemin jusqu'au provider.
    final oneYearAgo = DateTime.now().subtract(const Duration(days: 365));
    SharedPreferences.setMockInitialValues({
      'flutter.first_open_at': oneYearAgo.millisecondsSinceEpoch,
    });

    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    // Le chargement initial passe par une E/S réelle qui ne se résout pas
    // dans la zone async fictive via `pumpAndSettle()` seul : on sonde par
    // petits pas jusqu'à apparition de l'AppBar complète.
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byTooltip('المفضلة').evaluate().isNotEmpty) break;
    }

    expect(find.byTooltip('المفضلة'), findsOneWidget);

    await tester.tap(find.byTooltip('المفضلة'));
    await tester.pumpAndSettle();
    expect(find.byType(FavoritesScreen), findsOneWidget);

    // Retour vers HOME — c'est cette transition, et elle seule, qui évalue
    // une éventuelle demande d'évaluation.
    final NavigatorState navigator = tester.state(find.byType(Navigator));
    navigator.pop();
    await tester.pumpAndSettle();

    // Laisse la suite de transition (interstitiel puis évaluation, toutes
    // deux `unawaited`) se dérouler entièrement.
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.byType(FavoritesScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);

    // Le garde « HOME est bien l'écran courant » (qui protège DuaRead et
    // Grave Visit d'une sollicitation tardive, D6) ne doit pas bloquer le
    // cas nominal : au retour de Favoris, la route de HOME est courante.
    expect(
      ModalRoute.of(tester.element(find.byType(HomeScreen)))?.isCurrent,
      isTrue,
      reason: 'sans cela, la sollicitation ne pourrait jamais être émise',
    );
    expect(find.byTooltip('المفضلة'), findsOneWidget,
        reason: 'HOME reste pleinement fonctionnel au retour');
    expect(tester.takeException(), isNull,
        reason: 'l\'indisponibilité du mécanisme natif ne doit jamais '
            'remonter d\'exception');

    expect(
      await UserPrefs.instance.getLastReviewPromptedAt(),
      isNull,
      reason: 'aucun dialogue n\'a pu être affiché : le cooldown de 90 jours '
          'ne doit pas être consommé',
    );
  });
}
