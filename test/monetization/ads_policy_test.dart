import 'package:flutter_test/flutter_test.dart';
import 'package:test_1/monetization/ad_surface.dart';
import 'package:test_1/monetization/ads_free_status.dart';
import 'package:test_1/monetization/ads_policy.dart';

void main() {
  group('AdsPolicy.isBannerEligible — contraintes produit verrouillées', () {
    test('HOME, Recherche et Favoris sont éligibles à une bannière', () {
      expect(AdsPolicy.isBannerEligible(AdSurface.home), isTrue);
      expect(AdsPolicy.isBannerEligible(AdSurface.search), isTrue);
      expect(AdsPolicy.isBannerEligible(AdSurface.favorites), isTrue);
    });

    test(
        'Grave Visit, DuaRead, Onboarding, Splash et Share as Image ne sont '
        'JAMAIS éligibles à une bannière', () {
      expect(AdsPolicy.isBannerEligible(AdSurface.graveVisit), isFalse);
      expect(AdsPolicy.isBannerEligible(AdSurface.duaRead), isFalse);
      expect(AdsPolicy.isBannerEligible(AdSurface.onboarding), isFalse);
      expect(AdsPolicy.isBannerEligible(AdSurface.splash), isFalse);
      expect(AdsPolicy.isBannerEligible(AdSurface.shareAsImage), isFalse);
    });
  });

  group('AdsPolicy.canShowBanner', () {
    const adFree = AdsFreeStatus(null);

    test('false si la surface n\'est pas éligible, même si tout le reste '
        'est vrai', () {
      final result = AdsPolicy.canShowBanner(
        surface: AdSurface.graveVisit,
        canRequestAds: true,
        adsFreeStatus: adFree,
      );
      expect(result, isFalse);
    });

    test('false si canRequestAds (source unique de vérité UMP) est faux',
        () {
      final result = AdsPolicy.canShowBanner(
        surface: AdSurface.home,
        canRequestAds: false,
        adsFreeStatus: adFree,
      );
      expect(result, isFalse);
    });

    test('false si une suppression temporaire (Rewarded) est active', () {
      final now = DateTime(2026, 1, 1, 12, 0);
      final suppressedUntil = now.add(const Duration(minutes: 10));

      final result = AdsPolicy.canShowBanner(
        surface: AdSurface.home,
        canRequestAds: true,
        adsFreeStatus: AdsFreeStatus(suppressedUntil),
        now: now,
      );
      expect(result, isFalse);
    });

    test(
        'true seulement quand les 3 conditions sont réunies : surface '
        'éligible + canRequestAds + aucune suppression active', () {
      final result = AdsPolicy.canShowBanner(
        surface: AdSurface.search,
        canRequestAds: true,
        adsFreeStatus: adFree,
      );
      expect(result, isTrue);
    });

    test('redevient true une fois la suppression temporaire expirée', () {
      final now = DateTime(2026, 1, 1, 12, 0);
      final suppressedUntil = now.subtract(const Duration(minutes: 1));

      final result = AdsPolicy.canShowBanner(
        surface: AdSurface.favorites,
        canRequestAds: true,
        adsFreeStatus: AdsFreeStatus(suppressedUntil),
        now: now,
      );
      expect(result, isTrue);
    });
  });
}
