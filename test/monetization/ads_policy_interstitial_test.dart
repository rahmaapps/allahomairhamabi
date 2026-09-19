import 'package:flutter_test/flutter_test.dart';
import 'package:test_1/monetization/ads_free_status.dart';
import 'package:test_1/monetization/ads_policy.dart';
import 'package:test_1/monetization/interstitial_trigger.dart';

void main() {
  final now = DateTime(2026, 5, 1, 12, 0);
  const noAdsFree = AdsFreeStatus(null);

  group('AdsPolicy — éligibilité des déclencheurs (périmètre verrouillé)',
      () {
    test('leavingSearch et leavingFavorites sont autorisés', () {
      expect(
        AdsPolicy.isInterstitialTriggerEligible(
          InterstitialTrigger.leavingSearch,
        ),
        isTrue,
      );
      expect(
        AdsPolicy.isInterstitialTriggerEligible(
          InterstitialTrigger.leavingFavorites,
        ),
        isTrue,
      );
    });

    test(
        'aucune autre transition de l\'app n\'existe comme déclencheur : '
        'l\'enum est strictement limité aux deux retours validés (donc ni '
        'DuaRead, ni Grave Visit, ni Onboarding, ni Settings, ni '
        '« دعاء آخر » ne peuvent être déclenchés)', () {
      expect(InterstitialTrigger.values, [
        InterstitialTrigger.leavingSearch,
        InterstitialTrigger.leavingFavorites,
      ]);
    });
  });

  group('AdsPolicy — cooldown 10 minutes', () {
    test('timestamp absent (jamais présenté) → cooldown écoulé', () {
      expect(
        AdsPolicy.isInterstitialCooldownElapsed(lastShownAt: null, now: now),
        isTrue,
      );
    });

    test('moins de 10 minutes → cooldown NON écoulé', () {
      expect(
        AdsPolicy.isInterstitialCooldownElapsed(
          lastShownAt: now.subtract(const Duration(minutes: 9, seconds: 59)),
          now: now,
        ),
        isFalse,
      );
    });

    test('exactement 10 minutes → cooldown écoulé (borne incluse)', () {
      expect(
        AdsPolicy.isInterstitialCooldownElapsed(
          lastShownAt: now.subtract(const Duration(minutes: 10)),
          now: now,
        ),
        isTrue,
      );
    });

    test('plus de 10 minutes → cooldown écoulé', () {
      expect(
        AdsPolicy.isInterstitialCooldownElapsed(
          lastShownAt: now.subtract(const Duration(minutes: 42)),
          now: now,
        ),
        isTrue,
      );
    });
  });

  group('AdsPolicy.canShowInterstitial', () {
    test('true quand toutes les conditions sont réunies', () {
      expect(
        AdsPolicy.canShowInterstitial(
          trigger: InterstitialTrigger.leavingSearch,
          canRequestAds: true,
          adsFreeStatus: noAdsFree,
          lastShownAt: null,
          now: now,
        ),
        isTrue,
      );
    });

    test('false si canRequestAds est faux (consentement non exploitable)',
        () {
      expect(
        AdsPolicy.canShowInterstitial(
          trigger: InterstitialTrigger.leavingSearch,
          canRequestAds: false,
          adsFreeStatus: noAdsFree,
          lastShownAt: null,
          now: now,
        ),
        isFalse,
      );
    });

    test('false si adsSuppressedUntil est actif (fenêtre sans publicité)',
        () {
      expect(
        AdsPolicy.canShowInterstitial(
          trigger: InterstitialTrigger.leavingFavorites,
          canRequestAds: true,
          adsFreeStatus: AdsFreeStatus(now.add(const Duration(minutes: 30))),
          lastShownAt: null,
          now: now,
        ),
        isFalse,
      );
    });

    test('false si le cooldown n\'est pas écoulé', () {
      expect(
        AdsPolicy.canShowInterstitial(
          trigger: InterstitialTrigger.leavingFavorites,
          canRequestAds: true,
          adsFreeStatus: noAdsFree,
          lastShownAt: now.subtract(const Duration(minutes: 5)),
          now: now,
        ),
        isFalse,
      );
    });

    test('true à nouveau une fois le cooldown écoulé', () {
      expect(
        AdsPolicy.canShowInterstitial(
          trigger: InterstitialTrigger.leavingFavorites,
          canRequestAds: true,
          adsFreeStatus: noAdsFree,
          lastShownAt: now.subtract(const Duration(minutes: 11)),
          now: now,
        ),
        isTrue,
      );
    });
  });
}
