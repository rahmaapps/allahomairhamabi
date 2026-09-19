// Tests LOT 5.F — correction A2 : initialisation du SDK Ads dès que le
// consentement l'autorise, y compris en cours de session.
//
// Avant ce lot, le SDK n'était initialisé qu'au lancement et seulement si
// `canRequestAds()` était déjà vrai : un consentement accordé plus tard
// (notamment via « خيارات الخصوصية ») restait sans effet jusqu'au
// redémarrage.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:test_1/monetization/ads_activation.dart';
import 'package:test_1/monetization/ads_availability.dart';
import 'package:test_1/monetization/ads_sdk_initializer.dart';

import 'fakes/fake_consent_service.dart';

void main() {
  group('AdsActivation — consentement', () {
    test('canRequestAds == false : le SDK n\'est PAS initialisé', () async {
      final consent = FakeConsentService()..canRequestAdsValue = false;
      final availability = AdsAvailability(consent);
      var initCount = 0;

      final activation = AdsActivation(
        consentService: consent,
        adsAvailability: availability,
        initializeSdk: () async => initCount++,
      );

      expect(await activation.ensureInitializedIfAllowed(), isFalse);
      expect(initCount, 0);
      expect(availability.isSdkInitialized, isFalse);
      // Garantie inchangée depuis le LOT 5.A : aucune requête possible.
      expect(await availability.canRequestAds(), isFalse);
    });

    test('canRequestAds == true au lancement : le SDK est initialisé',
        () async {
      final consent = FakeConsentService()..canRequestAdsValue = true;
      final availability = AdsAvailability(consent);
      var initCount = 0;

      final activation = AdsActivation(
        consentService: consent,
        adsAvailability: availability,
        initializeSdk: () async => initCount++,
      );

      expect(await activation.ensureInitializedIfAllowed(), isTrue);
      expect(initCount, 1);
      expect(availability.isSdkInitialized, isTrue);
      expect(await availability.canRequestAds(), isTrue);
    });

    test(
        'A2 — consentement accordé APRÈS le lancement : le SDK devient '
        'initialisable dans la même session, sans redémarrage', () async {
      final consent = FakeConsentService()..canRequestAdsValue = false;
      final availability = AdsAvailability(consent);
      var initCount = 0;

      final activation = AdsActivation(
        consentService: consent,
        adsAvailability: availability,
        initializeSdk: () async => initCount++,
      );

      // Lancement : rien.
      expect(await activation.ensureInitializedIfAllowed(), isFalse);
      expect(availability.isSdkInitialized, isFalse);

      // L'utilisateur ouvre « خيارات الخصوصية » et accorde son consentement.
      consent.canRequestAdsValue = true;

      expect(await activation.ensureInitializedIfAllowed(), isTrue);
      expect(initCount, 1);
      expect(availability.isSdkInitialized, isTrue);
    });

    test('un refus ultérieur ne réinitialise ni ne casse rien', () async {
      final consent = FakeConsentService()..canRequestAdsValue = true;
      final availability = AdsAvailability(consent);
      var initCount = 0;

      final activation = AdsActivation(
        consentService: consent,
        adsAvailability: availability,
        initializeSdk: () async => initCount++,
      );

      await activation.ensureInitializedIfAllowed();
      consent.canRequestAdsValue = false;

      // Le SDK reste initialisé, mais la porte `canRequestAds` se referme :
      // plus aucune requête publicitaire n'est possible.
      expect(await activation.ensureInitializedIfAllowed(), isTrue);
      expect(initCount, 1);
      expect(await availability.canRequestAds(), isFalse);
    });
  });

  group('AdsActivation — idempotence et concurrence', () {
    test('plusieurs appels successifs : une seule initialisation', () async {
      final consent = FakeConsentService()..canRequestAdsValue = true;
      final availability = AdsAvailability(consent);
      var initCount = 0;

      final activation = AdsActivation(
        consentService: consent,
        adsAvailability: availability,
        initializeSdk: () async => initCount++,
      );

      await activation.ensureInitializedIfAllowed();
      await activation.ensureInitializedIfAllowed();
      await activation.ensureInitializedIfAllowed();

      expect(initCount, 1);
    });

    test('appels concurrents : aucune double initialisation', () async {
      final consent = FakeConsentService()..canRequestAdsValue = true;
      final availability = AdsAvailability(consent);
      var initCount = 0;
      final gate = Completer<void>();

      final activation = AdsActivation(
        consentService: consent,
        adsAvailability: availability,
        initializeSdk: () async {
          initCount++;
          await gate.future;
        },
      );

      final calls = [
        activation.ensureInitializedIfAllowed(),
        activation.ensureInitializedIfAllowed(),
        activation.ensureInitializedIfAllowed(),
      ];
      gate.complete();
      final results = await Future.wait(calls);

      expect(initCount, 1);
      expect(results, everyElement(isTrue));
    });

    test('exception du SDK : aucune exception propagée, app non bloquée',
        () async {
      final consent = FakeConsentService()..canRequestAdsValue = true;
      final availability = AdsAvailability(consent);

      final activation = AdsActivation(
        consentService: consent,
        adsAvailability: availability,
        initializeSdk: () async => throw Exception('SDK indisponible'),
      );

      expect(await activation.ensureInitializedIfAllowed(), isFalse);
      expect(availability.isSdkInitialized, isFalse);

      // Une tentative ultérieure reste possible : aucun état d'échec figé.
      expect(await activation.ensureInitializedIfAllowed(), isFalse);
    });

    test('exception du service de consentement : absorbée', () async {
      final consent = _ThrowingConsentService();
      final availability = AdsAvailability(consent);
      var initCount = 0;

      final activation = AdsActivation(
        consentService: consent,
        adsAvailability: availability,
        initializeSdk: () async => initCount++,
      );

      expect(await activation.ensureInitializedIfAllowed(), isFalse);
      expect(initCount, 0);
    });
  });

  group('AdsSdkInitializer — idempotence de bas niveau', () {
    setUp(AdsSdkInitializer.resetForTesting);
    tearDown(AdsSdkInitializer.resetForTesting);

    test('une seule initialisation, même en appels concurrents', () async {
      var initCount = 0;
      final gate = Completer<void>();
      AdsSdkInitializer.initializer = () async {
        initCount++;
        await gate.future;
      };

      final calls = [
        AdsSdkInitializer.initializeIfNeeded(),
        AdsSdkInitializer.initializeIfNeeded(),
      ];
      gate.complete();
      await Future.wait(calls);

      await AdsSdkInitializer.initializeIfNeeded();

      expect(initCount, 1);
      expect(AdsSdkInitializer.isInitialized, isTrue);
    });

    test('un échec n\'interdit pas une tentative ultérieure', () async {
      var attempts = 0;
      AdsSdkInitializer.initializer = () async {
        attempts++;
        if (attempts == 1) throw Exception('échec transitoire');
      };

      await expectLater(
        AdsSdkInitializer.initializeIfNeeded(),
        throwsA(isA<Exception>()),
      );
      expect(AdsSdkInitializer.isInitialized, isFalse);

      await AdsSdkInitializer.initializeIfNeeded();

      expect(attempts, 2);
      expect(AdsSdkInitializer.isInitialized, isTrue);
    });
  });
}

class _ThrowingConsentService extends FakeConsentService {
  @override
  Future<bool> canRequestAds() async => throw Exception('canal indisponible');
}
