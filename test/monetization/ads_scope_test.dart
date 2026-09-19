// Tests LOT 5.F — non-régression structurelle des surfaces publicitaires.
//
// Le LOT 5.F ne touche que la CONFIGURATION (identifiants, environnement,
// initialisation). Ce fichier prouve, en lisant les sources, que rien des
// décisions produit D8/D9/D10/D11/D12 n'a bougé : un lot ultérieur qui
// déplacerait une bannière, ajouterait un déclencheur d'interstitiel ou
// changerait le cooldown fera échouer ces tests.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:test_1/monetization/ad_surface.dart';
import 'package:test_1/monetization/ads_policy.dart';
import 'package:test_1/monetization/interstitial_trigger.dart';

/// Source d'un fichier, commentaires de ligne retirés — même procédé que
/// `test/review/review_scope_test.dart` : les assertions portent sur le
/// CODE, jamais sur la documentation.
String _readCode(String path) {
  return File(path).readAsLinesSync().map((line) {
    final commentIndex = line.indexOf('//');
    return commentIndex == -1 ? line : line.substring(0, commentIndex);
  }).join('\n');
}

void main() {
  group('Bannières — 3 surfaces autorisées, et elles seules (D8/D9)', () {
    const allowed = <String, AdSurface>{
      'lib/home_screen.dart': AdSurface.home,
      'lib/search_screen.dart': AdSurface.search,
      'lib/favorites_screen.dart': AdSurface.favorites,
    };

    allowed.forEach((path, surface) {
      test('$path héberge exactement une bannière (${surface.name})', () {
        final source = _readCode(path);
        final matches = RegExp('BannerAdSlot\\(surface:').allMatches(source);

        expect(matches.length, 1);
        expect(source, contains('AdSurface.${surface.name}'));
        expect(AdsPolicy.isBannerEligible(surface), isTrue);
      });
    });

    const excluded = <String, String>{
      'lib/screens/dua_read_screen.dart': 'DuaRead (lecture)',
      'lib/screens/grave_visit_read_screen.dart': 'Grave Visit',
      'lib/screens/onboarding_screen.dart': 'Onboarding',
      'lib/screens/person_selection_screen.dart': 'Person Selection',
      'lib/settings_screen.dart': 'Paramètres',
      'lib/main.dart': 'Lancement / Splash',
    };

    excluded.forEach((path, label) {
      test('aucune bannière dans $label', () {
        final source = _readCode(path);

        expect(source.contains('BannerAdSlot'), isFalse);
        expect(source.contains('AdSurface.'), isFalse);
      });
    });

    test('la policy refuse toutes les surfaces non autorisées', () {
      for (final surface in AdSurface.values) {
        final expected = surface == AdSurface.home ||
            surface == AdSurface.search ||
            surface == AdSurface.favorites;
        expect(AdsPolicy.isBannerEligible(surface), expected);
      }
    });
  });

  group('Interstitiels — 2 déclencheurs, et eux seuls (D10/D12)', () {
    test('un seul écran déclenche des interstitiels : HOME', () {
      const screens = [
        'lib/home_screen.dart',
        'lib/search_screen.dart',
        'lib/favorites_screen.dart',
        'lib/screens/dua_read_screen.dart',
        'lib/screens/grave_visit_read_screen.dart',
        'lib/screens/onboarding_screen.dart',
        'lib/screens/person_selection_screen.dart',
        'lib/settings_screen.dart',
        'lib/main.dart',
      ];

      for (final path in screens) {
        final callsInterstitial =
            _readCode(path).contains('maybeShowOnTransition');
        expect(
          callsInterstitial,
          path == 'lib/home_screen.dart',
          reason: path,
        );
      }
    });

    test('HOME n\'utilise que les 2 déclencheurs verrouillés', () {
      final source = _readCode('lib/home_screen.dart');
      final calls = RegExp('maybeShowOnTransition').allMatches(source);

      expect(calls.length, 2);
      expect(source, contains('InterstitialTrigger.leavingSearch'));
      expect(source, contains('InterstitialTrigger.leavingFavorites'));
    });

    test('l\'enum ne représente aucune autre transition', () {
      expect(InterstitialTrigger.values, hasLength(2));
      for (final trigger in InterstitialTrigger.values) {
        expect(AdsPolicy.isInterstitialTriggerEligible(trigger), isTrue);
      }
    });
  });

  group('Cooldown interstitiel — 10 minutes (D11)', () {
    test('valeur produit verrouillée', () {
      expect(AdsPolicy.interstitialCooldown, const Duration(minutes: 10));
    });

    test('inchangé par le LOT 5.F', () {
      final now = DateTime(2026, 9, 20, 12, 0);

      expect(
        AdsPolicy.isInterstitialCooldownElapsed(
          lastShownAt: now.subtract(const Duration(minutes: 9, seconds: 59)),
          now: now,
        ),
        isFalse,
      );
      expect(
        AdsPolicy.isInterstitialCooldownElapsed(
          lastShownAt: now.subtract(const Duration(minutes: 10)),
          now: now,
        ),
        isTrue,
      );
    });
  });
}
