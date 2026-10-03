import 'package:flutter_test/flutter_test.dart';
import 'package:test_1/monetization/ads_availability.dart';

import 'fakes/fake_consent_service.dart';

void main() {
  group('AdsAvailability — source unique de vérité (audit LOT 5.A §5/§8)', () {
    test(
        'canRequestAds() est false tant que le SDK n\'est pas marqué initialisé, '
        'même si le consentement UMP l\'autorise déjà', () async {
      final consent = FakeConsentService()..canRequestAdsValue = true;
      final availability = AdsAvailability(consent);

      expect(await availability.canRequestAds(), isFalse);
      expect(availability.isSdkInitialized, isFalse);
    });

    test(
        'canRequestAds() reste false si le SDK est initialisé mais que le '
        'consentement UMP ne l\'autorise pas', () async {
      final consent = FakeConsentService()..canRequestAdsValue = false;
      final availability = AdsAvailability(consent)..markSdkInitialized();

      expect(await availability.canRequestAds(), isFalse);
    });

    test(
        'canRequestAds() devient true seulement quand les DEUX conditions '
        'sont réunies (SDK initialisé ET consentement UMP exploitable)',
        () async {
      final consent = FakeConsentService()..canRequestAdsValue = true;
      final availability = AdsAvailability(consent);

      expect(await availability.canRequestAds(), isFalse);

      availability.markSdkInitialized();

      expect(await availability.canRequestAds(), isTrue);
    });

    test('canRequestAds() ne fait jamais de supposition locale : il '
        'délègue strictement à ConsentService.canRequestAds()', () async {
      final consent = FakeConsentService()..canRequestAdsValue = true;
      final availability = AdsAvailability(consent)..markSdkInitialized();

      expect(await availability.canRequestAds(), isTrue);

      // Le SDK UMP peut retirer l'autorisation entre deux appels (ex.
      // révocation) — la source unique de vérité doit refléter ce
      // changement immédiatement, sans mise en cache locale erronée.
      consent.canRequestAdsValue = false;

      expect(await availability.canRequestAds(), isFalse);
    });
  });
}
