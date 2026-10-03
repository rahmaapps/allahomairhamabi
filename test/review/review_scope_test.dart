// Tests LOT 5.D — périmètre du branchement.
//
// Vérifie STRUCTURELLEMENT, en lisant les sources, qu'aucune logique
// d'évaluation n'existe hors de son unique point de branchement. Un test
// comportemental ne pourrait pas prouver une absence : il faudrait exercer
// tous les chemins de tous les écrans. La lecture des sources, elle, le
// prouve directement, et échouera si un lot ultérieur rebranche
// l'évaluation ailleurs sans décision produit.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:test_1/review/review_trigger.dart';

/// Tout ce qui trahirait une logique d'évaluation dans un fichier.
const _reviewTokens = <String>[
  'ReviewPromptController',
  'ReviewTrigger',
  'ReviewPolicy',
  'ReviewAvailability',
  'InAppReview',
  'in_app_review',
];

/// Source d'un fichier du projet, **commentaires de ligne retirés**.
///
/// Les assertions de ce fichier portent sur le CODE, jamais sur la
/// documentation : un commentaire qui explique pourquoi un écran ne
/// sollicite rien mentionne légitimement les concepts qu'il exclut, et ne
/// doit pas être confondu avec une logique réelle.
///
/// Appelée aussi au niveau des `group`, donc sans `expect` : un fichier
/// absent échoue de lui-même (`readAsLinesSync` lève).
String _readCode(String path) {
  return File(path).readAsLinesSync().map((line) {
    final commentIndex = line.indexOf('//');
    return commentIndex == -1 ? line : line.substring(0, commentIndex);
  }).join('\n');
}

void main() {
  group('LOT 5.D — écrans et moments explicitement exclus (D6)', () {
    // Chaque entrée correspond à une exclusion produit verrouillée.
    const excludedSources = <String, String>{
      'lib/screens/dua_read_screen.dart': 'DuaRead (interaction de lecture)',
      'lib/screens/grave_visit_read_screen.dart': 'Grave Visit',
      'lib/screens/onboarding_screen.dart': 'Onboarding',
      'lib/screens/person_selection_screen.dart': 'Person Selection',
      'lib/search_screen.dart': 'Recherche',
      'lib/favorites_screen.dart': 'Favoris (l\'écran lui-même)',
      'lib/settings_screen.dart': 'Paramètres (aucun bouton « Évaluer »)',
      'lib/main.dart': 'Lancement / Splash',
    };

    excludedSources.forEach((path, label) {
      test('aucune logique d\'évaluation dans $label', () {
        final source = _readCode(path);
        for (final token in _reviewTokens) {
          expect(
            source.contains(token),
            isFalse,
            reason: '$path ne doit contenir aucune référence à « $token » '
                '($label est une exclusion verrouillée du LOT 5.D)',
          );
        }
      });
    });
  });

  group('LOT 5.D — point de branchement unique dans HOME (D1)', () {
    final home = _readCode('lib/home_screen.dart');

    test('une seule sollicitation dans tout le fichier', () {
      expect(
        'ReviewPromptController'.allMatches(home).length,
        1,
        reason: 'un unique appel, jamais dispersé dans l\'écran',
      );
      expect('maybeRequestOnTransition'.allMatches(home).length, 1);
    });

    test('le seul déclencheur utilisé est le retour Favoris → HOME', () {
      expect('ReviewTrigger.'.allMatches(home).length, 1);
      expect(home.contains('ReviewTrigger.leavingFavorites'), isTrue);
    });

    test(
        'la sollicitation est branchée sur la suite de la transition '
        'Favoris → HOME, et jamais dans le chemin Recherche → HOME',
        () {
      final hookIndex = home.indexOf('ReviewPromptController');
      final favoritesTransitionIndex =
          home.indexOf('Future<void> _runPostFavoritesTransition()');
      final searchIndex = home.indexOf('Future<void> _openSearch()');

      expect(favoritesTransitionIndex, greaterThan(-1));
      expect(searchIndex, greaterThan(-1));
      expect(
        hookIndex,
        greaterThan(favoritesTransitionIndex),
        reason: 'l\'appel doit être dans _runPostFavoritesTransition',
      );
      expect(
        hookIndex,
        lessThan(searchIndex),
        reason: 'l\'appel ne doit jamais se trouver dans _openSearch : le '
            'retour Recherche → HOME ne sollicite rien (D1)',
      );
    });

    test(
        'aucun bouton permanent « Évaluer » n\'est introduit dans HOME '
        '(D6)', () {
      expect(home.contains('تقييم التطبيق'), isFalse);
      expect(home.contains('openStoreListing'), isFalse);
    });
  });

  group('LOT 5.D — aucun dialogue custom avant Google Play', () {
    test(
        'le service n\'affiche aucune UI : il ne dépend ni de material, ni '
        'd\'un BuildContext (donc ni question préalable « Aimez-vous '
        'l\'application ? », ni dialogue maison)', () {
      final controller = _readCode('lib/review/review_prompt_controller.dart');
      expect(controller.contains('material.dart'), isFalse);
      expect(controller.contains('BuildContext'), isFalse);
      expect(controller.contains('showDialog'), isFalse);
    });

    test('la policy reste pure : aucun accès au stockage ni à la plateforme',
        () {
      final policy = _readCode('lib/review/review_policy.dart');
      expect(policy.contains('UserPrefs'), isFalse);
      expect(policy.contains('SharedPreferences'), isFalse);
      expect(policy.contains('in_app_review'), isFalse);
    });

    test('la policy ne dépend pas du package : D7 (abstraction) respecté',
        () {
      final controller = _readCode('lib/review/review_prompt_controller.dart');
      expect(
        controller.contains('package:in_app_review'),
        isFalse,
        reason: 'seule l\'implémentation InAppReviewAvailability connaît le '
            'package',
      );
    });
  });

  group('LOT 5.D — aucun compteur d\'usage introduit (D2)', () {
    test('les seules clés ajoutées sont deux dates', () {
      final prefs = _readCode('lib/user_prefs.dart');
      expect(prefs.contains('first_open_at'), isTrue);
      expect(prefs.contains('last_review_prompted_at'), isTrue);

      for (final forbidden in const [
        'sessionCount',
        'session_count',
        'openCount',
        'open_count',
        'launchCount',
        'launch_count',
        'duaReadCount',
        'usage_count',
      ]) {
        expect(prefs.contains(forbidden), isFalse,
            reason: 'aucun compteur ne doit être introduit ($forbidden)');
      }
    });
  });

  group('LOT 5.D — monétisation non modifiée', () {
    test(
        'la sonde publicitaire lit l\'état interstitiel sans jamais le '
        'piloter', () {
      final probe = _readCode('lib/review/interstitial_ad_activity_probe.dart');
      for (final forbidden in const [
        'maybeShowOnTransition',
        'setLastInterstitialShownAt',
        'setAdsSuppressedUntil',
      ]) {
        expect(probe.contains(forbidden), isFalse,
            reason: 'lecture seule stricte : $forbidden interdit ici');
      }
    });
  });

  group('LOT 5.D — surface de déclenchement', () {
    test('un seul déclencheur existe dans tout le domaine', () {
      expect(ReviewTrigger.values, hasLength(1));
    });
  });
}
